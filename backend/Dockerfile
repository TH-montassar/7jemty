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


# Build the TypeScript code (Only in production)
RUN npm run build;

# Copy the generated Prisma client to the dist directory (Only in production)
RUN  cp -r generated dist/generated;
# Expose the API port (defaulting to 3000, adjust if your server uses a different port)
EXPOSE 8080
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Run the development server
CMD ["sh", "/entrypoint.sh"]