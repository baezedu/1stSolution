# DOGO2 - Blazor Application

A Blazor Server application built with .NET 9.0 and Syncfusion components.

## Project Overview

DOGO2 is an ASP.NET Core Blazor Server application that provides airplane management functionality with a SQL Server database backend.

## Features

- Blazor Server interactive components
- Entity Framework Core with SQL Server
- Syncfusion Blazor components
- QuickGrid for data display
- Responsive UI with Bootstrap

## Getting Started

### Prerequisites

- .NET 9.0 SDK or later
- SQL Server or SQL Server LocalDB
- Visual Studio 2022 or Visual Studio Code

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/baezedu/1stSolution.git
   cd 1stSolution
   ```

2. Update the connection string in `appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DOGO2Context": "Server=(localdb)\\MSSQLLocalDB;Database=YumBlazor;Trusted_Connection=true"
   }
   ```

3. Restore dependencies:
   ```bash
   dotnet restore
   ```

4. Apply database migrations:
   ```bash
   cd DOGO2
   dotnet ef database update
   ```

5. Run the application:
   ```bash
   dotnet run
   ```

6. Open your browser and navigate to `https://localhost:5001`

## Domain Setup for Site123

If you're deploying this application with a custom domain on Site123, you'll need to configure DNS TXT records for domain verification.

### Quick Reference

See the following documentation files for detailed instructions:

- **[Complete Setup Guide](SITE123_DOMAIN_SETUP.md)** - Comprehensive instructions for configuring Site123 TXT records
- **[Quick Reference](DOGO2/SITE123_TXT_RECORD_GUIDE.md)** - Fast guide for TXT record setup

### Summary

To connect your custom domain to Site123:

1. Get your unique verification code from Site123 Settings > Domain
2. Add a TXT record to your domain's DNS settings with the verification code
3. Wait for DNS propagation (5-60 minutes)
4. Verify the domain in Site123

## Project Structure

```
DOGO2/
├── Components/
│   ├── Layout/          # Layout components
│   └── Pages/           # Page components
│       └── Aviones1Pages/  # Airplane management pages
├── Data/                # Database context
├── Migrations/          # EF Core migrations
├── Model/               # Data models
├── wwwroot/             # Static files
├── Program.cs           # Application entry point
└── appsettings.json     # Configuration
```

## Technologies Used

- **Framework**: ASP.NET Core 9.0 Blazor Server
- **Database**: SQL Server with Entity Framework Core
- **UI Components**: Syncfusion Blazor
- **CSS Framework**: Bootstrap 5
- **Language**: C# 12

## Database Configuration

The application uses Entity Framework Core with SQL Server. The connection string can be configured in `appsettings.json`:

### Development (LocalDB)
```json
"DOGO2Context": "Server=(localdb)\\MSSQLLocalDB;Database=YumBlazor;Trusted_Connection=true"
```

### Production (SQL Server)
```json
"DOGO2Context": "Server=YOUR_SERVER;Database=YOUR_DB;User ID=YOUR_USER;Password=YOUR_PASSWORD;Trust Server Certificate=True"
```

## License

Syncfusion License: This project uses Syncfusion Blazor components. Ensure you have a valid Syncfusion license for production use.

## Support

For issues related to:
- **Application bugs**: Open an issue on GitHub
- **Site123 domain setup**: See [SITE123_DOMAIN_SETUP.md](SITE123_DOMAIN_SETUP.md)
- **Syncfusion components**: Visit [Syncfusion Support](https://www.syncfusion.com/support)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

- baezedu

---

**Need help with Site123 domain verification?** Check out the [Site123 TXT Record Setup Guide](SITE123_DOMAIN_SETUP.md) for step-by-step instructions.
