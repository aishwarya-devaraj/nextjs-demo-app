# ============================================================
# Dockerfile for Next.js Application (Single-stage optimized)
# ============================================================

FROM node:20-alpine
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Copy pre-built standalone application and assets from the host
COPY .next/standalone ./
COPY .next/static ./.next/static
COPY public ./public

EXPOSE 3000

CMD ["node", "server.js"]
