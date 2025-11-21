# Stage 1: Builder - Saari dependencies install aur project build karo
FROM node:18-alpine AS builder

# Working directory set karna
WORKDIR /app

# Package files copy karna
COPY package.json package-lock.json ./

# Dependencies install karna (yarn ya npm jo bhi aap use karte hain)
RUN npm install

# Bacha hua code copy karna
COPY . .

# FIX: Convex files generate karein taaki TypeScript build ho sake
RUN npx convex codegen

# Next.js project build karna
RUN npm run build

# Stage 2: Runner - Sirf zaroori files aur runtime environment
FROM node:18-alpine AS runner

# Node.js ki performance ke liye zaroori
ENV NODE_ENV=production

# Next.js standalone output use karna
# Yeh zaroori hai agar aap next.config.js mein output: 'standalone' set karte hain
WORKDIR /app
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next/standalone ./

# Port expose karna jahan application sunegi
EXPOSE 3000

# Application start karne ka command
CMD ["node", "server.js"]