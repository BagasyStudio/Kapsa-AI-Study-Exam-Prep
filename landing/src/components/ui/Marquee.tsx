"use client";

import { cn } from "@/lib/cn";

type MarqueeProps = {
  children: React.ReactNode;
  className?: string;
  speed?: "normal" | "slow";
  pauseOnHover?: boolean;
};

export function Marquee({
  children,
  className,
  speed = "normal",
  pauseOnHover = true,
}: MarqueeProps) {
  return (
    <div
      className={cn(
        "relative overflow-hidden",
        "[mask-image:linear-gradient(to_right,transparent,black_10%,black_90%,transparent)]",
        className
      )}
    >
      <div
        className={cn(
          "flex w-max gap-8",
          speed === "slow" ? "animate-marquee-slow" : "animate-marquee",
          pauseOnHover && "hover:[animation-play-state:paused]"
        )}
      >
        {/* Duplicate children for seamless loop */}
        {children}
        {children}
      </div>
    </div>
  );
}
