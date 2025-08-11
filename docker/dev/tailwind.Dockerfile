FROM node:24-slim

ENV APP_HOME="/code"
WORKDIR ${APP_HOME}

COPY package.json package.json
COPY package-lock.json package-lock.json

RUN npm ci

CMD ["npm", "run", "tailwind:watch"]