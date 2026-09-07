# Multi-stage Dockerfile for DeepSeek Harness (DSH)
# Stage 1: Build & compilation
FROM node:22-slim AS builder

WORKDIR /app

# Install system dependencies needed for native modules & build
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm matching packageManager version
RUN corepack enable && corepack prepare pnpm@11.7.0 --activate

# Copy package manifests and workspace structure
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches ./patches
COPY packages ./packages
COPY apps ./apps
COPY scripts ./scripts
COPY vendor ./vendor
COPY website ./website
COPY tsconfig*.json tsdown.config.ts vitest*.ts ./

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Build libraries and web app
RUN pnpm run build

# Stage 2: Runtime image
FROM node:22-slim AS runner

WORKDIR /app

# Install runtime dependencies (git, curl for agent tools and healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@11.7.0 --activate

# Create non-root user and persistent directories
RUN useradd -m -u 1001 -s /bin/bash dshuser && \
    mkdir -p /data/dsh /data/workspaces /app && \
    chown -R dshuser:dshuser /data /app

# Copy built application from builder
COPY --from=builder --chown=dshuser:dshuser /app /app

USER dshuser

# Default environment
ENV NODE_ENV=production \
    DSH_HOME=/data/dsh \
    DSH_AGENTS_HOME=/data/dsh/.agents \
    PORT=3080 \
    HOST=0.0.0.0

EXPOSE 3080

VOLUME ["/data"]

# Start web interface in headless/server mode
CMD ["node", "--import", "tsx/esm", "apps/cli/src/bin.ts", "web", "--no-open", "--port", "3080", "--host", "0.0.0.0"]
