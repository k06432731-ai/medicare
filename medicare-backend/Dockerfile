# syntax=docker/dockerfile:1.7
# ============================================================
#  Medicare Strapi v5 - Production Dockerfile (multi-stage)
# ============================================================

# ------------------------------------------------------------
# Stage 1: builder - install ALL deps + build the admin panel
# ------------------------------------------------------------
FROM node:22-alpine AS builder

# Native build deps for better-sqlite3, sharp, node-gyp, etc.
RUN apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    vips-dev \
    python3 \
    git

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package.json package-lock.json* ./
RUN npm ci

# Copy the rest of the source
COPY . .

# Build the admin panel for production
ENV NODE_ENV=production
RUN npm run build

# Prune dev dependencies after build
RUN npm prune --omit=dev


# ------------------------------------------------------------
# Stage 2: runtime - minimal image with built app only
# ------------------------------------------------------------
FROM node:22-alpine AS runtime

# Runtime libs (sharp + sqlite native bindings)
RUN apk add --no-cache \
    vips-dev \
    tini

WORKDIR /app

ENV NODE_ENV=production \
    PATH=/app/node_modules/.bin:$PATH

# Copy built app and prod-only node_modules from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json* ./
COPY --from=builder /app/build ./build
COPY --from=builder /app/config ./config
COPY --from=builder /app/database ./database
COPY --from=builder /app/public ./public
COPY --from=builder /app/src ./src
COPY --from=builder /app/types ./types
COPY --from=builder /app/favicon.png ./favicon.png

# Ensure uploads dir exists and is writable (Fly volume mount target)
RUN mkdir -p /app/public/uploads && chown -R node:node /app

USER node

# Strapi serves on 1337 by default
EXPOSE 1337

# Lightweight healthcheck — Strapi answers 200 on /_health
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:1337/_health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["npm", "run", "start"]
