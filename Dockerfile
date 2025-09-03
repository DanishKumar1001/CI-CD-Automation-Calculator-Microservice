FROM node:20-alpine AS base # Base image
WORKDIR /usr/src/app # Sets Work Direcctory inside container
COPY package*.json ./ # Copy dependencies
RUN npm ci --only=production #  Install only production dependencies


FROM node:20-alpine 
WORKDIR /usr/src/app
COPY --from=base /usr/src/app/node_modules ./node_modules # Copy dependencies to base image
COPY calculator.js ./ # Copy app source 
COPY logs ./logs
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000 
CMD ["node", "calculator.js"] # Start Service
