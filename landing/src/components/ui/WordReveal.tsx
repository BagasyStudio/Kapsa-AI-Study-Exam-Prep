"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/cn";

type WordRevealProps = {
  children: string;
  className?: string;
  renderWord?: (word: string, index: number) => React.ReactNode;
};

export function WordReveal({ children, className, renderWord }: WordRevealProps) {
  const words = children.split(" ");

  return (
    <motion.span
      initial="hidden"
      animate="visible"
      variants={{
        hidden: {},
        visible: { transition: { staggerChildren: 0.08 } },
      }}
      className={cn("inline", className)}
    >
      {words.map((word, i) => (
        <motion.span
          key={i}
          variants={{
            hidden: { opacity: 0, y: 20, filter: "blur(8px)" },
            visible: {
              opacity: 1,
              y: 0,
              filter: "blur(0px)",
              transition: { type: "spring", stiffness: 100, damping: 12 },
            },
          }}
          className="inline-block mr-[0.3em]"
        >
          {renderWord ? renderWord(word, i) : word}
        </motion.span>
      ))}
    </motion.span>
  );
}
