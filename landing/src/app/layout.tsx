import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";

const inter = localFont({
  src: [
    { path: "../../public/fonts/Inter-Regular.ttf", weight: "400", style: "normal" },
    { path: "../../public/fonts/Inter-Medium.ttf", weight: "500", style: "normal" },
    { path: "../../public/fonts/Inter-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "../../public/fonts/Inter-Bold.ttf", weight: "700", style: "normal" },
  ],
  variable: "--font-inter",
  display: "swap",
});

const outfit = localFont({
  src: [
    { path: "../../public/fonts/Outfit-Medium.ttf", weight: "500", style: "normal" },
    { path: "../../public/fonts/Outfit-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "../../public/fonts/Outfit-Bold.ttf", weight: "700", style: "normal" },
  ],
  variable: "--font-outfit",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://kapsa.app"),
  title: {
    default: "Kapsa — AI Study Companion",
    template: "%s | Kapsa",
  },
  description:
    "Turn your notes, PDFs, and lectures into flashcards, quizzes, and personalized study plans with AI. Join 50,000+ students studying smarter.",
  keywords: [
    "AI study app",
    "flashcards",
    "quiz generator",
    "study companion",
    "exam prep",
    "AI tutor",
    "spaced repetition",
  ],
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://kapsa.app",
    siteName: "Kapsa",
    title: "Kapsa — AI Study Companion",
    description:
      "Turn your notes into flashcards, quizzes, and study plans with AI.",
    images: [{ url: "/og-image.png", width: 1200, height: 630 }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Kapsa — AI Study Companion",
    description:
      "Study smarter with AI-powered flashcards, quizzes, and study plans.",
    images: ["/og-image.png"],
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} ${outfit.variable}`}>
      <body className="antialiased">
        <Navbar />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
