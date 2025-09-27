# build stage
FROM node:8.15.0-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# production stage
FROM nginx:1.13.12-alpine as production-stage

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Copy built application
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Copy nginx template
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Create startup script directly in Dockerfile
RUN cat > /start.sh << 'EOF'
#!/bin/sh
set -e

# Replace environment variables in nginx.conf.template
envsubst '${AUTH_API_URL} ${TODOS_API_URL} ${USERS_API_URL} ${ZIPKIN_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Create config.js with the API URLs for client-side access
cat > /usr/share/nginx/html/config.js << 'INNER_EOF'
window.CONFIG = {
  AUTH_API_URL: '${AUTH_API_URL}',
  TODOS_API_URL: '${TODOS_API_URL}',
  USERS_API_URL: '${USERS_API_URL}',
  ZIPKIN_URL: '${ZIPKIN_URL}'
};
INNER_EOF

# Start nginx
exec nginx -g 'daemon off;'
EOF
RUN sed -i 's/\r$//' /start.sh  && \  
        chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]