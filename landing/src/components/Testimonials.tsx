"use client";

import { useEffect, useRef, useState } from "react";
import { TESTIMONIALS, STATS } from "@/lib/constants";
import { GlassCard } from "@/components/ui/GlassCard";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import { SectionHeading } from "@/components/ui/SectionHeading";

export function Testimonials() {
  return (
    <section id="testimonials" className="relative py-24 sm:py-32 bg-immersive noise-overlay">
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <SectionHeading
            badge="Testimonials"
            title="Students Love Kapsa"
            subtitle="Join thousands of students who are already studying smarter."
          />
        </ScrollReveal>

        {/* Stats row */}
        <ScrollReveal>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6 mb-16">
            {STATS.map((stat) => (
              <div key={stat.label} className="text-center">
                <AnimatedValue value={stat.value} />
                <p className="mt-1 text-sm text-white/40">{stat.label}</p>
              </div>
            ))}
          </div>
        </ScrollReveal>

        {/* Testimonial cards */}
        <div className="grid md:grid-cols-3 gap-6">
          {TESTIMONIALS.map((t, i) => (
            <ScrollReveal key={t.name} delay={i * 0.1}>
              <GlassCard className="p-6 h-full flex flex-col">
                {/* Stars */}
                <div className="flex gap-1 mb-4">
                  {Array.from({ length: t.rating }).map((_, j) => (
                    <svg key={j} width="16" height="16" viewBox="0 0 24 24" fill="#FFCC00">
                      <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 16.8l-6.2 4.5 2.4-7.4L2 9.4h7.6z" />
                    </svg>
                  ))}
                </div>

                <p className="text-sm text-white/60 leading-relaxed flex-1">
                  &ldquo;{t.quote}&rdquo;
                </p>

                <div className="mt-6 flex items-center gap-3">
                  {/* Avatar placeholder */}
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-indigo-400 flex items-center justify-center text-white font-bold text-sm">
                    {t.name[0]}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-white">{t.name}</p>
                    <p className="text-xs text-white/40">
                      {t.role} · {t.university}
                    </p>
                  </div>
                </div>
              </GlassCard>
            </ScrollReveal>
          ))}
        </div>

        {/* University trust line */}
        <ScrollReveal>
          <p className="mt-12 text-center text-sm text-white/25 tracking-widest uppercase">
            Used by students at Stanford, MIT, and Oxford
          </p>
        </ScrollReveal>
      </div>
    </section>
  );
}

function AnimatedValue({ value }: { value: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const [display, setDisplay] = useState("0");
  const [started, setStarted] = useState(false);

  useEffect(() => {
    if (!ref.current) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started) {
          setStarted(true);
          animateValue();
        }
      },
      { threshold: 0.5 }
    );
    observer.observe(ref.current);
    return () => observer.disconnect();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [started]);

  function animateValue() {
    const numericPart = value.replace(/[^0-9.]/g, "");
    const target = parseFloat(numericPart);
    const suffix = value.replace(numericPart, "");
    const isDecimal = numericPart.includes(".");
    const duration = 1500;
    const start = performance.now();

    function tick(now: number) {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = target * eased;

      if (isDecimal) {
        setDisplay(current.toFixed(1) + suffix);
      } else {
        setDisplay(Math.round(current).toLocaleString() + suffix);
      }

      if (progress < 1) requestAnimationFrame(tick);
    }

    requestAnimationFrame(tick);
  }

  return (
    <div ref={ref} className="font-heading text-3xl sm:text-4xl font-bold text-white">
      {display}
    </div>
  );
}
