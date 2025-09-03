# Use  Node.js 
FROM node:20

# Set working directory inside the container
WORKDIR /usr/src/app

# Copy package files 
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy the rest of the app code
COPY . .

# Expose application port
EXPOSE 3000

# Start the application
CMD ["node", "calculator.js"]
