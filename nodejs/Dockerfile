FROM node:14

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY ./server/package*.json ./

# Install dependencies including nodemon
RUN npm install
RUN npm install -g nodemon

# Copy all files into the image
COPY ./server/ .

EXPOSE 5000

# Use nodemon to run the app
CMD ["npx", "nodemon", "index.js"]  # nodemon ile uygulamayı başlatın
