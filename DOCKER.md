# Docker Guide for Tiptap

This guide explains how to build and run Tiptap using Docker containers. There are two main approaches:

1. **Development mode** - Using Docker Compose for local development with hot reload
2. **Production mode** - Using Dockerfile to build a production-ready image

## Prerequisites

- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)

## Development Mode (Recommended for development)

### Quick Start

The easiest way to get started with development is using Docker Compose:

```bash
# Start the development server
docker compose up

# Or run in detached mode
docker compose up -d

# View logs
docker compose logs -f

# Stop the containers
docker compose down
```

### What happens:

- Mounts your local directory as a volume inside the container
- Installs dependencies with `pnpm install`
- Starts the Vite development server on port 5173
- Enables hot reload - your changes will be reflected immediately
- All package dependencies are installed fresh on each startup

### Access the application:

Open your browser and navigate to: `http://localhost:5173`

### Viewing logs:

```bash
# View logs for all services
docker compose logs

# Follow logs in real-time
docker compose logs -f

# View logs for specific service
docker compose logs web
```

### Stopping the development environment:

```bash
# Stop and remove containers
docker compose down

# Stop, remove containers and volumes
docker compose down -v
```

## Production Mode

### Building the production image

```bash
# Build the production image
docker build -t tiptap-demos .

# Build with no cache (useful for clean builds)
docker build --no-cache -t tiptap-demos .
```

### What the build does:

1. **Build stage**: Uses Node.js Alpine image to:
   - Install dependencies with pnpm
   - Build all packages using Turbo
   - Build the demos using Vite
   
2. **Production stage**: Uses nginx Alpine image to:
   - Copy the built static files
   - Serve them on port 80

### Running the production container

```bash
# Run the production container
docker run -p 3000:80 tiptap-demos

# Run in detached mode
docker run -d -p 3000:80 --name tiptap-prod tiptap-demos

# Stop the production container
docker stop tiptap-prod
docker rm tiptap-prod
```

### Access the production application:

Open your browser and navigate to: `http://localhost:3000`

## NPM Scripts for Docker

You can add these convenient scripts to your workflow:

### Development scripts:

```bash
# Start development environment
npm run docker:dev
# or
pnpm docker:dev

# View development logs
npm run docker:dev:logs
# or  
pnpm docker:dev:logs

# Stop development environment
npm run docker:dev:stop
# or
pnpm docker:dev:stop
```

### Production scripts:

```bash
# Build production image
npm run docker:build
# or
pnpm docker:build

# Run production container
npm run docker:prod
# or
pnpm docker:prod

# Stop production container
npm run docker:prod:stop
# or
pnpm docker:prod:stop
```

## Docker Configuration Files

### Dockerfile

The `Dockerfile` creates a production-ready image:
- **Multi-stage build** for optimized final image size
- **Build stage**: Compiles TypeScript, builds packages, and creates static files
- **Production stage**: Serves static files with nginx

### docker-compose.yml

The `docker-compose.yml` provides a development environment:
- **Volume mounting** for live code updates
- **Automatic dependency installation**
- **Hot reload support**
- **Environment variables** for proper Vite configuration

### .dockerignore

The `.dockerignore` file excludes unnecessary files from the Docker build context:
- `node_modules/`
- `dist/`
- `.git/`
- Build artifacts

## Troubleshooting

### Common Issues

**Port already in use:**
```bash
# Check what's using the port
lsof -i :5173  # for development
lsof -i :3000  # for production

# Use different ports
docker run -p 8080:80 tiptap-demos  # production on port 8080
# or modify docker-compose.yml ports section
```

**Build failures:**
```bash
# Clean build with no cache
docker build --no-cache -t tiptap-demos .

# Check Docker build logs
docker build -t tiptap-demos . --progress=plain
```

**Development container issues:**
```bash
# Remove containers and volumes
docker compose down -v

# Rebuild containers
docker compose up --build
```

**Permission issues (Linux/macOS):**
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

### Resource Requirements

**Development mode:**
- RAM: ~2GB (for Node.js + dependencies)
- CPU: Moderate (builds on startup)
- Disk: ~1GB (dependencies + source)

**Production mode:**
- RAM: ~128MB (nginx only)
- CPU: Low (static serving)
- Disk: ~50MB (built static files)

### Network Issues

If you're having network connectivity issues in containers:

```bash
# Check Docker network
docker network ls

# Restart Docker daemon (Linux/macOS)
sudo systemctl restart docker

# Reset Docker networks
docker network prune
```

## Advanced Usage

### Custom Environment Variables

For development with environment variables:

```yaml
# docker-compose.override.yml
services:
  web:
    environment:
      - VITE_COLLAB_ROOMS=custom_value
      - VITE_API_URL=http://localhost:8080
```

### Using Different Node Versions

To use a different Node.js version, modify the Dockerfile:

```dockerfile
# Use Node 18 instead of 20
FROM node:18-alpine AS build
```

### Mounting Specific Directories

For more selective volume mounting:

```yaml
services:
  web:
    volumes:
      - ./packages:/repo/packages
      - ./demos:/repo/demos
      # Don't mount node_modules
```

## Performance Tips

1. **Use .dockerignore** - Exclude unnecessary files from build context
2. **Layer caching** - Order Dockerfile commands from least to most frequently changing
3. **Multi-stage builds** - Keep production images small
4. **Volume mounting** - Use for development to avoid rebuilds

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Docker Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t tiptap-demos .
      - name: Test image
        run: |
          docker run -d -p 3000:80 --name test tiptap-demos
          sleep 10
          curl -f http://localhost:3000
          docker stop test
```

This guide provides everything you need to containerize Tiptap for both development and production use cases.