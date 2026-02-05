# syntax=docker/dockerfile:1.6

########################################
# Base Stage: Shared environment
########################################
FROM node:20-slim AS base

# Install openssl (required by Prisma engines)
RUN apt-get update && apt-get install -y openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV NODE_ENV=production

########################################
# Deps Stage: Install all dependencies
# Use npm ci for reproducible builds
########################################
FROM base AS deps
ENV NODE_ENV=development

# Only copy dependency files for caching
COPY package.json package-lock.json* ./

# Install dev deps as well so build and prisma generate can run
RUN npm ci --include=dev

########################################
# Build Stage: Compile TS & generate Prisma client
########################################
FROM deps AS build

# Copy build-related files only
COPY tsconfig.json tsconfig.build.json .eslintrc.cjs ./
COPY prisma ./prisma
COPY src ./src
COPY scripts ./scripts

# Generate Prisma Client once in build stage
RUN npm run prisma:generate

# Compile TS code
RUN npm run build

########################################
# Development Stage: For local development
########################################
FROM deps AS development
ENV NODE_ENV=development

# Copy full project to support dev mode
COPY . .

# Expose dev port
EXPOSE 3000

# Start in dev mode (with hot reload)
CMD ["npm", "run", "dev"]

########################################
# Production Stage: Minimal runtime image
########################################
FROM base AS production

# Copy package files
COPY package.json package-lock.json* ./

# Copy node_modules from build stage (contains generated Prisma Client)
# This ensures Prisma Client is available in production
COPY --from=build /app/node_modules ./node_modules

# Copy build output and necessary prisma files
COPY --from=build /app/dist ./dist
COPY prisma ./prisma

# Copy docs directory for Swagger YAML files (needed at runtime)
COPY --from=build /app/src/docs ./src/docs

# Copy start script for running migrations before app starts
COPY --from=build /app/scripts/start.sh ./scripts/start.sh
RUN chmod +x ./scripts/start.sh

# Install prisma CLI as production dependency for running migrations
# Prisma is needed at runtime for migrations, so we install it separately
RUN npm install --save prisma@^5.14.0

# Remove other devDependencies to shrink size
RUN npm prune --omit=dev

# Cloud Run will set PORT environment variable, default to 8080 for Cloud Run
ENV PORT=8080

# Expose the port (Cloud Run uses PORT env var, but EXPOSE helps with documentation)
EXPOSE 8080

# Use start script that runs migrations before starting the app
CMD ["./scripts/start.sh"]
