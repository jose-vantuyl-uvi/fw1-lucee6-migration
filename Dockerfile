# Lucee 6 Docker Image for FW/1 Groups Online Payment
# Based on Lucee official image with nginx
# Using Lucee 6.0 (latest stable 6.0.x release)
# Note: server.json specifies lucee@6.0.2.45 for CommandBox, but Docker uses different tags
# Available tags: 6.0-nginx, 6.0.3.1-nginx, etc.
# See: https://hub.docker.com/r/lucee/lucee/tags

FROM lucee/lucee:6.0-nginx

# Install gettext for envsubst (used by initContainer for config substitution)
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www

# Copy application files
COPY . /var/www/

# Set proper permissions
RUN chown -R www-data:www-data /var/www

# Expose port 80 (nginx)
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1
