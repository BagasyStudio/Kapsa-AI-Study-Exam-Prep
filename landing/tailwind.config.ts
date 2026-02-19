import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#6467F2",
          light: "#8A8CF7",
          dark: "#4F51C9",
        },
        background: {
          DEFAULT: "#101122",
          surface: "#2A2C4E",
          light: "#F6F6F8",
        },
        success: "#34C759",
        error: "#EF4444",
        warning: "#FFCC00",
      },
      fontFamily: {
        heading: ["var(--font-outfit)", "sans-serif"],
        body: ["var(--font-inter)", "sans-serif"],
      },
      borderRadius: {
        card: "28px",
        pill: "100px",
      },
      boxShadow: {
        glass: "0 8px 32px 0 rgba(100, 103, 242, 0.1)",
        glow: "0 0 20px rgba(100, 103, 242, 0.4)",
        "glow-lg": "0 0 40px rgba(100, 103, 242, 0.3)",
      },
      animation: {
        aurora: "aurora 15s ease infinite",
        "pulse-glow": "pulse-glow 3s ease-in-out infinite",
        float: "float 6s ease-in-out infinite",
        "float-delayed": "float 6s ease-in-out 2s infinite",
        "fade-in": "fadeIn 0.6s ease-out forwards",
        marquee: "marquee 30s linear infinite",
        "marquee-slow": "marquee 45s linear infinite",
      },
      keyframes: {
        aurora: {
          "0%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" },
          "100%": { backgroundPosition: "0% 50%" },
        },
        "pulse-glow": {
          "0%, 100%": { boxShadow: "0 0 15px rgba(100,103,242,0.3)" },
          "50%": { boxShadow: "0 0 30px rgba(100,103,242,0.6)" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-12px)" },
        },
        fadeIn: {
          "0%": { opacity: "0", transform: "translateY(20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        marquee: {
          "0%": { transform: "translateX(0)" },
          "100%": { transform: "translateX(-50%)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
