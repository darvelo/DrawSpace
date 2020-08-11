FROM node:12

WORKDIR /srv/app

COPY . .

RUN npm install

EXPOSE 8080

ENTRYPOINT ["npm", "start"]
