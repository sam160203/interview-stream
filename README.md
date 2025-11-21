🚀 Interview Stream PlatformA secure, real-time online interview platform designed for conducting and managing technical interviews remotely. This application leverages a modern Next.js 14 stack for performance and a suite of real-time services for robust communication features.✨ 
Key Features
🎥 Real-Time Video & Audio: Instant, high-quality peer-to-peer video and audio conferencing powered by Stream.
🖥️ Screen Sharing: Allows candidates or interviewers to share their screens seamlessly for code review or collaborative problem-solving.
🎬 Interview Recording: Includes the capability for screen recording to capture interview sessions for later review and compliance.
🔒 Secure Authentication & Authorization: Robust user management, sign-up, and sign-in flows powered by Clerk.
💾 State Management: Real-time data and file storage managed efficiently by Convex.
🎨 Modern UI: A sleek, responsive user interface achieved with Tailwind CSS and the Shadcn UI component library.
⚙️ Tech Stack & Architecture
| Category | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | **Next.js & TypeScript** | Full-stack React framework utilizing Server Components for performance and type safety. |
| **Authentication** | **Clerk** | Secure user sign-up, sign-in, and authorization flows. |
| **Video/Streaming** | **Stream** | Handles complex real-time video, audio, and screen-sharing infrastructure. |
| **Database/Backend** | **Convex** | Real-time, file-storage, and transactional backend for application data. |
| **Styling** | **Tailwind CSS & Shadcn UI** | Utility-first CSS framework and customizable UI components. |
| **Server Logic** | **Server Actions** | Leverages the latest Next.js features for efficient server-side logic and data mutations. |
🚀 Getting Started
Follow these steps to set up and run the Interview Stream platform locally.
1. Prerequisites
   Ensure you have the following installed on your system:
   . Node.js (v18 or higher)
   . Git
2. Clone and Install Dependencies
   1. Clone the repository:
       Bash : git clone https://github.com/sam160203/interview-stream.git
   2. Navigate to the project directory:
       Bash : cd interview-stream
   3. Install dependencies (choose one):
       Bash npm install
       # or
      yarn install
      # or
      pnpm install
      # or
      bun install
3. Set Up Environment Variables
   🔑This project requires API keys and secrets from Clerk, Stream, and Convex to function.
   1. Create the local environment file: In the root of your project directory, create a new file named .env.
   2. Add required variables: Copy the structure below into your new .env file and replace the placeholder values (YOUR_..._KEY) with your actual keys.
       Note: These keys are private and must NEVER be committed to GitHub. The .gitignore file already ensures this security.
   Code snippet
   # --- CLERK AUTHENTICATION ---
   # Public key for Clerk (Client-side use)
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=YOUR_CLERK_PUBLISHABLE_KEY 
   # Secret key for Clerk (Server-side use)
   CLERK_SECRET_KEY=YOUR_CLERK_SECRET_KEY

   # --- STREAM VIDEO CALLS ---
   # Public key for Stream (Client-side use)
   NEXT_PUBLIC_STREAM_API_KEY=YOUR_STREAM_API_KEY
   # Secret key for Stream (Server-side use)
   STREAM_API_SECRET=YOUR_STREAM_API_SECRET

   # --- CONVEX DATABASE ---
   # Public URL for your Convex project (Client-side use)
   NEXT_PUBLIC_CONVEX_URL=YOUR_CONVEX_URL
4. Run the Development ServerOnce your environment variables are set up, you can start the application:Bashnpm run dev
   # or
   yarn dev
   # or
   pnpm dev
   # or
   bun dev

   The application will be accessible at http://localhost:3000.

💡 Contribution
   Feel free to open issues or submit pull requests. All contributions are welcome!
