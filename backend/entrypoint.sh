#!/bin/sh
echo "📦 Installing dependencies..."
npm install

echo "⚙️ Generating Prisma client..."
npx prisma generate

echo "🗄️ Running migrations..."
npx prisma migrate deploy

if [ "$NODE_ENV" = "production" ]; then
    echo "🚀 Starting PRODUCTION server..."
    exec npm run start:prod
else
    echo "🚀 Starting DEV server..."
    exec npm run dev
fi