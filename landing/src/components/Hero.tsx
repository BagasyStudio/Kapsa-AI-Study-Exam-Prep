"use client";

import { motion } from "framer-motion";
import { Button } from "@/components/ui/Button";
import { PhoneMockup } from "@/components/ui/PhoneMockup";
import { FloatingOrbs } from "@/components/ui/FloatingOrbs";
import { LINKS } from "@/lib/constants";

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center overflow-hidden pt-24 pb-16">
      <FloatingOrbs />
      <div className="bg-ethereal absolute inset-0" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 w-full">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-8 items-center">
          {/* Text column */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, ease: "easeOut" }}
          >
            {/* Badge */}
            <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-sm font-medium bg-primary/10 text-primary-light border border-primary/20 mb-6">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 16.8l-6.2 4.5 2.4-7.4L2 9.4h7.6z" />
              </svg>
              AI-Powered Study Companion
            </span>

            <h1 className="font-heading text-4xl sm:text-5xl lg:text-6xl font-bold leading-[1.1] tracking-tight">
              Study{" "}
              <span className="text-gradient">Smarter</span>,
              <br />
              Not Harder
            </h1>

            <p className="mt-6 text-lg sm:text-xl text-white/50 max-w-lg leading-relaxed">
              Turn your notes, PDFs, and lectures into flashcards, quizzes, and
              personalized study plans — all powered by AI.
            </p>

            {/* CTAs */}
            <div className="mt-8 flex flex-col sm:flex-row gap-4">
              <Button href={LINKS.appStore} size="lg" className="animate-pulse-glow">
                <AppleIcon />
                Download on the App Store
              </Button>
              <Button href="#how-it-works" variant="secondary" size="lg">
                See How It Works
              </Button>
            </div>

            {/* Trust */}
            <div className="mt-8 flex items-center gap-2 text-sm text-white/30">
              <span>Join 50,000+ students from</span>
              <span className="font-medium text-white/40">Stanford</span>
              <span>·</span>
              <span className="font-medium text-white/40">MIT</span>
              <span>·</span>
              <span className="font-medium text-white/40">Oxford</span>
            </div>
          </motion.div>

          {/* Phone mockup column */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2, ease: "easeOut" }}
            className="flex justify-center lg:justify-end"
          >
            <div className="animate-float">
              <PhoneMockup
                src="/mockups/home-screen.png"
                alt="Kapsa app home screen"
                priority
              />
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function AppleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    </svg>
  );
}
