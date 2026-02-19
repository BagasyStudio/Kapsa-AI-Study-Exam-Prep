export const SITE = {
  name: "Kapsa",
  tagline: "AI Study Companion",
  description:
    "Turn your notes, PDFs, and lectures into flashcards, quizzes, and personalized study plans with AI.",
  url: "https://kapsa.app",
};

export const LINKS = {
  appStore: "https://apps.apple.com/app/kapsa-ai-study-exam-prep/id6746202763",
  github: "https://github.com/BagasyStudio/Kapsa-AI-Study-Exam-Prep",
  privacy: "/privacy",
  terms: "/terms",
  email: "support@kapsa.app",
};

export const FEATURES = [
  {
    id: "oracle",
    icon: "MessageSquare",
    title: "AI Oracle Chat",
    description:
      "Your personal AI tutor that answers questions, explains concepts, and helps you understand any topic in depth.",
    accent: "from-primary to-indigo-400",
  },
  {
    id: "capture",
    icon: "Camera",
    title: "Smart Capture",
    description:
      "Snap photos of textbooks, whiteboards, or handwritten notes. Our AI extracts and organizes the text instantly.",
    accent: "from-purple-500 to-violet-400",
  },
  {
    id: "flashcards",
    icon: "Layers",
    title: "AI Flashcards",
    description:
      "Automatically generate flashcards from your materials with spaced repetition to maximize retention.",
    accent: "from-indigo-500 to-blue-400",
  },
  {
    id: "tests",
    icon: "FileCheck",
    title: "Test Generation",
    description:
      "AI creates practice exams from your study materials so you can test yourself before the real thing.",
    accent: "from-emerald-500 to-teal-400",
  },
  {
    id: "courses",
    icon: "BookOpen",
    title: "Course Management",
    description:
      "Organize all your materials, notes, and resources by course. Everything in one place, always accessible.",
    accent: "from-blue-500 to-cyan-400",
  },
  {
    id: "streaks",
    icon: "Flame",
    title: "Streaks & Calendar",
    description:
      "Build consistent study habits with streak tracking, study calendar, and milestone celebrations.",
    accent: "from-amber-500 to-orange-400",
  },
];

export const STEPS = [
  {
    number: "01",
    title: "Capture Your Material",
    description:
      "Upload photos of your notes, import PDFs, or record audio from lectures. Kapsa accepts any study material you throw at it.",
    mockup: "/mockups/capture-screen.png",
  },
  {
    number: "02",
    title: "AI Does The Work",
    description:
      "Our AI instantly extracts text, generates flashcards, creates practice tests, and builds summaries — all automatically.",
    mockup: "/mockups/chat-screen.png",
  },
  {
    number: "03",
    title: "Study & Ace Your Exams",
    description:
      "Review with spaced repetition flashcards, take practice tests, track your progress, and watch your grades improve.",
    mockup: "/mockups/results-screen.png",
  },
];

export const PRICING = {
  free: {
    name: "Free",
    price: "$0",
    period: "",
    description: "Get started with the basics",
    features: [
      "Limited AI Oracle queries",
      "Basic flashcard generation",
      "1 active course",
      "Document capture",
      "Study streaks",
    ],
    cta: "Get Started",
    highlighted: false,
  },
  pro: {
    name: "Kapsa Pro",
    badge: "MOST POPULAR",
    monthly: { price: "$12.99", period: "/month" },
    yearly: {
      price: "$59.99",
      period: "/year",
      monthlyEquiv: "$5.00",
      savings: "62%",
    },
    description: "Everything you need to ace your exams",
    features: [
      "Unlimited AI Oracle Chat",
      "Instant Test Generation",
      "Smart Study Plans",
      "Advanced Analytics & Insights",
      "Unlimited courses",
      "Priority support",
    ],
    trialDays: 7,
    highlighted: true,
  },
};

export const TESTIMONIALS = [
  {
    name: "Sofia R.",
    role: "Medical Student",
    university: "Stanford University",
    quote:
      "Kapsa changed the way I study. My grades improved so much in just one month. The AI flashcards are incredible.",
    rating: 5,
  },
  {
    name: "James L.",
    role: "Engineering Student",
    university: "MIT",
    quote:
      "I used to spend hours making study materials. Now Kapsa does it in seconds. More time studying, less time organizing.",
    rating: 5,
  },
  {
    name: "Priya K.",
    role: "Law Student",
    university: "Oxford University",
    quote:
      "The test generation feature is a game changer. I feel so much more prepared for my exams. Highly recommend!",
    rating: 5,
  },
];

export const STATS = [
  { value: "50,000+", label: "Active Students" },
  { value: "40%", label: "Average Grade Improvement" },
  { value: "4.9", label: "App Store Rating" },
  { value: "1M+", label: "Flashcards Generated" },
];

export const NAV_LINKS = [
  { label: "Features", href: "#features" },
  { label: "How It Works", href: "#how-it-works" },
  { label: "Pricing", href: "#pricing" },
  { label: "Testimonials", href: "#testimonials" },
];
