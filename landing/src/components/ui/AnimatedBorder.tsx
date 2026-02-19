"use client";

import { cn } from "@/lib/cn";

type AnimatedBorderProps = {
  children: React.ReactNode;
  className?: string;
};

export function AnimatedBorder({ children, className }: AnimatedBorderProps) {
  return (
    <div className={cn("relative rounded-2xl p-[1px]", className)}>
      {/* Rotating gradient border */}
      <div
        className="absolute inset-0 rounded-2xl overflow-hidden"
        aria-hidden
      >
        <div
          className="absolute inset-[-200%] animate-spin"
          style={{
            animationDuration: "4s",
            background:
              "conic-gradient(from 0deg, transparent 0%, transparent 30%, #6467F2 50%, transparent 70%, transparent 100%)",
          }}
        />
      </div>

      {/* Inner content with dark background */}
      <div className="relative rounded-2xl bg-background">
        {children}
      </div>
    </div>
  );
}
