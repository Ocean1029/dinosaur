#!/bin/bash
set -e

# Run Prisma migrations before starting the application
# Use npx to find prisma CLI (works even if prisma is in devDependencies and was pruned)
echo "Running database migrations..."
if command -v npx >/dev/null 2>&1; then
  npx prisma migrate deploy || echo "Migration failed or no migrations to run"
else
  npm run prisma:migrate || echo "Migration failed or no migrations to run"
fi

# Start the application
echo "Starting application..."
exec npm run start

