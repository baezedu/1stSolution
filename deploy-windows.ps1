# DOGO2 Blazor Application - Windows Deployment Script
# Run this script with Administrator privileges
# Usage: .\deploy-windows.ps1

# Configuration
$AppName = "DOGO2"
$AppPath = "C:\inetpub\wwwroot\DOGO2"
$AppPoolName = "${AppName}AppPool"
$SiteName = $AppName
$SitePort = 80
$SiteHttpsPort = 443
$PublishPath = ".\DOGO2\bin\Release\net9.0\publish"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DOGO2 Deployment Script for Windows/IIS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Install .NET Hosting Bundle if not installed
Write-Host "[1/8] Checking .NET Hosting Bundle..." -ForegroundColor Green
try {
    $dotnetVersion = dotnet --version
    Write-Host "  .NET SDK version: $dotnetVersion" -ForegroundColor Gray
} catch {
    Write-Host "  WARNING: .NET SDK not found!" -ForegroundColor Yellow
    Write-Host "  Please download and install from: https://dotnet.microsoft.com/download/dotnet/9.0" -ForegroundColor Yellow
    $continue = Read-Host "  Continue anyway? (y/n)"
    if ($continue -ne "y") { exit 1 }
}

# Step 2: Enable IIS Features
Write-Host "[2/8] Enabling IIS Features..." -ForegroundColor Green
try {
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -NoRestart -ErrorAction SilentlyContinue
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -NoRestart -ErrorAction SilentlyContinue
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -NoRestart -ErrorAction SilentlyContinue
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -NoRestart -ErrorAction SilentlyContinue
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -NoRestart -ErrorAction SilentlyContinue
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets -NoRestart -ErrorAction SilentlyContinue
    Write-Host "  IIS features enabled successfully" -ForegroundColor Gray
} catch {
    Write-Host "  WARNING: Some IIS features may already be enabled" -ForegroundColor Yellow
}

# Import IIS module
Import-Module WebAdministration -ErrorAction SilentlyContinue

# Step 3: Publish Application
Write-Host "[3/8] Publishing application..." -ForegroundColor Green
if (Test-Path $PublishPath) {
    Remove-Item -Path $PublishPath -Recurse -Force
}
dotnet publish .\DOGO2\DOGO2.csproj -c Release -o $PublishPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to publish application" -ForegroundColor Red
    exit 1
}
Write-Host "  Application published successfully" -ForegroundColor Gray

# Step 4: Create/Update Application Directory
Write-Host "[4/8] Setting up application directory..." -ForegroundColor Green
if (-not (Test-Path $AppPath)) {
    New-Item -Path $AppPath -ItemType Directory -Force | Out-Null
    Write-Host "  Created directory: $AppPath" -ForegroundColor Gray
}

# Stop IIS site if it exists
if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
    Stop-Website -Name $SiteName
    Write-Host "  Stopped existing website" -ForegroundColor Gray
}

# Copy published files
Write-Host "  Copying files to $AppPath..." -ForegroundColor Gray
Copy-Item -Path "$PublishPath\*" -Destination $AppPath -Recurse -Force
Write-Host "  Files copied successfully" -ForegroundColor Gray

# Step 5: Create Application Pool
Write-Host "[5/8] Configuring Application Pool..." -ForegroundColor Green
if (Test-Path "IIS:\AppPools\$AppPoolName") {
    Remove-WebAppPool -Name $AppPoolName
    Write-Host "  Removed existing Application Pool" -ForegroundColor Gray
}

$appPool = New-WebAppPool -Name $AppPoolName
$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value ""
$appPool | Set-ItemProperty -Name "managedPipelineMode" -Value "Integrated"
$appPool | Set-ItemProperty -Name "startMode" -Value "AlwaysRunning"
$appPool | Set-ItemProperty -Name "processModel.idleTimeout" -Value ([TimeSpan]::FromMinutes(0))
$appPool | Set-ItemProperty -Name "recycling.periodicRestart.time" -Value ([TimeSpan]::FromMinutes(0))
Write-Host "  Application Pool '$AppPoolName' created" -ForegroundColor Gray

# Step 6: Create/Update Website
Write-Host "[6/8] Configuring Website..." -ForegroundColor Green
if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
    Remove-Website -Name $SiteName
    Write-Host "  Removed existing website" -ForegroundColor Gray
}

New-Website -Name $SiteName `
    -PhysicalPath $AppPath `
    -ApplicationPool $AppPoolName `
    -Port $SitePort `
    -Force

Write-Host "  Website '$SiteName' created on port $SitePort" -ForegroundColor Gray

# Configure website for Blazor
$webConfig = Join-Path $AppPath "web.config"
if (-not (Test-Path $webConfig)) {
    # Create basic web.config if it doesn't exist
    @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" arguments=".\DOGO2.dll" stdoutLogEnabled="false" stdoutLogFile=".\logs\stdout" hostingModel="inprocess" />
    </system.webServer>
  </location>
</configuration>
"@ | Set-Content -Path $webConfig
    Write-Host "  Created web.config" -ForegroundColor Gray
}

# Step 7: Configure Firewall
Write-Host "[7/8] Configuring Windows Firewall..." -ForegroundColor Green
try {
    $firewallRule = Get-NetFirewallRule -DisplayName "IIS HTTP" -ErrorAction SilentlyContinue
    if (-not $firewallRule) {
        New-NetFirewallRule -DisplayName "IIS HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow | Out-Null
        Write-Host "  Created firewall rule for HTTP (port 80)" -ForegroundColor Gray
    } else {
        Write-Host "  Firewall rule for HTTP already exists" -ForegroundColor Gray
    }
    
    $firewallRuleHttps = Get-NetFirewallRule -DisplayName "IIS HTTPS" -ErrorAction SilentlyContinue
    if (-not $firewallRuleHttps) {
        New-NetFirewallRule -DisplayName "IIS HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow | Out-Null
        Write-Host "  Created firewall rule for HTTPS (port 443)" -ForegroundColor Gray
    } else {
        Write-Host "  Firewall rule for HTTPS already exists" -ForegroundColor Gray
    }
} catch {
    Write-Host "  WARNING: Could not configure firewall rules" -ForegroundColor Yellow
}

# Step 8: Set Environment Variables
Write-Host "[8/8] Setting Environment Variables..." -ForegroundColor Green
Write-Host "  Environment variables should be set via:" -ForegroundColor Yellow
Write-Host "  - IIS Manager > Application Pool > $AppPoolName > Advanced Settings > Environment Variables" -ForegroundColor Yellow
Write-Host "  - Or use: Set-WebConfigurationProperty for specific settings" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Required environment variable:" -ForegroundColor Yellow
Write-Host "    SQL_PASSWORD=YourSecurePassword" -ForegroundColor Yellow

# Start the website
Start-Website -Name $SiteName
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Set SQL_PASSWORD environment variable in IIS" -ForegroundColor White
Write-Host "2. Update appsettings.Production.json with your connection string" -ForegroundColor White
Write-Host "3. Configure SSL certificate for HTTPS (recommended)" -ForegroundColor White
Write-Host "4. Test the application at: http://localhost:$SitePort" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  View logs: Get-EventLog -LogName Application -Source 'IIS AspNetCore Module V2' -Newest 20" -ForegroundColor Gray
Write-Host "  Restart site: Restart-WebAppPool -Name '$AppPoolName'" -ForegroundColor Gray
Write-Host "  Stop site: Stop-Website -Name '$SiteName'" -ForegroundColor Gray
Write-Host ""

# Open browser
$openBrowser = Read-Host "Open browser to test? (y/n)"
if ($openBrowser -eq "y") {
    Start-Process "http://localhost:$SitePort"
}
