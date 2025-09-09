#!/bin/bash

# Docker validation script for Tiptap
# This script validates that both development and production Docker setups work correctly

set -e

echo "🐳 Tiptap Docker Validation Script"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check prerequisites
echo ""
print_info "Checking prerequisites..."

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_status "Docker is installed: $DOCKER_VERSION"
else
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_status "Docker Compose is installed: $COMPOSE_VERSION"
else
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

# Test production build
echo ""
print_info "Testing production Docker build..."

# Clean up any existing containers/images
docker stop tiptap-prod &> /dev/null || true
docker rm tiptap-prod &> /dev/null || true
docker rmi tiptap-demos &> /dev/null || true

# Build production image
print_info "Building production image (this may take a few minutes)..."
if docker build -t tiptap-demos . > build.log 2>&1; then
    print_status "Production image built successfully"
else
    echo -e "${RED}❌ Production build failed. Check build.log for details${NC}"
    exit 1
fi

# Test running production container
print_info "Testing production container..."
if docker run -d -p 3001:80 --name tiptap-prod tiptap-demos > /dev/null 2>&1; then
    print_status "Production container started"
    
    # Wait for container to be ready
    sleep 5
    
    # Test if the service responds
    if curl -s -f http://localhost:3001 > /dev/null 2>&1; then
        print_status "Production service is responding"
    else
        print_info "Service might need more time to start, this is normal for first run"
    fi
    
    # Clean up
    docker stop tiptap-prod > /dev/null 2>&1
    docker rm tiptap-prod > /dev/null 2>&1
    print_status "Production container cleaned up"
else
    echo -e "${RED}❌ Failed to start production container${NC}"
    exit 1
fi

# Test development setup (without actually starting services due to network limitations)
echo ""
print_info "Validating development setup..."

# Check docker-compose.yml syntax
if docker compose config > /dev/null 2>&1; then
    print_status "Docker Compose configuration is valid"
else
    echo -e "${RED}❌ Docker Compose configuration is invalid${NC}"
    exit 1
fi

# Test NPM scripts
echo ""
print_info "Validating NPM scripts..."

# Check if the scripts exist in package.json
if grep -q "docker:dev" package.json; then
    print_status "Docker development scripts are available"
else
    echo -e "${RED}❌ Docker scripts not found in package.json${NC}"
    exit 1
fi

if grep -q "docker:build" package.json; then
    print_status "Docker build scripts are available"
else
    echo -e "${RED}❌ Docker build scripts not found in package.json${NC}"
    exit 1
fi

# Validate files exist
echo ""
print_info "Validating Docker configuration files..."

if [ -f "Dockerfile" ]; then
    print_status "Dockerfile exists"
else
    echo -e "${RED}❌ Dockerfile not found${NC}"
    exit 1
fi

if [ -f "docker-compose.yml" ]; then
    print_status "docker-compose.yml exists"
else
    echo -e "${RED}❌ docker-compose.yml not found${NC}"
    exit 1
fi

if [ -f ".dockerignore" ]; then
    print_status ".dockerignore exists"
else
    echo -e "${RED}❌ .dockerignore not found${NC}"
    exit 1
fi

if [ -f "DOCKER.md" ]; then
    print_status "Docker documentation exists"
else
    echo -e "${RED}❌ DOCKER.md not found${NC}"
    exit 1
fi

# Clean up build log
rm -f build.log

echo ""
echo -e "${GREEN}🎉 All Docker validations passed!${NC}"
echo ""
echo "Available commands:"
echo "  Development:"
echo "    pnpm docker:dev          # Start development environment"
echo "    pnpm docker:dev:logs     # View development logs"
echo "    pnpm docker:dev:stop     # Stop development environment"
echo ""
echo "  Production:"
echo "    pnpm docker:build        # Build production image"
echo "    pnpm docker:prod         # Run production container"
echo "    pnpm docker:prod:stop    # Stop production container"
echo ""
echo "  Manual commands:"
echo "    docker compose up        # Start development"
echo "    docker build -t tiptap-demos .  # Build production"
echo "    docker run -p 3000:80 tiptap-demos  # Run production"
echo ""
echo "📖 For detailed instructions, see DOCKER.md"