#!/bin/sh

# Cloud Run provides PORT environment variable
# Default to 8080 if not set
WEB_PORT=${PORT:-8080}

# Start Mailpit with dynamic port binding
exec /mailpit \
  --smtp 0.0.0.0:1025 \
  --listen 0.0.0.0:${WEB_PORT} \
  --smtp-auth-accept-any \
  --smtp-auth-allow-insecure \
  --max 5000
