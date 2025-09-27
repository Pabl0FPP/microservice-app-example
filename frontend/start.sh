#!/bin/bash

# Replace environment variables in nginx.conf.template
envsubst '${AUTH_API_URL} ${TODOS_API_URL} ${USERS_API_URL} ${ZIPKIN_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Create config.js with the API URLs for client-side access
cat > /usr/share/nginx/html/config.js << EOF
window.CONFIG = {
  AUTH_API_URL: '${AUTH_API_URL}',
  TODOS_API_URL: '${TODOS_API_URL}',
  USERS_API_URL: '${USERS_API_URL}',
  ZIPKIN_URL: '${ZIPKIN_URL}'
};
EOF

# Start nginx
nginx -g 'daemon off;'