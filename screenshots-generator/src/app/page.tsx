"use client";

import React, { useRef, useState, useCallback } from "react";
import { toPng } from "html-to-image";

// ─── Design Constants ────────────────────────────────────────────────
const W = 1320;
const H = 2868;

const SIZES = [
  { label: '6.5" (Required)', w: 1242, h: 2688 },
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.7"', w: 1290, h: 2796 },
  { label: '6.1"', w: 1179, h: 2556 },
] as const;

const PURPLE = "#8B5CF6";
const PURPLE_MID = "#6366F1";

// ─── Phone Mockup ───────────────────────────────────────────────────
const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

function Phone({ src, alt, style }: { src: string; alt: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: `${MK_W}/${MK_H}`, ...style }}>
      <img src="/mockup.png" alt="" draggable={false} style={{ display: "block", width: "100%", height: "100%" }} />
      <div style={{ position: "absolute", zIndex: 10, overflow: "hidden", left: `${SC_L}%`, top: `${SC_T}%`, width: `${SC_W}%`, height: `${SC_H}%`, borderRadius: `${SC_RX}% / ${SC_RY}%` }}>
        <img src={src} alt={alt} draggable={false} style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} />
      </div>
    </div>
  );
}

// ─── Reusable Primitives ─────────────────────────────────────────────

/** Full-slide container */
function SlideBase({ children, bg }: { children: React.ReactNode; bg?: string }) {
  return (
    <div style={{
      width: W, height: H,
      background: bg || `linear-gradient(170deg, #060818 0%, #0A0E2A 40%, #1A1040 100%)`,
      position: "relative", overflow: "hidden", fontFamily: "Inter, sans-serif",
    }}>
      {children}
    </div>
  );
}

/** Soft colored orb for background depth */
function Orb({ size, color, top, left, right, bottom }: { size: number; color: string; top?: string | number; left?: string | number; right?: string | number; bottom?: string | number }) {
  return <div style={{ position: "absolute", width: size, height: size, borderRadius: "50%", background: `radial-gradient(circle, ${color}, transparent 70%)`, pointerEvents: "none", top, left, right, bottom, opacity: 0.9 }} />;
}

/** Purple highlight text */
function HL({ children }: { children: React.ReactNode }) {
  return <span style={{ color: PURPLE }}>{children}</span>;
}

/** Massive headline — must be readable at thumbnail */
const HS: React.CSSProperties = {
  fontSize: W * 0.108,
  fontWeight: 800,
  color: "white",
  lineHeight: 1.05,
  letterSpacing: "-0.025em",
  whiteSpace: "pre-line",
  textAlign: "center",
  padding: `0 ${W * 0.05}px`,
};

/** White floating badge — big and readable */
function Badge({ emoji, text, style }: { emoji: string; text: string; style?: React.CSSProperties }) {
  return (
    <div style={{
      position: "absolute",
      background: "rgba(255,255,255,0.97)",
      borderRadius: W * 0.02,
      padding: `${W * 0.02}px ${W * 0.035}px`,
      display: "flex", alignItems: "center", gap: W * 0.015,
      boxShadow: "0 14px 50px rgba(0,0,0,0.4)",
      zIndex: 20,
      ...style,
    }}>
      <span style={{ fontSize: W * 0.04 }}>{emoji}</span>
      <span style={{ fontSize: W * 0.032, fontWeight: 700, color: "#111" }}>{text}</span>
    </div>
  );
}

// ─── Hero Card for Slide 1 ──────────────────────────────────────────
function HeroCard({ icon, iconBg, label, style }: { icon: string; iconBg: string; label: string; style?: React.CSSProperties }) {
  const cw = (style?.width as number) || W * 0.26;
  return (
    <div style={{
      position: "absolute",
      width: cw,
      height: cw * 1.08,
      borderRadius: W * 0.035,
      background: "linear-gradient(180deg, #ffffff 0%, #f4f4f6 100%)",
      boxShadow: `0 ${W * 0.005}px 0 0 #d4d4d8, 0 ${W * 0.01}px 0 0 #e4e4e7, 0 ${W * 0.025}px ${W * 0.05}px rgba(0,0,0,0.3)`,
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: W * 0.022,
      zIndex: 15,
      ...style,
    }}>
      <div style={{
        width: cw * 0.38, height: cw * 0.38,
        borderRadius: cw * 0.12,
        background: iconBg,
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: cw * 0.24,
        boxShadow: `0 6px 18px rgba(0,0,0,0.15)`,
      }}>
        {icon}
      </div>
      <span style={{ fontSize: W * 0.032, fontWeight: 700, color: "#1e1e3a", textAlign: "center" }}>{label}</span>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 1: HERO — Feature overview, no phone
// Big headline + rating + 3x2 grid of feature cards
// ═══════════════════════════════════════════════════════════════════════
function Slide1Hero() {
  const cardW = W * 0.26;
  const gap = W * 0.035;
  const gridW = cardW * 3 + gap * 2;
  const gridLeft = (W - gridW) / 2;
  const row1Y = H * 0.29;
  const row2Y = row1Y + cardW * 1.08 + gap;

  const cards = [
    { icon: "\u26A1", bg: "linear-gradient(135deg, #A78BFA, #7C3AED)", label: "Flashcards" },
    { icon: "\uD83D\uDCCB", bg: "linear-gradient(135deg, #60A5FA, #3B82F6)", label: "Quizzes" },
    { icon: "\uD83D\uDCD6", bg: "linear-gradient(135deg, #5EEAD4, #14B8A6)", label: "Summaries" },
    { icon: "\uD83D\uDCF8", bg: "linear-gradient(135deg, #FDBA74, #F97316)", label: "Snap & Solve" },
    { icon: "\uD83E\uDDE0", bg: "linear-gradient(135deg, #F9A8D4, #EC4899)", label: "AI Tutor" },
    { icon: "\uD83C\uDFA7", bg: "linear-gradient(135deg, #86EFAC, #22C55E)", label: "Audio Notes" },
  ];

  return (
    <SlideBase bg="linear-gradient(175deg, #060818 0%, #0A0E2A 35%, #1A1040 100%)">
      <Orb size={W * 1.0} color="rgba(99,102,241,0.1)" top="-15%" right="-30%" />
      <Orb size={W * 0.5} color="rgba(139,92,246,0.08)" bottom="20%" left="-20%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.04, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Study smarter,\nace "}<HL>every exam</HL></div>
      </div>

      {/* Rating badge */}
      <div style={{
        position: "absolute", top: H * 0.185, left: "50%", transform: "translateX(-50%)",
        display: "flex", alignItems: "center", gap: W * 0.02, zIndex: 20,
      }}>
        <div style={{
          width: W * 0.13, height: W * 0.13, borderRadius: "50%",
          border: `${W * 0.005}px solid #EAB308`,
          boxShadow: `0 0 ${W * 0.02}px rgba(234,179,8,0.3)`,
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        }}>
          <div style={{ fontSize: W * 0.05, fontWeight: 900, color: "white", lineHeight: 1 }}>4.8</div>
          <div style={{ fontSize: W * 0.018, color: "#FACC15", letterSpacing: 1, marginTop: 2 }}>★★★★★</div>
        </div>
        <div>
          <div style={{ fontSize: W * 0.026, fontWeight: 700, color: "white" }}>Trusted by</div>
          <div style={{ fontSize: W * 0.03, fontWeight: 800, color: "#FACC15" }}>10K+ students</div>
        </div>
      </div>

      {/* 3x2 Feature card grid */}
      {cards.map((card, i) => {
        const col = i % 3;
        const row = Math.floor(i / 3);
        return (
          <HeroCard
            key={i}
            icon={card.icon}
            iconBg={card.bg}
            label={card.label}
            style={{
              top: row === 0 ? row1Y : row2Y,
              left: gridLeft + col * (cardW + gap),
              width: cardW,
            }}
          />
        );
      })}

      {/* Bottom tagline */}
      <div style={{ position: "absolute", bottom: H * 0.06, left: 0, right: 0, textAlign: "center", zIndex: 15 }}>
        <div style={{ fontSize: W * 0.03, fontWeight: 500, color: "rgba(255,255,255,0.4)", letterSpacing: "0.02em" }}>
          Everything you need to study better
        </div>
      </div>
    </SlideBase>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 2: SNAP & SOLVE — "Snap a photo, AI does the rest"
// Centered phone, clean layout
// ═══════════════════════════════════════════════════════════════════════
function Slide2SnapSolve() {
  return (
    <SlideBase bg="linear-gradient(170deg, #1A1040 0%, #0A0E2A 50%, #060818 100%)">
      <Orb size={W * 0.7} color="rgba(249,115,22,0.08)" top="10%" left="-20%" />
      <Orb size={W * 0.5} color="rgba(139,92,246,0.1)" bottom="25%" right="-15%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.045, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Snap a photo,\n"}<HL>AI does the rest</HL></div>
      </div>

      {/* Badge */}
      <Badge emoji="✨" text="Instant solutions" style={{ top: H * 0.21, left: "50%", transform: "translateX(-50%)" }} />

      {/* Phone glow */}
      <div style={{ position: "absolute", bottom: H * 0.18, left: "50%", transform: "translateX(-50%)", width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "radial-gradient(circle, rgba(249,115,22,0.08), transparent 65%)", pointerEvents: "none", zIndex: 5 }} />

      {/* Phone — fully visible, centered */}
      <div style={{ position: "absolute", bottom: H * 0.02, left: "50%", transform: "translateX(-50%)", width: W * 0.72, zIndex: 10 }}>
        <Phone src="/screenshots/capture.jpg" alt="Snap & Solve" />
      </div>
    </SlideBase>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 3: NOTES → STUDY MATERIAL
// Centered phone showing study tools
// ═══════════════════════════════════════════════════════════════════════
function Slide3NotesToMaterial() {
  return (
    <SlideBase bg="linear-gradient(175deg, #060818 0%, #0D0A25 40%, #1A1040 100%)">
      <Orb size={W * 0.8} color="rgba(99,102,241,0.1)" top="0%" right="-25%" />
      <Orb size={W * 0.4} color="rgba(6,182,212,0.07)" bottom="30%" left="-15%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.045, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Your notes become\n"}<HL>study material</HL></div>
      </div>

      {/* Badge */}
      <Badge emoji="✨" text="AI generates everything" style={{ top: H * 0.21, left: "50%", transform: "translateX(-50%)" }} />

      {/* Phone glow */}
      <div style={{ position: "absolute", bottom: H * 0.18, left: "50%", transform: "translateX(-50%)", width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "radial-gradient(circle, rgba(99,102,241,0.1), transparent 65%)", pointerEvents: "none", zIndex: 5 }} />

      {/* Phone — fully visible */}
      <div style={{ position: "absolute", bottom: H * 0.02, left: "50%", transform: "translateX(-50%)", width: W * 0.72, zIndex: 10 }}>
        <Phone src="/screenshots/study-tools.jpg" alt="Study Tools" />
      </div>
    </SlideBase>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 4: NEVER FORGET — Spaced repetition flashcards
// Centered phone + retention badge
// ═══════════════════════════════════════════════════════════════════════
function Slide4NeverForget() {
  return (
    <SlideBase bg="linear-gradient(180deg, #0A0E2A 0%, #0F0A30 50%, #1A1040 100%)">
      <Orb size={W * 0.7} color="rgba(16,185,129,0.08)" top="10%" right="-20%" />
      <Orb size={W * 0.5} color="rgba(99,102,241,0.08)" bottom="25%" left="-18%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.045, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Never "}<HL>forget</HL>{"\nwhat you learn"}</div>
      </div>

      {/* Retention badge */}
      <Badge emoji="\uD83D\uDCC8" text="92% retention rate" style={{ top: H * 0.21, left: "50%", transform: "translateX(-50%)" }} />

      {/* Phone glow */}
      <div style={{ position: "absolute", bottom: H * 0.18, left: "50%", transform: "translateX(-50%)", width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "radial-gradient(circle, rgba(16,185,129,0.08), transparent 65%)", pointerEvents: "none", zIndex: 5 }} />

      {/* Phone */}
      <div style={{ position: "absolute", bottom: H * 0.02, left: "50%", transform: "translateX(-50%)", width: W * 0.72, zIndex: 10 }}>
        <Phone src="/screenshots/flashcards.jpg" alt="Flashcards" />
      </div>
    </SlideBase>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 5: AI TUTOR — "Your personal AI tutor"
// Phone slightly right, text left-aligned for variety
// ═══════════════════════════════════════════════════════════════════════
function Slide5Oracle() {
  return (
    <SlideBase bg="linear-gradient(170deg, #060818 0%, #0A0E2A 40%, #1A1040 100%)">
      <Orb size={W * 0.6} color="rgba(139,92,246,0.12)" top="8%" left="-15%" />
      <Orb size={W * 0.4} color="rgba(34,211,238,0.06)" bottom="30%" right="-10%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.045, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Your personal\n"}<HL>AI tutor</HL></div>
      </div>

      {/* Badge */}
      <Badge emoji="\uD83D\uDCA1" text="Explains anything" style={{ top: H * 0.21, left: "50%", transform: "translateX(-50%)" }} />

      {/* Phone glow */}
      <div style={{ position: "absolute", bottom: H * 0.18, left: "50%", transform: "translateX(-50%)", width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.1), transparent 65%)", pointerEvents: "none", zIndex: 5 }} />

      {/* Phone */}
      <div style={{ position: "absolute", bottom: H * 0.02, left: "50%", transform: "translateX(-50%)", width: W * 0.72, zIndex: 10 }}>
        <Phone src="/screenshots/oracle.jpg" alt="AI Tutor" />
      </div>
    </SlideBase>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 6: SMART QUIZZES — "Test yourself with AI quizzes"
// Centered phone + score badge
// ═══════════════════════════════════════════════════════════════════════
function Slide6Quizzes() {
  return (
    <SlideBase bg="linear-gradient(180deg, #0D0B28 0%, #0A0E2A 40%, #1A1040 100%)">
      <Orb size={W * 0.7} color="rgba(99,102,241,0.1)" top="5%" right="-20%" />
      <Orb size={W * 0.4} color="rgba(16,185,129,0.06)" bottom="30%" left="-15%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.045, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Test yourself\nwith "}<HL>AI quizzes</HL></div>
      </div>

      {/* Score badge */}
      <Badge emoji="✓" text="9/10 correct" style={{ top: H * 0.21, left: "50%", transform: "translateX(-50%)" }} />

      {/* Phone glow */}
      <div style={{ position: "absolute", bottom: H * 0.18, left: "50%", transform: "translateX(-50%)", width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "radial-gradient(circle, rgba(99,102,241,0.08), transparent 65%)", pointerEvents: "none", zIndex: 5 }} />

      {/* Phone */}
      <div style={{ position: "absolute", bottom: H * 0.02, left: "50%", transform: "translateX(-50%)", width: W * 0.72, zIndex: 10 }}>
        <Phone src="/screenshots/quiz.jpg" alt="Smart Quizzes" />
      </div>
    </SlideBase>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SLIDE 7: MASTER ANYTHING — CTA / closing slide
// Centered phone showing home + CTA button
// ═══════════════════════════════════════════════════════════════════════
function Slide7Master() {
  return (
    <SlideBase bg="linear-gradient(180deg, #060818 0%, #1A1040 50%, #060818 100%)">
      <Orb size={W * 0.6} color="rgba(139,92,246,0.08)" top="15%" left="-15%" />
      <Orb size={W * 0.5} color="rgba(34,211,238,0.05)" bottom="20%" right="-20%" />

      {/* Headline */}
      <div style={{ position: "absolute", top: H * 0.045, left: 0, right: 0, zIndex: 15 }}>
        <div style={HS}>{"Master "}<HL>anything,</HL>{"\nfaster"}</div>
      </div>

      {/* Phone glow */}
      <div style={{ position: "absolute", bottom: H * 0.18, left: "50%", transform: "translateX(-50%)", width: W * 0.95, height: W * 0.95, borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.1), transparent 65%)", pointerEvents: "none", zIndex: 5 }} />

      {/* Phone */}
      <div style={{ position: "absolute", bottom: H * 0.06, left: "50%", transform: "translateX(-50%)", width: W * 0.72, zIndex: 10 }}>
        <Phone src="/screenshots/home.jpg" alt="Home" />
      </div>

      {/* CTA button at very bottom */}
      <div style={{
        position: "absolute", bottom: H * 0.02, left: "50%", transform: "translateX(-50%)",
        background: `linear-gradient(135deg, ${PURPLE_MID}, ${PURPLE})`,
        borderRadius: W * 0.05,
        padding: `${W * 0.025}px ${W * 0.07}px`,
        fontSize: W * 0.035, fontWeight: 700, color: "white",
        boxShadow: "0 8px 32px rgba(139,92,246,0.5)",
        whiteSpace: "nowrap", zIndex: 15,
      }}>
        Start learning for free
      </div>
    </SlideBase>
  );
}

// ─── Registry ────────────────────────────────────────────────────────
const SCREENSHOTS = [
  { id: "01-hero", label: "Hero", Component: Slide1Hero },
  { id: "02-snap-solve", label: "Snap & Solve", Component: Slide2SnapSolve },
  { id: "03-notes-material", label: "Notes to Material", Component: Slide3NotesToMaterial },
  { id: "04-never-forget", label: "Never Forget", Component: Slide4NeverForget },
  { id: "05-ai-tutor", label: "AI Tutor", Component: Slide5Oracle },
  { id: "06-quizzes", label: "Smart Quizzes", Component: Slide6Quizzes },
  { id: "07-master", label: "Master Anything", Component: Slide7Master },
];

// ─── Preview ─────────────────────────────────────────────────────────
function ScreenshotPreview({ id, label, Component }: { id: string; label: string; Component: React.FC }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.2);

  React.useEffect(() => {
    if (!containerRef.current?.parentElement) return;
    const obs = new ResizeObserver((e) => setScale(e[0].contentRect.width / W));
    obs.observe(containerRef.current.parentElement);
    return () => obs.disconnect();
  }, []);

  return (
    <div>
      <div style={{ width: W * scale, height: H * scale, overflow: "hidden", borderRadius: 12, border: "1px solid rgba(255,255,255,0.1)" }}>
        <div ref={containerRef} style={{ transform: `scale(${scale})`, transformOrigin: "top left", width: W, height: H }}>
          <Component />
        </div>
      </div>
      <div style={{ textAlign: "center", marginTop: 8, color: "#aaa", fontSize: 13, fontWeight: 600 }}>
        #{id.split("-")[0]} {label}
      </div>
    </div>
  );
}

// ─── Main Page ───────────────────────────────────────────────────────
export default function ScreenshotsPage() {
  const offRefs = useRef<Map<string, HTMLDivElement>>(new Map());
  const [exporting, setExporting] = useState(false);
  const [progress, setProgress] = useState("");
  const [sizeIdx, setSizeIdx] = useState(0);

  const toPngWithTimeout = useCallback((el: HTMLElement, opts: object, ms = 10000): Promise<string> => {
    return Promise.race([
      toPng(el, opts),
      new Promise<string>((_, rej) => setTimeout(() => rej(new Error("TIMEOUT")), ms)),
    ]);
  }, []);

  const exportOne = useCallback(async (id: string, tw: number, th: number) => {
    const el = offRefs.current.get(id);
    if (!el) return;
    console.log(`[Export] Starting: ${id}`);
    el.style.left = "0px"; el.style.opacity = "1"; el.style.zIndex = "-1";
    const imgs = el.querySelectorAll("img");
    await Promise.all(Array.from(imgs).map(img =>
      img.complete ? Promise.resolve() : new Promise(r => { img.onload = r; img.onerror = r; })
    ));
    await new Promise(r => setTimeout(r, 300));
    const opts = { width: W, height: H, pixelRatio: 1 };
    try {
      console.log(`[Export] Warmup: ${id}`);
      await toPngWithTimeout(el, opts, 8000);
    } catch (e) {
      console.warn(`[Export] Warmup failed for ${id}:`, (e as Error).message);
    }
    let dataUrl: string;
    try {
      console.log(`[Export] Capture: ${id}`);
      dataUrl = await toPngWithTimeout(el, opts, 8000);
      console.log(`[Export] Success: ${id} (${dataUrl.length} bytes)`);
    } catch (e) {
      console.error(`[Export] FAILED: ${id}`, (e as Error).message);
      el.style.left = "-9999px"; el.style.opacity = ""; el.style.zIndex = "";
      return;
    }
    el.style.left = "-9999px"; el.style.opacity = ""; el.style.zIndex = "";
    if (tw !== W || th !== H) {
      const img = new Image(); img.src = dataUrl;
      await new Promise((r) => (img.onload = r));
      const c = document.createElement("canvas"); c.width = tw; c.height = th;
      c.getContext("2d")!.drawImage(img, 0, 0, tw, th);
      return c.toDataURL("image/png");
    }
    return dataUrl;
  }, [toPngWithTimeout]);

  const exportAll = useCallback(async () => {
    setExporting(true);
    const s = SIZES[sizeIdx];
    for (let i = 0; i < SCREENSHOTS.length; i++) {
      const ss = SCREENSHOTS[i];
      setProgress(`${i + 1}/${SCREENSHOTS.length}: ${ss.label}`);
      const url = await exportOne(ss.id, s.w, s.h);
      if (url) {
        const a = document.createElement("a");
        a.download = `${String(i + 1).padStart(2, "0")}-${ss.id.split("-").slice(1).join("-")}-${s.w}x${s.h}.png`;
        a.href = url; a.click();
      }
      await new Promise((r) => setTimeout(r, 300));
    }
    setExporting(false); setProgress("");
  }, [sizeIdx, exportOne]);

  const exportSingle = useCallback(async (id: string) => {
    setExporting(true);
    const s = SIZES[sizeIdx];
    setProgress("Exporting...");
    const url = await exportOne(id, s.w, s.h);
    if (url) {
      const a = document.createElement("a");
      a.download = `${id}-${s.w}x${s.h}.png`;
      a.href = url; a.click();
    }
    setExporting(false); setProgress("");
  }, [sizeIdx, exportOne]);

  return (
    <div style={{ minHeight: "100vh", background: "#0a0a0a", color: "white", padding: 32 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 32, flexWrap: "wrap" }}>
        <h1 style={{ fontSize: 24, fontWeight: 700 }}>Kapsa — App Store Screenshots</h1>
        <select value={sizeIdx} onChange={(e) => setSizeIdx(Number(e.target.value))} style={{ background: "#1a1a2e", color: "white", border: "1px solid #333", padding: "8px 16px", borderRadius: 8, fontSize: 14 }}>
          {SIZES.map((s, i) => <option key={i} value={i}>{s.label} ({s.w}x{s.h})</option>)}
        </select>
        <button onClick={exportAll} disabled={exporting} style={{ background: exporting ? "#555" : PURPLE, color: "white", border: "none", padding: "10px 24px", borderRadius: 8, fontSize: 14, fontWeight: 700, cursor: exporting ? "not-allowed" : "pointer" }}>
          {exporting ? progress : "Export All PNGs"}
        </button>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 24 }}>
        {SCREENSHOTS.map(({ id, label, Component }) => (
          <div key={id} style={{ cursor: "pointer" }} onClick={() => exportSingle(id)} title={`Click to export ${label}`}>
            <ScreenshotPreview id={id} label={label} Component={Component} />
          </div>
        ))}
      </div>
      {SCREENSHOTS.map(({ id, Component }) => (
        <div key={`off-${id}`} ref={(el) => { if (el) offRefs.current.set(id, el); }} style={{ position: "absolute", left: "-9999px", width: W, height: H, fontFamily: "Inter, sans-serif" }}>
          <Component />
        </div>
      ))}
    </div>
  );
}
