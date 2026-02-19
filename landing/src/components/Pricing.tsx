"use client";

import { useState } from "react";
import { cn } from "@/lib/cn";
import { PRICING, LINKS } from "@/lib/constants";
import { GlassCard } from "@/components/ui/GlassCard";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import { SectionHeading } from "@/components/ui/SectionHeading";
import { Button } from "@/components/ui/Button";

export function Pricing() {
  const [yearly, setYearly] = useState(true);
  const pro = PRICING.pro;
  const currentPro = yearly ? pro.yearly : pro.monthly;

  return (
    <section id="pricing" className="relative py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <SectionHeading
            badge="Pricing"
            title="Simple, Transparent Pricing"
            subtitle="Start free, upgrade when you're ready. Cancel anytime."
          />
        </ScrollReveal>

        {/* Billing toggle */}
        <ScrollReveal>
          <div className="flex items-center justify-center gap-3 mb-12">
            <span className={cn("text-sm", !yearly ? "text-white" : "text-white/40")}>
              Monthly
            </span>
            <button
              onClick={() => setYearly(!yearly)}
              className={cn(
                "relative w-14 h-7 rounded-full transition-colors duration-300",
                yearly ? "bg-primary" : "bg-white/20"
              )}
            >
              <span
                className={cn(
                  "absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform duration-300",
                  yearly ? "translate-x-7" : "translate-x-0.5"
                )}
              />
            </button>
            <span className={cn("text-sm", yearly ? "text-white" : "text-white/40")}>
              Yearly
            </span>
            {yearly && (
              <span className="ml-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                Save {pro.yearly.savings}
              </span>
            )}
          </div>
        </ScrollReveal>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {/* Free tier */}
          <ScrollReveal delay={0}>
            <GlassCard className="p-8 h-full flex flex-col">
              <h3 className="font-heading text-xl font-bold text-white">
                {PRICING.free.name}
              </h3>
              <p className="mt-1 text-sm text-white/40">{PRICING.free.description}</p>
              <div className="mt-6">
                <span className="font-heading text-4xl font-bold text-white">{PRICING.free.price}</span>
              </div>

              <ul className="mt-8 space-y-3 flex-1">
                {PRICING.free.features.map((f) => (
                  <li key={f} className="flex items-start gap-3 text-sm text-white/60">
                    <CheckIcon className="mt-0.5 shrink-0 text-white/30" />
                    {f}
                  </li>
                ))}
              </ul>

              <Button href={LINKS.appStore} variant="secondary" className="w-full mt-8">
                {PRICING.free.cta}
              </Button>
            </GlassCard>
          </ScrollReveal>

          {/* Pro tier */}
          <ScrollReveal delay={0.1}>
            <div className="relative">
              {/* Badge */}
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 z-10">
                <span className="px-4 py-1 rounded-full text-xs font-bold bg-primary text-white shadow-glow">
                  {pro.badge}
                </span>
              </div>

              <GlassCard
                variant="panel"
                className="p-8 h-full flex flex-col border-primary/30 ring-1 ring-primary/20"
              >
                <h3 className="font-heading text-xl font-bold text-white">
                  {pro.name}
                </h3>
                <p className="mt-1 text-sm text-white/40">{pro.description}</p>
                <div className="mt-6 flex items-baseline gap-2">
                  <span className="font-heading text-4xl font-bold text-white">
                    {yearly ? pro.yearly.monthlyEquiv : currentPro.price.replace("/month", "")}
                  </span>
                  <span className="text-white/40 text-sm">/month</span>
                </div>
                {yearly && (
                  <p className="mt-1 text-xs text-white/30">
                    Billed {pro.yearly.price}{pro.yearly.period}
                  </p>
                )}

                <ul className="mt-8 space-y-3 flex-1">
                  {pro.features.map((f) => (
                    <li key={f} className="flex items-start gap-3 text-sm text-white/70">
                      <CheckIcon className="mt-0.5 shrink-0 text-primary-light" />
                      {f}
                    </li>
                  ))}
                </ul>

                <Button href={LINKS.appStore} className="w-full mt-8 animate-pulse-glow">
                  Start {pro.trialDays}-Day Free Trial
                </Button>

                <p className="mt-3 text-center text-xs text-white/30">
                  Cancel anytime. No questions asked.
                </p>

                {/* Trust badges */}
                <div className="mt-4 flex items-center justify-center gap-4 text-xs text-white/25">
                  <span className="flex items-center gap-1">
                    <LockIcon /> Secure
                  </span>
                  <span className="flex items-center gap-1">
                    <ShieldIcon /> Encrypted
                  </span>
                  <span className="flex items-center gap-1">
                    <StarIcon /> Trusted
                  </span>
                </div>
              </GlassCard>
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  );
}

function CheckIcon({ className }: { className?: string }) {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

function LockIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
      <path d="M7 11V7a5 5 0 0110 0v4" />
    </svg>
  );
}

function ShieldIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}

function StarIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 16.8l-6.2 4.5 2.4-7.4L2 9.4h7.6z" />
    </svg>
  );
}
