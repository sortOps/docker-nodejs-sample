# Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Run tests
RUN npm test

# Production stage
FROM gcr.io/kaniko-project/executor:latest AS kaniko

# Set workspace
WORKDIR /workspace

# Copy built application from builder
COPY --from=builder /app .

# Build arguments for Kaniko
ENV DOCKER_CONFIG=/kaniko/.docker

# Create empty Docker config if not exists
RUN mkdir -p /kaniko/.docker && \
    echo '{"auths": {}}' > /kaniko/.docker/config.json

# Kaniko build command
FROM scratch

# Copy application files
COPY --from=builder /app/src /app/src
COPY --from=builder /app/package*.json /app/

# Runtime configuration
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Use non-root user
USER 65532:65532

# Start command
CMD ["node", "/app/src/index.js"]