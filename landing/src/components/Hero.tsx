"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform } from "framer-motion";
import { Button } from "@/components/ui/Button";
import { PhoneMockup } from "@/components/ui/PhoneMockup";
import { FloatingOrbs } from "@/components/ui/FloatingOrbs";
import { WordReveal } from "@/components/ui/WordReveal";
import { Marquee } from "@/components/ui/Marquee";
import { LINKS } from "@/lib/constants";

const UNIVERSITIES = [
  "Stanford", "MIT", "Oxford", "Harvard", "Cambridge",
  "Yale", "Princeton", "Columbia", "Berkeley", "UCLA",
];

export function Hero() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start start", "end start"],
  });

  const phoneY = useTransform(scrollYProgress, [0, 1], [0, 100]);
  const textY = useTransform(scrollYProgress, [0, 1], [0, 40]);
  const orbsY = useTransform(scrollYProgress, [0, 1], [0, -60]);

  return (
    <section
      ref={sectionRef}
      className="relative min-h-screen flex items-center overflow-hidden pt-24 pb-16"
    >
      <motion.div style={{ y: orbsY }} className="absolute inset-0">
        <FloatingOrbs />
      </motion.div>
      <div className="bg-ethereal absolute inset-0" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 w-full">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-8 items-center">
          <motion.div style={{ y: textY }}>
            <motion.span
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ type: "spring", stiffness: 100, damping: 15 }}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-sm font-medium bg-primary/10 text-primary-light border border-primary/20 mb-6"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 16.8l-6.2 4.5 2.4-7.4L2 9.4h7.6z" />
              </svg>
              AI-Powered Study Companion
            </motion.span>

            <h1 className="font-heading text-4xl sm:text-5xl lg:text-6xl font-bold leading-[1.1] tracking-tight">
              <WordReveal
                renderWord={(word) =>
                  word === "Smarter," ? (
                    <span className="text-gradient">{word}</span>
                  ) : (
                    word
                  )
                }
              >
                Study Smarter, Not Harder
              </WordReveal>
            </h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6, duration: 0.6 }}
              className="mt-6 text-lg sm:text-xl text-white/50 max-w-lg leading-relaxed"
            >
              Turn your notes, PDFs, and lectures into flashcards, quizzes, and
              personalized study plans — all powered by AI.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8, duration: 0.5 }}
              className="mt-8 flex flex-col sm:flex-row gap-4"
            >
              <Button href={LINKS.appStore} size="lg" className="animate-pulse-glow">
                <AppleIcon />
                Download on the App Store
              </Button>
              <Button href="#how-it-works" variant="secondary" size="lg">
                See How It Works
              </Button>
            </motion.div>

            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1, duration: 0.8 }}
              className="mt-10"
            >
              <p className="text-xs text-white/25 uppercase tracking-widest mb-3">
                Trusted by students at
              </p>
              <Marquee speed="slow" className="max-w-md">
                {UNIVERSITIES.map((uni) => (
                  <span key={uni} className="text-sm font-medium text-white/30 whitespace-nowrap">
                    {uni}
                  </span>
                ))}
              </Marquee>
            </motion.div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.9, delay: 0.3, type: "spring", stiffness: 80 }}
            style={{ y: phoneY }}
            className="flex justify-center lg:justify-end"
          >
            <div className="animate-float">
              <PhoneMockup src="/mockups/home-screen.png" alt="Kapsa app home screen" priority />
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
