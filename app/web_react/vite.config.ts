import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/api/nanoclaw/analyze": {
        target: "http://100.109.47.20:8000",
        changeOrigin: true,
        rewrite: () => "/analyze",
      },
      "/api/nanoclaw/health": {
        target: "http://100.109.47.20:8000",
        changeOrigin: true,
        rewrite: () => "/health",
      },
    },
  },
});
