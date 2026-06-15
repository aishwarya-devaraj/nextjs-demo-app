// ============================================================
// app/api/health/route.ts
// Health check endpoint — App Router version
// Used by Jenkins smoke test: GET /api/health → 200 OK
// ============================================================

import { NextResponse } from 'next/server'

export async function GET() {
  const health = {
    status:      'healthy',
    timestamp:   new Date().toISOString(),
    version:     process.env.npm_package_version ?? '1.0.0',
    commit:      process.env.GIT_COMMIT          ?? 'unknown',
    uptime:      process.uptime(),
    environment: process.env.NODE_ENV            ?? 'development',
    memory: {
      rss:       process.memoryUsage().rss,
      heapUsed:  process.memoryUsage().heapUsed,
      heapTotal: process.memoryUsage().heapTotal,
    },
  }

  return NextResponse.json(health, { status: 200 })
}
