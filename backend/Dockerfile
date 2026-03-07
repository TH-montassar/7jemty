FROM node:20

WORKDIR /app

# Copy package.json and package-lock.json first to cache dependencies
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Expose the API port (defaulting to 3000, adjust if your server uses a different port)
EXPOSE 3000

# Run the development server
CMD ["/entrypoint.sh"]