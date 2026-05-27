FROM node:20-alpine
WORKDIR /app
COPY server/package*.json ./
RUN npm ci
COPY server/ . .
EXPOSE 3000
CMD ["npx", "tsx", "src/index.ts"]
