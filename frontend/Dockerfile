# Build stage
FROM node:8.17-buster AS builder

# Set working directory
WORKDIR /app

#==========================dependences management=============================#
# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

#==========================Build=============================#
# Copy source code
COPY . .

# Build the application
RUN npm run build

#==========================Production=============================#
# Production stage
FROM nginx:stable-alpine

# Copy built application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]