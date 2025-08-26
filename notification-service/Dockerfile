FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache curl
COPY package.json package-lock.json* ./
RUN npm install --only=production || npm install --production=false
COPY src/ ./src/
EXPOSE 3000
CMD ["node", "src/index.js"]
