"use client";

import { STEPS } from "@/lib/constants";
import { PhoneMockup } from "@/components/ui/PhoneMockup";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import { SectionHeading } from "@/components/ui/SectionHeading";

export function HowItWorks() {
  return (
    <section id="how-it-works" className="relative py-24 sm:py-32 bg-immersive noise-overlay">
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <SectionHeading
            badge="How It Works"
            title="Three Steps to Better Grades"
            subtitle="Getting started with Kapsa takes less than a minute."
          />
        </ScrollReveal>

        <div className="space-y-24 lg:space-y-32">
          {STEPS.map((step, i) => {
            const reversed = i % 2 === 1;
            return (
              <div
                key={step.number}
                className={`flex flex-col ${reversed ? "lg:flex-row-reverse" : "lg:flex-row"} items-center gap-12 lg:gap-20`}
              >
                {/* Text */}
                <ScrollReveal
                  direction={reversed ? "right" : "left"}
                  className="flex-1"
                >
                  <div className="max-w-md">
                    <span className="font-heading text-6xl font-bold text-gradient opacity-50">
                      {step.number}
                    </span>
                    <h3 className="mt-2 font-heading text-2xl sm:text-3xl font-bold text-white">
                      {step.title}
                    </h3>
                    <p className="mt-4 text-lg text-white/45 leading-relaxed">
                      {step.description}
                    </p>
                  </div>
                </ScrollReveal>

                {/* Phone mockup */}
                <ScrollReveal
                  direction={reversed ? "left" : "right"}
                  delay={0.15}
                  className="flex-1 flex justify-center"
                >
                  <PhoneMockup src={step.mockup} alt={step.title} />
                </ScrollReveal>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
