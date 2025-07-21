# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o bbs-go main.go

# Runtime stage
FROM node:18-alpine

WORKDIR /app

# Copy configuration file from builder
COPY --from=builder /app/bbs-go.yaml .

# Set runtime environment variables
ENV BBSGO_CONFIG=/app/bbs-go.yaml
ENV BBSGO_ENV=prod
ENV PORT=8082

# Install PM2 process manager
RUN npm install -g pm2

# Copy application artifacts
COPY --from=builder /app/bbs-go .
COPY start.sh .
RUN chmod +x start.sh
EXPOSE 8082

# Verify configuration file exists
RUN test -f bbs-go.yaml || (echo "Configuration file missing!" && exit 1)

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app
USER appuser

# Health check configuration
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:${PORT}/api/user/current || exit 1

# Start application
CMD ["sh", "./start.sh"]