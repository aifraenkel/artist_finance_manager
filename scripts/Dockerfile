# Dockerfile for Artist Finance Manager - Flutter Web App
# Optimized for Google Cloud Run deployment
# Two-stage build: Build Flutter web app, then serve with nginx

# ================================
# Stage 1: Build Flutter Web App
# ================================
FROM debian:bookworm-slim AS build

# Install Flutter dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ENV FLUTTER_VERSION=3.38.3
ENV FLUTTER_HOME=/opt/flutter
RUN git clone --branch ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME}
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Pre-download Flutter dependencies and enable web
RUN flutter doctor -v && \
    flutter config --enable-web && \
    flutter precache --web

# Set working directory
WORKDIR /app

# Copy pubspec files and get dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the Flutter web app in release mode
RUN flutter build web --release

# ================================
# Stage 2: Serve with Nginx
# ================================
FROM nginx:alpine

# Remove default nginx config and static files
RUN rm -rf /usr/share/nginx/html/* && \
    rm /etc/nginx/conf.d/default.conf

# Copy built Flutter web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration (already includes port 8080 and /health endpoint)
COPY nginx.conf /etc/nginx/nginx.conf

# Add PID location for non-root user (Cloud Run requirement)
RUN sed -i '1i pid /tmp/nginx.pid;' /etc/nginx/nginx.conf

# Add a simple health check endpoint

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Configure nginx to run as non-root user (Cloud Run requirement)
# Create necessary directories and set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid && \
    # Ensure nginx can write to /tmp
    chmod 1777 /tmp

# Run as non-root user
USER nginx

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

# Metadata
LABEL maintainer="Artist Finance Manager Team"
LABEL description="Flutter web app for tracking artist project finances"
LABEL version="1.0.0"
