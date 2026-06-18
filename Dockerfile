# Stage-1: Building the application
FROM node:18-alpine AS builder

# Setting up the work directory 
WORKDIR /app

# Install necessary build dependencies
RUN apk add --no-cache python3 make g++

# Copying the dependencies
COPY package*.json ./

# Installing the dependencies
RUN npm ci

# Copy all the project files
COPY . .

# Building the application
RUN npm run build


# Stage-2: Running the application
FROM node:18-alpine AS runner

# Setting up the work directory
WORKDIR /app

# Copying files from the builder stage
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Setting up the env variables
ENV NODE_ENV=production
ENV PORT=3000

# Exposing the port
EXPOSE 3000

# Starting the application 
CMD ["node" , "server.js"]




