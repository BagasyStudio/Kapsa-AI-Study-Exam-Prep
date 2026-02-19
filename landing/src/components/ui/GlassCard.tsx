import { cn } from "@/lib/cn";

type GlassCardProps = {
  variant?: "card" | "panel";
  children: React.ReactNode;
  className?: string;
};

export function GlassCard({
  variant = "card",
  children,
  className,
}: GlassCardProps) {
  return (
    <div
      className={cn(
        "rounded-2xl",
        variant === "panel" ? "glass-panel" : "glass-card",
        className
      )}
    >
      {children}
    </div>
  );
}
