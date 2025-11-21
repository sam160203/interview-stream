/** @type {import('next').NextConfig} */
const nextConfig = {
  // FIX: Docker build ke liye 'standalone' output mode enable kiya gaya hai
  output: 'standalone', 
};

export default nextConfig;