FROM axllent/mailpit:latest

# Mailpit runs on:
# - Port 1025: SMTP server
# - Dynamic port: Web UI (reads from $PORT)

EXPOSE 1025 8080

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use custom entrypoint that reads Cloud Run's PORT env var
ENTRYPOINT ["/entrypoint.sh"]
