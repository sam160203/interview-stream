/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', 
  // FIX: Explicitly set assetPrefix to root (or empty string) for Docker consistency
  assetPrefix: '', // This tells Next.js to load assets from the root path
};

export default nextConfig;