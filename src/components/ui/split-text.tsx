// FILE: src/components/ui/split-text.tsx
"use client";

import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ElementType,
} from "react";
import { cn } from "@/lib/utils";

interface SplitTextProps {
  text: string;
  className?: string;
  delay?: number;
  duration?: number;
  tag?: "h1" | "h2" | "h3" | "p" | "span";
  textAlign?: CSSProperties["textAlign"];
}

export function SplitText({
  text,
  className,
  delay = 36,
  duration = 700,
  tag = "p",
  textAlign = "left",
}: SplitTextProps) {
  const ref = useRef<HTMLElement | null>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (!ref.current) {
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          observer.disconnect();
        }
      },
      {
        threshold: 0.18,
        rootMargin: "-40px",
      },
    );

    observer.observe(ref.current);

    return () => observer.disconnect();
  }, []);

  const Tag = tag as ElementType;

  // Pre-compute per-character global index so delays are consistent
  const chars: { char: string; globalIndex: number }[] = [];
  text.split("").forEach((char, i) => chars.push({ char, globalIndex: i }));

  // Group into words so line breaks only happen at word boundaries
  const words: { chars: typeof chars }[] = [];
  let current: typeof chars = [];
  for (const item of chars) {
    if (item.char === " ") {
      if (current.length) {
        words.push({ chars: current });
        current = [];
      }
      words.push({ chars: [item] }); // space as its own "word"
    } else {
      current.push(item);
    }
  }
  if (current.length) words.push({ chars: current });

  return (
    <Tag
      ref={ref}
      className={cn("overflow-hidden whitespace-normal", className)}
      style={{ textAlign }}
    >
      {words.map((word, wordIndex) => {
        const isSpace = word.chars.length === 1 && word.chars[0].char === " ";

        if (isSpace) {
          const { globalIndex } = word.chars[0];
          return (
            <span
              key={`space-${globalIndex}`}
              aria-hidden="true"
              className="inline-block will-change-transform will-change-opacity"
              style={{
                transitionProperty: "transform, opacity",
                transitionDuration: `${duration}ms`,
                transitionTimingFunction: "cubic-bezier(0.22, 1, 0.36, 1)",
                transitionDelay: `${globalIndex * delay}ms`,
                transform: visible ? "translateY(0px)" : "translateY(24px)",
                opacity: visible ? 1 : 0,
              }}
            >
              {"\u00A0"}
            </span>
          );
        }

        return (
          <span key={`word-${wordIndex}`} className="inline-block whitespace-nowrap">
            {word.chars.map(({ char, globalIndex }) => (
              <span
                key={`${char}-${globalIndex}`}
                aria-hidden="true"
                className="inline-block will-change-transform will-change-opacity"
                style={{
                  transitionProperty: "transform, opacity",
                  transitionDuration: `${duration}ms`,
                  transitionTimingFunction: "cubic-bezier(0.22, 1, 0.36, 1)",
                  transitionDelay: `${globalIndex * delay}ms`,
                  transform: visible ? "translateY(0px)" : "translateY(24px)",
                  opacity: visible ? 1 : 0,
                }}
              >
                {char}
              </span>
            ))}
          </span>
        );
      })}
      <span className="sr-only">{text}</span>
    </Tag>
  );
}
