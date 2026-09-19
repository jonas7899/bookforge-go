#!/bin/bash

# Bookforge - Project Setup Script
# This script initializes the project with git submodules and dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Bookforge - Home library Copywriting SaaS - Setup   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed${NC}"
    exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed${NC}"
    echo -e "${YELLOW}Please install Go 1.22 or later from https://golang.org/dl/${NC}"
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
echo -e "${GREEN}✓ Go version: ${GO_VERSION}${NC}"

# Check if Docker is installed (optional but recommended)
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠ Warning: Docker is not installed (recommended for local development)${NC}"
else
    echo -e "${GREEN}✓ Docker installed${NC}"
fi

echo ""
echo -e "${CYAN}Step 1: Initializing Git submodules...${NC}"

# Initialize git if not already initialized
if [ ! -d .git ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
fi

# Check if submodules are already added
if [ ! -f .gitmodules ]; then
    echo -e "${YELLOW}Adding submodules...${NC}"
    
    # Add config-go submodule
    if [ ! -d "04_common/config-go" ]; then
        git clone --recurse-submodules https://github.com/jonas7899/config-go
        echo -e "${GREEN}✓ config-go submodule added${NC}"
    else
        echo -e "${YELLOW}config-go already exists${NC}"
    fi
    
    # Add logger-go submodule
    if [ ! -d "04_common/logger-go" ]; then
        git clone --recurse-submodules https://github.com/jonas7899/logger-go
        echo -e "${GREEN}✓ logger-go submodule added${NC}"
    else
        echo -e "${YELLOW}logger-go already exists${NC}"
    fi
else
    echo -e "${YELLOW}Submodules already configured, updating...${NC}"
    git submodule update --init --recursive
    echo -e "${GREEN}✓ Submodules updated${NC}"
fi

echo ""
echo -e "${CYAN}Step 2: Setting up environment files...${NC}"

# Copy .env.example to .env if not exists
if [ ! -f .env ]; then
    cp 05_config/.env.example 05_config/.env
    echo -e "${GREEN}✓ Created .env file from .env.example${NC}"
    echo -e "${YELLOW}⚠ IMPORTANT: Edit .env and add your API keys!${NC}"
else
    echo -e "${YELLOW}.env already exists (skipping)${NC}"
fi

echo ""
echo -e "${CYAN}Step 3: Installing Go dependencies...${NC}"

# Backend dependencies
if [ -d 02_backend ]; then
    echo -e "${YELLOW}Installing backend dependencies...${NC}"
    cd 02_backend
    go mod download
    echo -e "${GREEN}✓ Backend dependencies installed${NC}"
    cd ..
fi

# Frontend dependencies
if [ -d 03_frontend_htmx ]; then
    echo -e "${YELLOW}Installing frontend dependencies...${NC}"
    cd 03_frontend_htmx
    go mod download
    echo -e "${GREEN}✓ Frontend dependencies installed${NC}"
    cd ..
fi

echo ""
echo -e "${CYAN}Step 4: Checking for required tools...${NC}"

# Check for goose (database migrations)
if ! command -v goose &> /dev/null; then
    echo -e "${YELLOW}Installing goose (database migrations)...${NC}"
    go install github.com/pressly/goose/v3/cmd/goose@latest
    echo -e "${GREEN}✓ goose installed${NC}"
else
    echo -e "${GREEN}✓ goose already installed${NC}"
fi

# Check for swag (Swagger docs)
if ! command -v swag &> /dev/null; then
    echo -e "${YELLOW}Installing swag (Swagger documentation)...${NC}"
    go install github.com/swaggo/swag/cmd/swag@latest
    echo -e "${GREEN}✓ swag installed${NC}"
else
    echo -e "${GREEN}✓ swag already installed${NC}"
fi

# Check for golangci-lint (optional but recommended)
if ! command -v golangci-lint &> /dev/null; then
    echo -e "${YELLOW}golangci-lint not found (optional, for linting)${NC}"
    echo -e "${YELLOW}Install from: https://golangci-lint.run/usage/install/${NC}"
else
    echo -e "${GREEN}✓ golangci-lint installed${NC}"
fi

echo ""
echo -e "${CYAN}Step 5: Creating necessary directories...${NC}"


echo -e "${GREEN}✓ Directory structure created${NC}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Setup Complete! 🎉                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo -e "1. ${YELLOW}Edit .env file with your API keys:${NC}"
echo -e "   nano .env"
echo ""
echo -e "2. ${YELLOW}Start infrastructure (PostgreSQL + Redis):${NC}"
echo -e "   make docker-up"
echo ""
echo -e "3. ${YELLOW}Run database migrations:${NC}"
echo -e "   make migrate-up"
echo ""
echo -e "4. ${YELLOW}Start backend server:${NC}"
echo -e "   make run-backend"
echo ""
echo -e "5. ${YELLOW}Start frontend server (in another terminal):${NC}"
echo -e "   make run-frontend"
echo ""
echo -e "${CYAN}For more commands, run:${NC} make help"
echo ""
