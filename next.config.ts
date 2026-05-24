import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      // Serve the full Nova site at root without changing the URL
      { source: '/', destination: '/nova-site.html' },
    ]
  },
}

export default nextConfig;
