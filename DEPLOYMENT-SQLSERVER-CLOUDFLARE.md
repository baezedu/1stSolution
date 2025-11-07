# Guía de Deployment: Aplicación Blazor con SQL Server Local y Túnel Cloudflare

## Índice
1. [Arquitectura General](#arquitectura-general)
2. [Componentes del Sistema](#componentes-del-sistema)
3. [Configuración de SQL Server Local](#configuración-de-sql-server-local)
4. [Configuración del Túnel Cloudflare](#configuración-del-túnel-cloudflare)
5. [Configuración de la Aplicación](#configuración-de-la-aplicación)
6. [Proceso de Deployment](#proceso-de-deployment)
7. [Consideraciones de Seguridad](#consideraciones-de-seguridad)
8. [Troubleshooting](#troubleshooting)

## Arquitectura General

Esta aplicación Blazor Server utiliza una arquitectura de tres capas que permite el acceso desde dispositivos móviles a un SQL Server local mediante un túnel Cloudflare.

```
┌─────────────────┐
│  Dispositivo    │
│  Móvil/Cliente  │
│  (Navegador)    │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│  Aplicación     │
│  Blazor Server  │
│  (IIS/Kestrel)  │
└────────┬────────┘
         │ Conexión DB
         ▼
┌─────────────────┐      ┌──────────────────┐
│  Cloudflare     │◄────►│  SQL Server      │
│  Tunnel         │      │  Local           │
│  (cloudflared)  │      │  (Puerto 1433)   │
└─────────────────┘      └──────────────────┘
         ▲
         │ Túnel Seguro
         │
    [Internet]
```

## Componentes del Sistema

### 1. SQL Server Local
- **Ubicación**: Máquina local con IP privada (ejemplo: `192.168.56.102`)
- **Puerto**: 1433 (por defecto) o personalizado (ejemplo: 1401)
- **Función**: Base de datos principal de la aplicación
- **Acceso**: A través del túnel Cloudflare o conexión directa local

### 2. Cloudflare Tunnel (cloudflared)
- **Función**: Exponer SQL Server local de forma segura sin abrir puertos en el firewall
- **Beneficios**: 
  - No requiere IP pública
  - Conexión cifrada
  - Sin configuración de router/firewall
  - Protección DDoS incluida

### 3. Aplicación Blazor Server
- **Tecnología**: .NET 9 con Blazor Server
- **Función**: Interfaz de usuario y lógica de negocio
- **Acceso**: Navegador web (móvil o desktop)

## Configuración de SQL Server Local

### Paso 1: Habilitar SQL Server para Conexiones Remotas

1. **Abrir SQL Server Configuration Manager**
   ```
   C:\Windows\SysWOW64\SQLServerManager16.msc
   ```

2. **Habilitar TCP/IP**
   - Navegar a: SQL Server Network Configuration → Protocols for [INSTANCE_NAME]
   - Hacer clic derecho en "TCP/IP" → Enable
   - Reiniciar el servicio de SQL Server

3. **Configurar Puerto TCP**
   - Hacer doble clic en "TCP/IP" → Tab "IP Addresses"
   - En "IPAll", establecer:
     - TCP Port: `1433` (o tu puerto personalizado, ej: `1401`)
   - Guardar y reiniciar el servicio

4. **Configurar Firewall de Windows**
   ```powershell
   # Abrir PowerShell como Administrador
   New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
   ```

### Paso 2: Crear Usuario y Base de Datos

```sql
-- Crear la base de datos
CREATE DATABASE dbAlqPNA001Prod;
GO

-- Crear login y usuario
CREATE LOGIN sa_app WITH PASSWORD = 'YOUR_SECURE_PASSWORD_HERE!';
GO

USE dbAlqPNA001Prod;
GO

CREATE USER sa_app FOR LOGIN sa_app;
GO

-- Otorgar permisos
ALTER ROLE db_owner ADD MEMBER sa_app;
GO
```

### Paso 3: Verificar Conexión Local

Prueba la conexión desde tu máquina local:

```bash
# Usando sqlcmd (reemplaza YOUR_PASSWORD con tu contraseña real)
sqlcmd -S 192.168.56.102,1401 -U sa -P YOUR_PASSWORD
```

## Configuración del Túnel Cloudflare

### Opción 1: Cloudflare Tunnel (Recomendado)

#### Instalación de cloudflared

**Windows:**
```powershell
# Descargar cloudflared
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "cloudflared.exe"
```

**Linux:**
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
```

#### Configuración del Túnel

1. **Autenticación con Cloudflare**
   ```bash
   cloudflared tunnel login
   ```

2. **Crear el Túnel**
   ```bash
   cloudflared tunnel create sqlserver-tunnel
   ```

3. **Configurar el Túnel** - Crear archivo `config.yml`:
   ```yaml
   tunnel: <TUNNEL-ID>
   credentials-file: /path/to/.cloudflared/<TUNNEL-ID>.json

   ingress:
     # Ruta para SQL Server
     - hostname: sqlserver.tudominio.com
       service: tcp://localhost:1433
     
     # Ruta para la aplicación web (opcional)
     - hostname: app.tudominio.com
       service: http://localhost:5000
     
     # Regla catch-all
     - service: http_status:404
   ```

4. **Configurar DNS en Cloudflare**
   ```bash
   cloudflared tunnel route dns sqlserver-tunnel sqlserver.tudominio.com
   cloudflared tunnel route dns sqlserver-tunnel app.tudominio.com
   ```

5. **Iniciar el Túnel**
   ```bash
   cloudflared tunnel run sqlserver-tunnel
   ```

#### Ejecutar como Servicio (Windows)

```powershell
# Instalar como servicio
cloudflared service install

# Iniciar el servicio
cloudflared service start
```

### Opción 2: Cloudflare Access con IP Privada

Si prefieres mantener el acceso más restrictivo:

1. **Configurar Cloudflare Access**
   - Ir al dashboard de Cloudflare
   - Seleccionar "Zero Trust" → "Access" → "Applications"
   - Crear nueva aplicación para proteger tu túnel SQL

2. **Definir Políticas de Acceso**
   ```yaml
   Name: SQL Server Access
   Session Duration: 24 hours
   Include:
     - Email: tu@email.com
   ```

## Configuración de la Aplicación

### appsettings.json

Actualiza tu archivo `appsettings.json` con las diferentes configuraciones:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    // Desarrollo Local - Sin túnel
    "DOGO2Context": "Server=(localdb)\\MSSQLLocalDB;Database=YumBlazor;Trusted_Connection=true",
    
    // Producción - SQL Server Local con Autenticación SQL
    "DOGO2Context_Production_Local": "Server=192.168.56.102,1401;Database=dbAlqPNA001Prod;User ID=sa_app;Password=YOUR_SECURE_PASSWORD_HERE;Trust Server Certificate=True;Encrypt=True",
    
    // Producción - A través de Cloudflare Tunnel
    "DOGO2Context_Production_Tunnel": "Server=sqlserver.tudominio.com,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=YOUR_SECURE_PASSWORD_HERE;Trust Server Certificate=True;Encrypt=True"
  }
}
```

### appsettings.Development.json

Para desarrollo local:

```json
{
  "DetailedErrors": true,
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

### appsettings.Production.json

Crea este archivo para producción:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DOGO2Context": "Server=sqlserver.tudominio.com,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=${SQL_PASSWORD};Trust Server Certificate=True;Encrypt=True"
  }
}
```

### Variables de Entorno

Para mayor seguridad, usa variables de entorno para las credenciales:

**Windows:**
```powershell
# Reemplaza con tu contraseña real
$env:SQL_PASSWORD = "YOUR_SECURE_PASSWORD_HERE"
```

**Linux:**
```bash
# Reemplaza con tu contraseña real
export SQL_PASSWORD="YOUR_SECURE_PASSWORD_HERE"
```

### Program.cs

Asegúrate de que tu `Program.cs` esté configurado correctamente:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Configurar conexión a base de datos
var connectionString = builder.Configuration.GetConnectionString("DOGO2Context") 
    ?? throw new InvalidOperationException("Connection string 'DOGO2Context' not found.");

// Reemplazar variable de entorno si existe
if (connectionString.Contains("${SQL_PASSWORD}"))
{
    var password = Environment.GetEnvironmentVariable("SQL_PASSWORD");
    if (string.IsNullOrEmpty(password))
    {
        throw new InvalidOperationException("SQL_PASSWORD environment variable not set.");
    }
    connectionString = connectionString.Replace("${SQL_PASSWORD}", password);
}

builder.Services.AddDbContextFactory<DOGO2Context>(options =>
    options.UseSqlServer(connectionString));

// ... resto de la configuración
```

## Proceso de Deployment

### Preparación

1. **Verificar Requisitos**
   ```bash
   # Verificar .NET SDK
   dotnet --version
   
   # Debe ser 9.0 o superior
   ```

2. **Compilar la Aplicación**
   ```bash
   cd /home/runner/work/1stSolution/1stSolution/DOGO2
   dotnet build --configuration Release
   ```

3. **Publicar la Aplicación**
   ```bash
   dotnet publish --configuration Release --output ./publish
   ```

### Deployment en IIS (Windows)

1. **Instalar .NET Hosting Bundle**
   - Descargar de: https://dotnet.microsoft.com/download/dotnet/9.0
   - Instalar "ASP.NET Core Runtime Hosting Bundle"

2. **Configurar IIS**
   ```powershell
   # Habilitar IIS
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
   ```

3. **Crear Application Pool**
   - Abrir IIS Manager
   - Application Pools → Add Application Pool
   - Name: DOGO2AppPool
   - .NET CLR Version: No Managed Code
   - Pipeline Mode: Integrated

4. **Crear Sitio Web**
   - Sites → Add Website
   - Site Name: DOGO2
   - Application Pool: DOGO2AppPool
   - Physical Path: C:\inetpub\wwwroot\DOGO2
   - Port: 80 (HTTP) o 443 (HTTPS)

5. **Copiar Archivos Publicados**
   ```powershell
   Copy-Item -Path ./publish/* -Destination C:\inetpub\wwwroot\DOGO2 -Recurse
   ```

### Deployment en Linux (con Nginx)

1. **Publicar y Transferir Archivos**
   ```bash
   # Publicar
   dotnet publish -c Release -o ./publish
   
   # Transferir a servidor
   scp -r ./publish/* usuario@servidor:/var/www/dogo2
   ```

2. **Crear Servicio Systemd**
   ```bash
   sudo nano /etc/systemd/system/dogo2.service
   ```

   Contenido:
   ```ini
   [Unit]
   Description=DOGO2 Blazor Application
   After=network.target

   [Service]
   WorkingDirectory=/var/www/dogo2
   ExecStart=/usr/bin/dotnet /var/www/dogo2/DOGO2.dll
   Restart=always
   RestartSec=10
   KillSignal=SIGINT
   SyslogIdentifier=dogo2
   User=www-data
   Environment=ASPNETCORE_ENVIRONMENT=Production
   Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
   Environment=SQL_PASSWORD=TuPasswordSegura123!

   [Install]
   WantedBy=multi-user.target
   ```

3. **Configurar Nginx**
   ```bash
   sudo nano /etc/nginx/sites-available/dogo2
   ```

   Contenido:
   ```nginx
   server {
       listen 80;
       server_name app.tudominio.com;
       
       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection keep-alive;
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

4. **Habilitar y Arrancar Servicios**
   ```bash
   # Habilitar sitio Nginx
   sudo ln -s /etc/nginx/sites-available/dogo2 /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   
   # Iniciar aplicación
   sudo systemctl enable dogo2
   sudo systemctl start dogo2
   sudo systemctl status dogo2
   ```

### Deployment en Azure (Opcional)

Si prefieres un deployment en la nube:

```bash
# Login a Azure
az login

# Crear Resource Group
az group create --name DOGO2ResourceGroup --location eastus

# Crear App Service Plan
az appservice plan create --name DOGO2Plan --resource-group DOGO2ResourceGroup --sku B1 --is-linux

# Crear Web App
az webapp create --resource-group DOGO2ResourceGroup --plan DOGO2Plan --name dogo2-app --runtime "DOTNET|9.0"

# Configurar connection string
az webapp config connection-string set --resource-group DOGO2ResourceGroup --name dogo2-app --settings DOGO2Context="Server=sqlserver.tudominio.com,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=TuPasswordSegura123!;Trust Server Certificate=True" --connection-string-type SQLAzure

# Deploy
az webapp deployment source config-zip --resource-group DOGO2ResourceGroup --name dogo2-app --src ./publish.zip
```

## Consideraciones de Seguridad

### 1. Protección de Credenciales

**NO hacer:**
- ❌ Guardar contraseñas en texto plano en `appsettings.json`
- ❌ Commitear archivos con credenciales al repositorio
- ❌ Usar contraseñas débiles

**SÍ hacer:**
- ✅ Usar User Secrets en desarrollo
- ✅ Usar variables de entorno en producción
- ✅ Usar Azure Key Vault o similar para producción
- ✅ Usar contraseñas fuertes (mínimo 12 caracteres, mayúsculas, minúsculas, números, símbolos)

#### Configurar User Secrets (Desarrollo)

```bash
# Inicializar User Secrets
cd DOGO2
dotnet user-secrets init

# Agregar connection string
dotnet user-secrets set "ConnectionStrings:DOGO2Context" "Server=192.168.56.102,1401;Database=dbAlqPNA001Prod;User ID=sa_app;Password=TuPasswordSegura123!;Trust Server Certificate=True"
```

### 2. Cifrado de Conexión

Siempre usa `Encrypt=True` y `Trust Server Certificate=True` (o configura certificados válidos):

```
Server=sqlserver.tudominio.com,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=***;Trust Server Certificate=True;Encrypt=True
```

### 3. Cloudflare Access

Configura políticas de acceso para restringir quién puede conectarse:

```yaml
# Ejemplo de política
Name: SQL Server Access Policy
Include:
  - Email domain is: tuempresa.com
Exclude:
  - IP ranges: <rangos IP públicos no confiables>
```

### 4. SQL Server Security

```sql
-- Deshabilitar sa si no se usa
ALTER LOGIN sa DISABLE;
GO

-- Crear roles específicos en lugar de db_owner
CREATE ROLE app_reader;
CREATE ROLE app_writer;

GRANT SELECT ON SCHEMA::dbo TO app_reader;
GRANT INSERT, UPDATE, DELETE ON SCHEMA::dbo TO app_writer;

ALTER ROLE app_reader ADD MEMBER sa_app;
ALTER ROLE app_writer ADD MEMBER sa_app;
```

### 5. Rate Limiting

Configura rate limiting en Cloudflare para prevenir ataques:

```yaml
# En Cloudflare Dashboard → Security → WAF
Rule: Rate Limiting
Expression: (http.request.uri.path eq "/")
Requests: 100 requests per 10 seconds
Action: Block
```

### 6. Firewall de Aplicación Web (WAF)

Activa el WAF de Cloudflare para protección adicional:
- XSS Protection
- SQL Injection Protection
- Bot Protection

## Troubleshooting

### Problema 1: No se puede conectar a SQL Server

**Síntomas:**
```
A network-related or instance-specific error occurred while establishing a connection to SQL Server
```

**Soluciones:**

1. Verificar que SQL Server está corriendo:
   ```powershell
   Get-Service MSSQL*
   ```

2. Verificar firewall:
   ```powershell
   Test-NetConnection -ComputerName 192.168.56.102 -Port 1401
   ```

3. Verificar TCP/IP está habilitado:
   - SQL Server Configuration Manager → SQL Server Network Configuration → Protocols

4. Revisar logs de SQL Server:
   ```
   C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\ERRORLOG
   ```

### Problema 2: Cloudflare Tunnel no funciona

**Síntomas:**
```
ERR Connection terminated
```

**Soluciones:**

1. Verificar que cloudflared está corriendo:
   ```bash
   # Windows
   Get-Service cloudflared
   
   # Linux
   systemctl status cloudflared
   ```

2. Verificar configuración del túnel:
   ```bash
   cloudflared tunnel info sqlserver-tunnel
   ```

3. Revisar logs:
   ```bash
   # Windows
   Get-EventLog -LogName Application -Source cloudflared -Newest 50
   
   # Linux
   journalctl -u cloudflared -n 50
   ```

4. Probar túnel manualmente:
   ```bash
   cloudflared tunnel run --url tcp://localhost:1433
   ```

### Problema 3: Error de autenticación

**Síntomas:**
```
Login failed for user 'sa_app'
```

**Soluciones:**

1. Verificar que el usuario existe:
   ```sql
   SELECT name, type_desc, is_disabled 
   FROM sys.server_principals 
   WHERE name = 'sa_app';
   ```

2. Verificar modo de autenticación:
   ```sql
   SELECT SERVERPROPERTY('IsIntegratedSecurityOnly');
   -- Debe retornar 0 para permitir SQL Authentication
   ```

3. Habilitar SQL Server Authentication:
   - SSMS → Server Properties → Security → SQL Server and Windows Authentication mode

### Problema 4: Aplicación Blazor no inicia

**Síntomas:**
```
HTTP Error 500.30 - ASP.NET Core app failed to start
```

**Soluciones:**

1. Verificar .NET Runtime instalado:
   ```bash
   dotnet --list-runtimes
   ```

2. Revisar logs de la aplicación:
   - Windows Event Viewer → Application Logs
   - Linux: `journalctl -u dogo2 -n 100`

3. Ejecutar manualmente para ver error:
   ```bash
   cd /path/to/app
   dotnet DOGO2.dll
   ```

4. Verificar connection string:
   ```bash
   # Ver configuración actual
   dotnet run --environment Production
   ```

### Problema 5: CORS o problemas de SignalR

**Síntomas:**
```
WebSocket connection failed
```

**Soluciones:**

1. Configurar CORS en `Program.cs`:
   ```csharp
   builder.Services.AddCors(options =>
   {
       options.AddDefaultPolicy(policy =>
       {
           policy.WithOrigins("https://app.tudominio.com")
                 .AllowAnyHeader()
                 .AllowAnyMethod()
                 .AllowCredentials();
       });
   });
   ```

2. Verificar configuración de Cloudflare:
   - Cloudflare → Network → WebSockets: ON

3. Verificar configuración de Nginx (si aplica):
   ```nginx
   proxy_set_header Upgrade $http_upgrade;
   proxy_set_header Connection "upgrade";
   ```

## Recursos Adicionales

### Enlaces Útiles

- [Documentación Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Documentación Blazor](https://docs.microsoft.com/aspnet/core/blazor/)
- [SQL Server Security Best Practices](https://docs.microsoft.com/sql/relational-databases/security/security-best-practices)
- [ASP.NET Core Deployment](https://docs.microsoft.com/aspnet/core/host-and-deploy/)

### Comandos Útiles

```bash
# Verificar estado del túnel
cloudflared tunnel list

# Ver métricas del túnel
cloudflared tunnel info <TUNNEL-ID>

# Reiniciar servicio cloudflared
# Windows
Restart-Service cloudflared

# Linux
sudo systemctl restart cloudflared

# Verificar conexión a base de datos
sqlcmd -S sqlserver.tudominio.com,1433 -U sa_app -P TuPassword

# Ver logs de la aplicación en tiempo real
# Linux
journalctl -u dogo2 -f

# Ver uso de memoria de la aplicación
# Linux
ps aux | grep DOGO2
```

### Scripts de Mantenimiento

#### Backup de Base de Datos
```sql
-- Backup completo
BACKUP DATABASE dbAlqPNA001Prod
TO DISK = 'C:\Backups\dbAlqPNA001Prod_Full.bak'
WITH FORMAT, MEDIANAME = 'SQLServerBackups', NAME = 'Full Backup';

-- Backup diferencial
BACKUP DATABASE dbAlqPNA001Prod
TO DISK = 'C:\Backups\dbAlqPNA001Prod_Diff.bak'
WITH DIFFERENTIAL, FORMAT, MEDIANAME = 'SQLServerBackups', NAME = 'Differential Backup';
```

#### Monitoreo de Conexiones
```sql
-- Ver conexiones activas
SELECT 
    session_id,
    login_name,
    host_name,
    program_name,
    status,
    last_request_start_time
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;
```

## Conclusión

Esta guía proporciona una arquitectura completa para desplegar una aplicación Blazor Server que se conecta a un SQL Server local a través de un túnel Cloudflare. Esta configuración permite:

- ✅ Acceso seguro desde cualquier ubicación
- ✅ Sin necesidad de IP pública estática
- ✅ Protección DDoS integrada
- ✅ Cifrado end-to-end
- ✅ Fácil escalabilidad

Recuerda siempre seguir las mejores prácticas de seguridad y mantener todos los componentes actualizados.
