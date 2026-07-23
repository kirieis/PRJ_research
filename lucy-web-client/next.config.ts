import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  devIndicators: false,
  allowedDevOrigins: ['unplanked-inculpably-malorie.ngrok-free.dev'],
  async rewrites() {
    return [
      {
        source: "/api/v1/:path*",
        destination: "http://127.0.0.1:3001/api/v1/:path*",
      },
      {
        source: "/api/wallet/:path*",
        destination: "http://127.0.0.1:3001/api/wallet/:path*",
      },
      {
        source: "/api/agora/:path*",
        destination: "http://127.0.0.1:3001/api/agora/:path*",
      },
      {
        source: "/api/auth/me",
        destination: "http://127.0.0.1:3001/api/auth/me",
      },
      {
        source: "/api/auth/wallet/:path*",
        destination: "http://127.0.0.1:3001/api/auth/wallet/:path*",
      },
      {
        source: "/api/auth/sepay-webhook",
        destination: "http://127.0.0.1:3001/api/auth/sepay-webhook",
      },
      {
        source: "/socket.io/:path*",
        destination: "http://127.0.0.1:3001/socket.io/:path*",
      },
    ];
  },
};

export default nextConfig;

