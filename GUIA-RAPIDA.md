# Guía Rápida de Inicio - DOGO2

Esta guía te ayudará a configurar y desplegar tu aplicación DOGO2 Blazor con SQL Server local usando Cloudflare Tunnel en menos de 30 minutos.

## 🎯 Escenario

Quieres que tu aplicación web Blazor:
- Se ejecute en un servidor (local o remoto)
- Se conecte a tu SQL Server local (en tu red privada)
- Sea accesible desde internet de forma segura
- No requiera abrir puertos en tu firewall

## ✅ Pre-requisitos

Antes de comenzar, asegúrate de tener:

- [ ] Windows o Linux con permisos de administrador
- [ ] SQL Server instalado y corriendo
- [ ] .NET 9.0 SDK instalado
- [ ] Cuenta de Cloudflare (gratis)
- [ ] Un dominio configurado en Cloudflare

## 🚀 Paso a Paso

### Parte 1: Configurar SQL Server (10 minutos)

#### 1.1 Habilitar TCP/IP en SQL Server

**Windows:**
1. Abrir SQL Server Configuration Manager
2. Ir a: SQL Server Network Configuration → Protocols for MSSQLSERVER
3. Hacer clic derecho en "TCP/IP" → Enable
4. Doble clic en "TCP/IP" → pestaña "IP Addresses"
5. En "IPAll", establecer TCP Port: `1433`
6. Reiniciar el servicio SQL Server

#### 1.2 Crear Base de Datos y Usuario

```sql
-- Ejecutar en SQL Server Management Studio
CREATE DATABASE dbAlqPNA001Prod;
GO

CREATE LOGIN sa_app WITH PASSWORD = 'MiPassword123!Segura';
GO

USE dbAlqPNA001Prod;
GO

CREATE USER sa_app FOR LOGIN sa_app;
GO

ALTER ROLE db_owner ADD MEMBER sa_app;
GO
```

#### 1.3 Verificar Conexión

```bash
# Desde una ventana de comandos
sqlcmd -S localhost,1433 -U sa_app -P MiPassword123!Segura
```

Si te conectas exitosamente, ¡vas bien! 🎉

### Parte 2: Configurar Cloudflare Tunnel (15 minutos)

#### 2.1 Descargar cloudflared

**Windows:**
```powershell
# PowerShell como Administrador
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "C:\cloudflared.exe"
```

**Linux:**
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
```

#### 2.2 Autenticar con Cloudflare

```bash
cloudflared tunnel login
```

Esto abrirá tu navegador. Selecciona tu dominio y autoriza.

#### 2.3 Crear el Túnel

```bash
cloudflared tunnel create dogo2-tunnel
```

Guarda el **Tunnel ID** que aparece. Lo necesitarás después.

#### 2.4 Configurar el Túnel

Crear archivo de configuración:

**Windows:** `C:\Users\<usuario>\.cloudflared\config.yml`
**Linux:** `~/.cloudflared/config.yml`

```yaml
tunnel: <TU-TUNNEL-ID>
credentials-file: /path/to/.cloudflared/<TU-TUNNEL-ID>.json

ingress:
  # SQL Server
  - hostname: sqlserver.tudominio.com
    service: tcp://localhost:1433
  
  # Aplicación Web
  - hostname: app.tudominio.com
    service: http://localhost:5000
  
  # Catch-all
  - service: http_status:404
```

#### 2.5 Configurar DNS

```bash
cloudflared tunnel route dns dogo2-tunnel sqlserver.tudominio.com
cloudflared tunnel route dns dogo2-tunnel app.tudominio.com
```

#### 2.6 Iniciar el Túnel

```bash
# Prueba manual primero
cloudflared tunnel run dogo2-tunnel

# Si funciona, instalar como servicio
# Windows:
cloudflared service install
cloudflared service start

# Linux:
sudo cloudflared service install
sudo systemctl start cloudflared
```

¡Tu túnel está listo! 🎉

### Parte 3: Configurar la Aplicación (5 minutos)

#### 3.1 Configurar Connection String

Editar `DOGO2/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DOGO2Context": "Server=localhost,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=MiPassword123!Segura;Trust Server Certificate=True;Encrypt=True"
  }
}
```

Para producción, crear `DOGO2/appsettings.Production.json`:

```json
{
  "ConnectionStrings": {
    "DOGO2Context": "Server=sqlserver.tudominio.com,1433;Database=dbAlqPNA001Prod;User ID=sa_app;Password=${SQL_PASSWORD};Trust Server Certificate=True;Encrypt=True"
  }
}
```

#### 3.2 Configurar Variable de Entorno

**Windows:**
```powershell
$env:SQL_PASSWORD = "MiPassword123!Segura"
$env:ASPNETCORE_ENVIRONMENT = "Production"
```

**Linux:**
```bash
export SQL_PASSWORD="MiPassword123!Segura"
export ASPNETCORE_ENVIRONMENT="Production"
```

#### 3.3 Aplicar Migraciones

```bash
cd DOGO2
dotnet ef database update
```

#### 3.4 Probar Localmente

```bash
dotnet run
```

Abrir navegador en `https://localhost:5001`

Si funciona localmente, ¡estás listo para producción! 🎉

### Parte 4: Deployment (Automático)

#### Opción A: Windows con IIS

```powershell
# Como Administrador
.\deploy-windows.ps1
```

#### Opción B: Linux con Nginx

```bash
sudo ./deploy-linux.sh
```

Los scripts harán todo automáticamente:
- Publicar la aplicación
- Configurar IIS/Nginx
- Crear servicios
- Configurar firewall

### Parte 5: Verificación (5 minutos)

#### 5.1 Verificar SQL Server

```bash
# Local
sqlcmd -S localhost,1433 -U sa_app -P MiPassword123!Segura

# A través del túnel
sqlcmd -S sqlserver.tudominio.com,1433 -U sa_app -P MiPassword123!Segura
```

#### 5.2 Verificar Túnel Cloudflare

```bash
cloudflared tunnel info dogo2-tunnel
```

Debe mostrar "connected" o "active".

#### 5.3 Verificar Aplicación

```bash
# Local
curl http://localhost:5000

# A través de Cloudflare
curl https://app.tudominio.com
```

#### 5.4 Verificar desde Móvil

Abrir en tu navegador móvil:
```
https://app.tudominio.com
```

## 🎊 ¡Felicitaciones!

Tu aplicación ahora está:
- ✅ Desplegada en producción
- ✅ Conectada a SQL Server local
- ✅ Accesible desde internet de forma segura
- ✅ Protegida por Cloudflare
- ✅ Funcionando con SSL/TLS

## 📱 Uso desde Móvil

Tu aplicación Blazor Server funciona perfectamente en navegadores móviles:

1. **Safari (iOS):** `https://app.tudominio.com`
2. **Chrome (Android):** `https://app.tudominio.com`

Para una mejor experiencia móvil:
- Habilitar "Agregar a Pantalla de Inicio" (PWA)
- La aplicación funcionará como una app nativa
- SignalR mantiene la conexión en tiempo real

## 🔧 Comandos Útiles

### Ver Logs

**Windows:**
```powershell
# IIS
Get-EventLog -LogName Application -Source "IIS AspNetCore Module V2" -Newest 20

# Cloudflared
Get-EventLog -LogName Application -Source cloudflared -Newest 20
```

**Linux:**
```bash
# Aplicación
journalctl -u dogo2 -f

# Nginx
tail -f /var/log/nginx/dogo2_access.log

# Cloudflared
journalctl -u cloudflared -f
```

### Reiniciar Servicios

**Windows:**
```powershell
# Aplicación
Restart-WebAppPool -Name "DOGO2AppPool"

# Cloudflared
Restart-Service cloudflared
```

**Linux:**
```bash
# Aplicación
sudo systemctl restart dogo2

# Nginx
sudo systemctl restart nginx

# Cloudflared
sudo systemctl restart cloudflared
```

### Verificar Estado

```bash
# Túnel Cloudflare
cloudflared tunnel list
cloudflared tunnel info dogo2-tunnel

# SQL Server (Windows)
Get-Service MSSQL*

# Aplicación (Linux)
sudo systemctl status dogo2
```

## ⚠️ Problemas Comunes

### "No se puede conectar a SQL Server"

**Solución:**
1. Verificar que SQL Server está corriendo
2. Verificar que TCP/IP está habilitado
3. Verificar firewall de Windows
4. Probar conexión local primero

```powershell
# Verificar servicio
Get-Service MSSQL*

# Verificar puerto
Test-NetConnection -ComputerName localhost -Port 1433
```

### "Cloudflare Tunnel ERR Connection terminated"

**Solución:**
1. Verificar que cloudflared está corriendo
2. Revisar archivo config.yml
3. Verificar que el túnel existe

```bash
# Ver túneles
cloudflared tunnel list

# Ver estado
cloudflared tunnel info dogo2-tunnel

# Reiniciar
sudo systemctl restart cloudflared
```

### "HTTP Error 500.30"

**Solución:**
1. Verificar .NET Runtime instalado
2. Revisar connection string
3. Ver logs de la aplicación

```bash
# Verificar .NET
dotnet --list-runtimes

# Ejecutar manualmente para ver error
cd /var/www/dogo2
dotnet DOGO2.dll
```

### "Login failed for user 'sa_app'"

**Solución:**
1. Verificar que el usuario existe
2. Verificar la contraseña
3. Verificar modo de autenticación de SQL Server

```sql
-- Verificar usuario
SELECT name FROM sys.server_principals WHERE name = 'sa_app';

-- Verificar modo de autenticación
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly');
-- Debe retornar 0
```

## 📚 Próximos Pasos

1. **Configurar SSL** en tu dominio (Cloudflare lo hace automáticamente)
2. **Backup automático** de la base de datos
3. **Monitoreo** con Cloudflare Analytics
4. **WAF** (Web Application Firewall) de Cloudflare
5. **Rate Limiting** para protección adicional

## 🆘 Ayuda

Si tienes problemas:

1. **Lee la documentación completa:** [DEPLOYMENT-SQLSERVER-CLOUDFLARE.md](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md)
2. **Revisa los logs** de cada componente
3. **Abre un issue** en GitHub con:
   - Descripción del problema
   - Logs relevantes
   - Pasos para reproducir

## 📖 Recursos Adicionales

- [Documentación Completa](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md)
- [README Principal](./README.md)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Blazor Docs](https://docs.microsoft.com/aspnet/core/blazor/)

---

**¿Funcionó todo?** ¡Excelente! Ahora tienes una aplicación web profesional desplegada con las mejores prácticas de seguridad.

**¿Tienes problemas?** Consulta la sección de [Troubleshooting](#-problemas-comunes) o la [documentación completa](./DEPLOYMENT-SQLSERVER-CLOUDFLARE.md#troubleshooting).
