FROM node:14

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY ./package*.json ./

# Install dependencies
RUN npm install

# Install nodemon globally
RUN npm install -g nodemon

# Copy all application files from the server directory
COPY . .

# Expose the server port
EXPOSE 5000

# Start the server with nodemon
CMD ["nodemon", "app.js"]
