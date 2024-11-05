# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./
RUN npm ci

# Copy source files and run tests
COPY . .
RUN npm test && npm prune --production

# Final stage
FROM node:18-alpine

WORKDIR /app

# Create docker config directory first
RUN mkdir -p /kaniko/.docker && \
    echo '{"auths":{}}' > /kaniko/.docker/config.json && \
    chmod 600 /kaniko/.docker/config.json

# Copy built application
COPY --from=builder /app/src ./src
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV DOCKER_CONFIG=/kaniko/.docker

# Security settings
RUN addgroup -g 1001 nodejs && \
    adduser -u 1001 -G nodejs -s /bin/sh -D nodejs && \
    chown -R nodejs:nodejs /app /kaniko

# Expose port
EXPOSE 3000

# Switch to non-root user
USER nodejs

# Start application
CMD ["node", "src/index.js"]