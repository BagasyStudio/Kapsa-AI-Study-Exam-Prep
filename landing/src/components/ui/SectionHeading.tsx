import { cn } from "@/lib/cn";

type SectionHeadingProps = {
  badge?: string;
  title: string;
  subtitle?: string;
  className?: string;
  align?: "center" | "left";
};

export function SectionHeading({
  badge,
  title,
  subtitle,
  className,
  align = "center",
}: SectionHeadingProps) {
  return (
    <div className={cn("mb-16", align === "center" && "text-center", className)}>
      {badge && (
        <span className="inline-block mb-4 px-4 py-1.5 rounded-full text-sm font-medium bg-primary/10 text-primary-light border border-primary/20">
          {badge}
        </span>
      )}
      <h2 className="font-heading text-3xl sm:text-4xl lg:text-5xl font-bold text-white tracking-tight">
        {title}
      </h2>
      {subtitle && (
        <p className="mt-4 text-lg text-white/50 max-w-2xl mx-auto">
          {subtitle}
        </p>
      )}
    </div>
  );
}
