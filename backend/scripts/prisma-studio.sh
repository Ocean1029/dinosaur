#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BACKEND_DIR")"

# Change to backend directory
cd "$BACKEND_DIR"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env.dev" ]; then
    set -a
    source "$PROJECT_ROOT/.env.dev"
    set +a
fi

# Replace db:5432 with localhost:5432 for local Prisma Studio connection
export DATABASE_URL="${DATABASE_URL/db:5432/localhost:5432}"

echo "Starting Prisma Studio..."
echo "Database URL: ${DATABASE_URL}"
echo "Prisma Studio will be available at http://localhost:5555"
echo ""

npm run prisma:studio

