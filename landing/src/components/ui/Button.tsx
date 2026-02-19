"use client";

import { cn } from "@/lib/cn";

type ButtonProps = {
  variant?: "primary" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  children: React.ReactNode;
  className?: string;
  href?: string;
  onClick?: () => void;
};

export function Button({
  variant = "primary",
  size = "md",
  children,
  className,
  href,
  onClick,
}: ButtonProps) {
  const base =
    "inline-flex items-center justify-center gap-2 font-body font-semibold rounded-full transition-all duration-200 active:scale-[0.97]";

  const variants = {
    primary:
      "bg-gradient-to-r from-primary to-indigo-700 text-white shadow-glow hover:shadow-glow-lg hover:brightness-110",
    secondary:
      "glass-panel text-white hover:bg-white/10",
    ghost:
      "text-white/60 hover:text-white",
  };

  const sizes = {
    sm: "px-4 py-2 text-sm",
    md: "px-6 py-3 text-base",
    lg: "px-8 py-4 text-lg",
  };

  const classes = cn(base, variants[variant], sizes[size], className);

  if (href) {
    return (
      <a href={href} className={classes} target={href.startsWith("http") ? "_blank" : undefined} rel={href.startsWith("http") ? "noopener noreferrer" : undefined}>
        {children}
      </a>
    );
  }

  return (
    <button onClick={onClick} className={classes}>
      {children}
    </button>
  );
}
