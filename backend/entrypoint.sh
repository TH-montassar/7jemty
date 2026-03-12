#!/bin/sh
echo "📦 Installing dependencies..."
npm install

echo "⚙️ Generating Prisma client..."
npx prisma generate

echo "🗄️ Running migrations..."
npx prisma migrate deploy

echo "🚀 Starting PRODUCTION server..."
exec npm run start:prod