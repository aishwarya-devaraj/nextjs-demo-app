# ============================================================
# next.config.js — Next.js configuration for CI/CD deployment
# Enables standalone output required for Docker multi-stage build
# ============================================================

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Required for Docker standalone deployment
  output: 'standalone',

  // Image optimization domains (add your CDN/asset domain)
  images: {
    domains: ['your-cdn.cloudfront.net'],
    formats: ['image/avif', 'image/webp'],
  },

  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options',           value: 'DENY' },
          { key: 'X-Content-Type-Options',     value: 'nosniff' },
          { key: 'Referrer-Policy',            value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy',         value: 'camera=(), microphone=(), geolocation=()' },
          { key: 'X-XSS-Protection',           value: '1; mode=block' },
        ],
      },
    ]
  },

  // Compress responses
  compress: true,

  // Disable powered-by header
  poweredByHeader: false,
}

module.exports = nextConfig
