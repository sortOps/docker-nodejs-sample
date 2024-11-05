# test stage
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm test && npm prune --production

# Final stage
FROM node:18-alpine

WORKDIR /app

RUN mkdir -p /kaniko/.docker && \
    echo '{"auths":{}}' > /kaniko/.docker/config.json && \
    chmod 600 /kaniko/.docker/config.json

COPY --from=builder /app/src ./src
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

ENV NODE_ENV=production
ENV PORT=3000
ENV DOCKER_CONFIG=/kaniko/.docker

RUN addgroup -g 1001 nodejs && \
    adduser -u 1001 -G nodejs -s /bin/sh -D nodejs && \
    chown -R nodejs:nodejs /app /kaniko

EXPOSE 3000

USER nodejs

CMD ["node", "src/index.js"]
