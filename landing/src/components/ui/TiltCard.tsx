"use client";

import { useRef, useState, useCallback } from "react";
import { cn } from "@/lib/cn";

type TiltCardProps = {
  children: React.ReactNode;
  className?: string;
  glowColor?: string;
};

export function TiltCard({
  children,
  className,
  glowColor = "rgba(100, 103, 242, 0.15)",
}: TiltCardProps) {
  const cardRef = useRef<HTMLDivElement>(null);
  const [transform, setTransform] = useState("");
  const [glowPos, setGlowPos] = useState({ x: 50, y: 50 });
  const [isHovered, setIsHovered] = useState(false);

  const handleMouseMove = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (!cardRef.current) return;
      const rect = cardRef.current.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      const rotateX = ((y - centerY) / centerY) * -4;
      const rotateY = ((x - centerX) / centerX) * 4;

      setTransform(
        `perspective(800px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`
      );
      setGlowPos({
        x: (x / rect.width) * 100,
        y: (y / rect.height) * 100,
      });
    },
    []
  );

  const handleMouseLeave = useCallback(() => {
    setTransform("");
    setIsHovered(false);
  }, []);

  const handleMouseEnter = useCallback(() => {
    setIsHovered(true);
  }, []);

  return (
    <div
      ref={cardRef}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      onMouseEnter={handleMouseEnter}
      className={cn(
        "relative rounded-2xl transition-[box-shadow] duration-300",
        className
      )}
      style={{
        transform: transform || undefined,
        transition: isHovered
          ? "box-shadow 0.3s ease"
          : "transform 0.4s ease, box-shadow 0.3s ease",
      }}
    >
      {/* Glow border overlay */}
      {isHovered && (
        <div
          className="pointer-events-none absolute inset-0 rounded-2xl z-10 opacity-100 transition-opacity duration-300"
          style={{
            background: `radial-gradient(400px circle at ${glowPos.x}% ${glowPos.y}%, ${glowColor}, transparent 70%)`,
            mask: "linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)",
            maskComposite: "exclude",
            WebkitMaskComposite: "xor",
            padding: "1px",
          }}
        />
      )}
      {children}
    </div>
  );
}
