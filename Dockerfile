# Build stage
FROM gcr.io/kaniko-project/executor:latest AS builder

# Set working directory
WORKDIR /workspace

# Copy source code
COPY . .

# Configure Kaniko cache and credentials
ENV DOCKER_CONFIG /kaniko/.docker/
COPY config.json /kaniko/.docker/

# Build arguments
ARG TARGETARCH
ARG BUILDPLATFORM

# Build the application with Kaniko
FROM scratch
COPY --from=builder /workspace/src /app/src
COPY --from=builder /workspace/package*.json /app/

# Kaniko specific build commands
RUN /kaniko/executor \
    --context=/workspace \
    --dockerfile=Dockerfile \
    --destination=your-registry/nodejs-app:latest \
    --reproducible \
    --use-new-run \
    --single-snapshot \
    --skip-unused-stages \
    --snapshotMode=full \
    --verbosity=info

# Runtime configuration
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Set user to non-root
USER 65532:65532

# Start the application
CMD ["node", "/app/src/index.js"]