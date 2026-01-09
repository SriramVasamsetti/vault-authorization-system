FROM node:18-alpine

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY . .

RUN npm run compile

EXPOSE 8545

CMD ["npm", "run", "deploy"]
