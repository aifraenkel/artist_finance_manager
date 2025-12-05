# Multi-stage Docker build for Flutter web app
# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configure Flutter
RUN flutter doctor -v
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy Flutter project files
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the Flutter web app
RUN flutter build web --release

# Stage 2: Setup the nginx server
FROM nginx:alpine

# Copy the built web app from the build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 8080 (Cloud Run uses 8080 by default)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
