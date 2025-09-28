# build stage
FROM node:8.15.0-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# production stage
FROM nginx:1.13.12-alpine as production-stage

# Copy built application
COPY --from=build-stage /app/dist /usr/share/nginx/html

# ✅ USAR archivo estático en lugar de template
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]