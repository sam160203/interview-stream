# Stage 1: Builder - Saari dependencies install aur project build karo
FROM node:18-alpine AS builder

WORKDIR /app

# Package files copy karna
COPY package.json package-lock.json ./
RUN npm install

# Bacha hua code copy karna
COPY . .

# FIX: Convex files generate karna zaroori hai!
RUN npx convex codegen

# Next.js project build karna
RUN npm run build

# Stage 2: Runner - Sirf zaroori files aur runtime environment
FROM node:18-alpine AS runner

# Node.js ki performance ke liye zaroori
ENV NODE_ENV=production
ENV PORT=3000

# Next.js standalone output use karna
WORKDIR /app
# 1. Standalone output copy karna (server files)
COPY --from=builder /app/.next/standalone ./

# 2. Static build assets copy karna (.js chunks, .css, fonts)
COPY --from=builder /app/.next/static ./public/_next/static 

# 3. Public assets folder copy karna
COPY --from=builder /app/public ./public

# 4. Node modules copy karna (standalone ke liye zaruri)
COPY --from=builder /app/node_modules ./node_modules

# Port expose karna jahan application sunegi
EXPOSE 3000

# FIX: Application start karne ka command 'server.js' se
CMD ["node", "server.js"]