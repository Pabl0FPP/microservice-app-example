FROM node:8.17.0-buster

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 8082

ENV TODO_API_PORT=8082
ENV JWT_SECRET=foo
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel

CMD ["npm", "start"]
