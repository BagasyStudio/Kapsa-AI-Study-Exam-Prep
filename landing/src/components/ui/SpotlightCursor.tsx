"use client";

import { useEffect, useState } from "react";

export function SpotlightCursor() {
  const [position, setPosition] = useState({ x: -1000, y: -1000 });
  const [isDesktop, setIsDesktop] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(min-width: 768px) and (pointer: fine)");
    setIsDesktop(mq.matches);

    const onChange = (e: MediaQueryListEvent) => setIsDesktop(e.matches);
    mq.addEventListener("change", onChange);

    const onMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener("mousemove", onMouseMove, { passive: true });

    return () => {
      mq.removeEventListener("change", onChange);
      window.removeEventListener("mousemove", onMouseMove);
    };
  }, []);

  if (!isDesktop) return null;

  return (
    <div
      className="pointer-events-none fixed inset-0 z-30 transition-opacity duration-300"
      style={{
        background: `radial-gradient(600px at ${position.x}px ${position.y}px, rgba(100, 103, 242, 0.06), transparent 80%)`,
      }}
      aria-hidden
    />
  );
}
