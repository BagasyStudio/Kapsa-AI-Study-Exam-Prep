import { Button } from "@/components/ui/Button";

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="text-center">
        <h1 className="font-heading text-6xl font-bold text-gradient mb-4">404</h1>
        <p className="text-xl text-white/50 mb-8">Page not found</p>
        <Button href="/">Go Home</Button>
      </div>
    </div>
  );
}
