# DOGO2 - Aplicación Blazor Server con SQL Server

Una aplicación web moderna desarrollada con .NET 9 y Blazor Server que se conecta a SQL Server.

## 📋 Requisitos

- .NET 9.0 SDK
- SQL Server (Local o Remoto)
- IIS (Windows) o Nginx (Linux) para producción
- Cloudflare Tunnel (opcional, para acceso remoto seguro)

## 🚀 Inicio Rápido

### Desarrollo Local

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/baezedu/1stSolution.git
   cd 1stSolution
   ```

2. **Configurar la conexión a base de datos**
   
   Editar `DOGO2/appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DOGO2Context": "Server=(localdb)\\MSSQLLocalDB;Database=YumBlazor;Trusted_Connection=true"
     }
   }
   ```

3. **Ejecutar migraciones**
   ```bash
   cd DOGO2
   dotnet ef database update
   ```

4. **Ejecutar la aplicación**
   ```bash
   dotnet run
   ```

5. **Abrir en el navegador**
   ```
   https://localhost:5001
   ```

## 📦 Deployment

### Windows con IIS

Ejecutar el script de deployment automatizado:

```powershell
# Como Administrador
.\deploy-windows.ps1
```

**O manualmente:**

1. Publicar la aplicación:
   ```powershell
   dotnet publish -c Release -o ./publish
   ```

2. Configurar IIS según la documentación en [DEPLOYMENT-SQLSERVER-CLOUDFLARE.md](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md)

### Linux con Nginx

Ejecutar el script de deployment automatizado:

```bash
# Como root
sudo ./deploy-linux.sh
```

**O manualmente:**

1. Publicar la aplicación:
   ```bash
   dotnet publish -c Release -o ./publish
   ```

2. Configurar systemd y Nginx según la documentación en [DEPLOYMENT-SQLSERVER-CLOUDFLARE.md](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md)

## 🌐 Deployment con Cloudflare Tunnel

Para acceder a tu SQL Server local desde internet de forma segura, consulta la guía completa:

**[📖 Guía Completa de Deployment con Cloudflare Tunnel](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md)**

Esta guía incluye:
- Arquitectura del sistema
- Configuración de SQL Server para acceso remoto
- Setup completo de Cloudflare Tunnel
- Configuración de la aplicación Blazor
- Consideraciones de seguridad
- Troubleshooting

## 📁 Estructura del Proyecto

```
1stSolution/
├── DOGO2/                              # Aplicación principal
│   ├── Components/                     # Componentes Blazor
│   ├── Data/                          # Contexto de Entity Framework
│   ├── Model/                         # Modelos de datos
│   ├── Migrations/                    # Migraciones de base de datos
│   ├── Properties/                    # Configuración del proyecto
│   ├── wwwroot/                       # Archivos estáticos
│   ├── Program.cs                     # Punto de entrada
│   ├── appsettings.json              # Configuración
│   └── appsettings.Development.json  # Configuración de desarrollo
├── DEPLOYMENT-SQLSERVER-CLOUDFLARE.md # Guía de deployment completa
├── deploy-windows.ps1                 # Script de deployment para Windows
├── deploy-linux.sh                    # Script de deployment para Linux
├── cloudflare-tunnel-config.example.yml  # Ejemplo de configuración Cloudflare
├── nginx-config.example.conf          # Ejemplo de configuración Nginx
├── dogo2.service.example             # Ejemplo de servicio systemd
└── README.md                          # Este archivo
```

## 🔧 Configuración

### Variables de Entorno

Para producción, configure las siguientes variables de entorno:

**Windows:**
```powershell
$env:SQL_PASSWORD = "TuPasswordSegura123!"
$env:ASPNETCORE_ENVIRONMENT = "Production"
```

**Linux:**
```bash
export SQL_PASSWORD="TuPasswordSegura123!"
export ASPNETCORE_ENVIRONMENT="Production"
```

### Connection Strings

#### Desarrollo (LocalDB)
```json
"Server=(localdb)\\MSSQLLocalDB;Database=YumBlazor;Trusted_Connection=true"
```

#### Producción (SQL Server Local)
```json
"Server=192.168.56.102,1401;Database=dbAlqPNA001Prod;User ID=sa_app;Password=${SQL_PASSWORD};Trust Server Certificate=True;Encrypt=True"
```

#### Producción (Con Cloudflare Tunnel)
```json
"Server=sqlserver.tudominio.com,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=${SQL_PASSWORD};Trust Server Certificate=True;Encrypt=True"
```

## 🔒 Seguridad

### Mejores Prácticas

1. **Nunca** commitear contraseñas en el código
2. Usar **User Secrets** en desarrollo:
   ```bash
   dotnet user-secrets set "ConnectionStrings:DOGO2Context" "tu-connection-string"
   ```
3. Usar **variables de entorno** en producción
4. Habilitar **HTTPS** en producción
5. Configurar **Cloudflare WAF** para protección adicional
6. Usar **contraseñas fuertes** (mínimo 12 caracteres)
7. Mantener **.NET y dependencias actualizadas**

### Archivos a No Commitear

Asegúrate de que `.gitignore` incluya:

```gitignore
# User secrets
**/appsettings.Production.json
**/appsettings.*.json
!**/appsettings.Development.json

# Cloudflare credentials
**/.cloudflared/*.json
**/cloudflare-tunnel-config.yml

# Environment files
.env
*.env
/etc/dogo2/env
```

## 🧪 Testing

```bash
# Ejecutar tests unitarios
dotnet test

# Ejecutar con hot reload
dotnet watch run

# Verificar conexión a base de datos
dotnet ef dbcontext info
```

## 📊 Monitoreo

### Logs en Windows
```powershell
# IIS logs
Get-EventLog -LogName Application -Source "IIS AspNetCore Module V2" -Newest 20

# Application logs
Get-Content C:\inetpub\wwwroot\DOGO2\logs\*.log -Tail 50
```

### Logs en Linux
```bash
# Application logs
journalctl -u dogo2 -f

# Nginx logs
tail -f /var/log/nginx/dogo2_access.log
tail -f /var/log/nginx/dogo2_error.log
```

### Cloudflare Tunnel Logs
```bash
# Windows
Get-EventLog -LogName Application -Source cloudflared -Newest 50

# Linux
journalctl -u cloudflared -f
```

## 🛠 Troubleshooting

### Problema: No se puede conectar a SQL Server

```bash
# Verificar conectividad
Test-NetConnection -ComputerName 192.168.56.102 -Port 1401

# Verificar servicio SQL Server
Get-Service MSSQL*
```

### Problema: Aplicación no inicia

```bash
# Ver logs detallados
dotnet run --environment Development

# Verificar .NET Runtime
dotnet --list-runtimes
```

### Problema: Cloudflare Tunnel no funciona

```bash
# Verificar túnel
cloudflared tunnel info sqlserver-tunnel

# Ver logs
cloudflared tunnel run sqlserver-tunnel --loglevel debug
```

Para más información sobre troubleshooting, consulta [DEPLOYMENT-SQLSERVER-CLOUDFLARE.md](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md#troubleshooting)

## 📚 Documentación Adicional

- [Guía Completa de Deployment](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md) - Guía exhaustiva de deployment con Cloudflare Tunnel
- [Blazor Documentation](https://docs.microsoft.com/aspnet/core/blazor/)
- [Entity Framework Core](https://docs.microsoft.com/ef/core/)
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [SQL Server on Linux](https://docs.microsoft.com/sql/linux/)

## 🤝 Contribuir

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📝 Licencia

Este proyecto está bajo la licencia [especificar licencia].

## 👥 Autores

- Eduardo Baez - [baezedu](https://github.com/baezedu)

## 🙏 Agradecimientos

- Syncfusion por los componentes Blazor
- Cloudflare por el servicio de túnel
- Microsoft por .NET y Blazor

---

Para preguntas o soporte, por favor abre un [issue](https://github.com/baezedu/1stSolution/issues) en GitHub.
