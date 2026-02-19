import { cn } from "@/lib/cn";

type FloatingOrbsProps = {
  className?: string;
};

export function FloatingOrbs({ className }: FloatingOrbsProps) {
  return (
    <div className={cn("pointer-events-none absolute inset-0 overflow-hidden", className)} aria-hidden>
      {/* Indigo orb — top left */}
      <div className="absolute -top-32 -left-32 h-[500px] w-[500px] rounded-full bg-primary/20 blur-[120px] animate-pulse" style={{ animationDuration: "8s" }} />
      {/* Purple orb — center right */}
      <div className="absolute top-1/3 -right-24 h-[400px] w-[400px] rounded-full bg-purple-600/15 blur-[100px] animate-pulse" style={{ animationDuration: "10s" }} />
      {/* Blue orb — bottom left */}
      <div className="absolute -bottom-32 left-1/4 h-[450px] w-[450px] rounded-full bg-indigo-500/15 blur-[110px] animate-pulse" style={{ animationDuration: "12s" }} />
    </div>
  );
}
