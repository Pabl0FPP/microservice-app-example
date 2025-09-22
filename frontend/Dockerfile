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

# Copy nginx template and startup script
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh

# Make startup script executable
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]