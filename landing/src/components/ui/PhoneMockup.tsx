import Image from "next/image";
import { cn } from "@/lib/cn";

type PhoneMockupProps = {
  src: string;
  alt: string;
  className?: string;
  priority?: boolean;
};

export function PhoneMockup({ src, alt, className, priority }: PhoneMockupProps) {
  return (
    <div
      className={cn(
        "relative mx-auto w-[260px] sm:w-[280px] lg:w-[300px]",
        className
      )}
    >
      {/* Phone frame */}
      <div className="relative rounded-[40px] border-[3px] border-white/10 bg-black/40 p-2 shadow-2xl shadow-primary/10">
        {/* Notch */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[28px] bg-black rounded-b-2xl z-10" />
        {/* Screen */}
        <div className="relative rounded-[34px] overflow-hidden aspect-[9/19.5]">
          <Image
            src={src}
            alt={alt}
            fill
            className="object-cover"
            sizes="300px"
            priority={priority}
          />
        </div>
      </div>
    </div>
  );
}
