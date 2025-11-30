# Secure File Print System - Deployment Guide

This guide explains how to deploy the Secure File Print System using Docker and build the client applications.

## 📋 Prerequisites

### For Backend Deployment (Docker)
- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB of free disk space
- **Node.js 14+** (for generating secure secrets) OR OpenSSL

### For Client Builds
- Flutter SDK 3.0+
- Dart SDK (included with Flutter)
- Android SDK (for mobile builds)
- Platform-specific tools:
  - **Windows**: Visual Studio 2019+ with Desktop development with C++
  - **Linux**: Build essentials (`sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`)
  - **macOS**: Xcode 12+

## 🚀 Backend Deployment

### Quick Start

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Set up environment variables** (IMPORTANT for production):
   ```bash
   # Copy the example environment file
   cp docker.env.example .env
   
   # Edit .env and replace all CHANGE_ME_* values with secure credentials
   # Generate secrets using Node.js (requires Node.js installed):
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   
   # OR using OpenSSL (if Node.js not available):
   openssl rand -hex 32
   ```

3. **Start the services**:
   ```bash
   docker-compose up --build
   ```

4. **Verify deployment**:
   ```bash
   # Check service status
   docker-compose ps
   
   # Test the API health endpoint
   curl http://localhost:5000/health
   ```

### Production Deployment

For production environments:

1. **Configure environment variables** in the `.env` file (NOT in docker-compose.yml):
   
   ```bash
   # Create .env file from template
   cp docker.env.example .env
   
   # Edit .env file and set the following:
   nano .env
   ```
   
   **Required variables in `.env`:**
   - `POSTGRES_USER`: Database username (change from default)
   - `POSTGRES_PASSWORD`: Strong database password
   - `POSTGRES_DB`: Database name
   - `JWT_SECRET`: Strong random secret (64 chars hex)
   - `JWT_REFRESH_SECRET`: Strong random secret (64 chars hex)
   - `ENCRYPTION_KEY`: Strong random secret (64 chars hex)
   - `CORS_ORIGIN`: Allowed origins (e.g., `https://yourdomain.com`)
   - `CORS_CREDENTIALS`: Set to `true` or `false`
   
   **⚠️ Important:**
   - **DO NOT** edit `docker-compose.yml` directly to add secrets (they may be committed)
   - Use `.env` file for simple deployments (local/development)
   - For production: Use `docker-compose.override.yml`, environment variables from CI/CD, or secrets managers (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault)
   - See `backend/ENV_CONFIG_GUIDE.md` for detailed configuration instructions

2. **Use production-grade database**:
   - Consider using a managed PostgreSQL service (AWS RDS, Azure Database, Google Cloud SQL)
   - Update `DB_HOST` and credentials accordingly

3. **Enable HTTPS**:
   - Add a reverse proxy (nginx, Traefik) with SSL/TLS certificates
   - Use Let's Encrypt for free SSL certificates

4. **Configure persistent volumes**:
   - Ensure `uploads` and `logs` directories are backed up
   - Consider using cloud storage (S3, Azure Blob) for file uploads

### Docker Commands Reference

```bash
# Start services in background
docker-compose up -d

# View logs
docker-compose logs -f backend
docker-compose logs -f postgres

# Stop services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Rebuild and restart
docker-compose up --build --force-recreate

# View resource usage
docker stats
```

## 📱 Client Application Builds

### Windows

Run the batch script:
```cmd
build_clients.bat
```

### Linux/macOS

1. Make the script executable:
   ```bash
   chmod +x build_clients.sh
   ```

2. Run the script:
   ```bash
   ./build_clients.sh
   ```

### Build Outputs

Build artifacts are created in the `builds/` directory:

- **Mobile App**: `mobile_app_YYYYMMDD_HHMMSS.apk`
- **Desktop App**: `desktop_app_[platform]_YYYYMMDD_HHMMSS/`
- **Owner App**: `owner_app_[platform]_YYYYMMDD_HHMMSS/`

### Manual Flutter Builds

If you prefer to build manually:

#### Mobile App (Android)
```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

#### Desktop App (Windows)
```bash
cd desktop_app
flutter clean
flutter pub get
flutter build windows --release
# Build location: build/windows/runner/Release/
```

#### Desktop App (Linux)
```bash
cd desktop_app
flutter clean
flutter pub get
flutter build linux --release
# Build location: build/linux/x64/release/bundle/
```

#### Owner App
Follow the same process as the Desktop App, replacing `desktop_app` with `owner_app`.

## 🔒 Security Checklist

Before deploying to production:

- [ ] Replace all default credentials in `.env`
- [ ] Generate strong random secrets (minimum 32 characters)
- [ ] Configure appropriate CORS origins
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Review and update security headers
- [ ] Set up monitoring and alerting
- [ ] Document disaster recovery procedures

## 🧪 Testing the Deployment

### Backend API Tests

```bash
# Health check
curl http://localhost:5000/health

# Test authentication endpoint
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"<your-actual-admin-password>"}'

# Note: Update email and password with actual credentials created during initial setup

# Check database connection
docker-compose exec backend node -e "
  const {Pool} = require('pg');
  const pool = new Pool({
    host: 'postgres',
    user: process.env.POSTGRES_USER || 'postgres',
    password: process.env.POSTGRES_PASSWORD || 'postgres',
    database: 'secure_print'
  });
  pool.query('SELECT NOW()', (err, res) => {
    console.log(err ? 'DB Error' : 'DB Connected:', res.rows[0]);
    pool.end();
  });"
```

### Client Application Tests

1. **Mobile App**: Install the APK on an Android device or emulator
2. **Desktop App**: Run the executable from the build directory
3. **Owner App**: Run the executable and test owner-specific features

## 📊 Monitoring

### Container Health

```bash
# Check container health status
docker-compose ps

# View real-time logs
docker-compose logs -f

# Monitor resource usage
docker stats
```

### Application Logs

- Backend logs: `backend/logs/app.log`
- Docker logs: `docker-compose logs backend`

## 🐛 Troubleshooting

### Backend won't start

1. Check logs: `docker-compose logs backend`
2. Verify environment variables are set correctly
3. Ensure database is healthy: `docker-compose ps`

### Database connection errors

1. Check postgres health: `docker-compose exec postgres pg_isready`
2. Verify credentials match in both services
3. Check network connectivity: `docker network inspect prefinal_secure_print_network`

### Client build failures

1. Run `flutter doctor` to check SDK installation
2. Ensure all dependencies are installed
3. Clear build cache: `flutter clean`
4. Check platform-specific requirements

## 📝 Additional Documentation

- [Backend API Guide](backend/API_GUIDE.md)
- [Backend README](backend/README.md)
- [Security Guidelines](backend/CREDENTIALS_SECURITY.md)
- [Project Overview](00_START_HERE_FIRST.md)

## 🆘 Support

For issues or questions:
1. Check existing documentation
2. Review error logs
3. Consult the project's issue tracker
4. Contact the development team

## 📜 License

PROPRIETARY - See LICENSE file for details
