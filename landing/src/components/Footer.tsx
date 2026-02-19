import Image from "next/image";
import { LINKS, SITE } from "@/lib/constants";

export function Footer() {
  return (
    <footer className="border-t border-white/5 bg-[#0B0D1E]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-2 gap-8 sm:grid-cols-4">
          {/* Brand */}
          <div className="col-span-2 sm:col-span-1">
            <a href="/" className="flex items-center gap-2.5 mb-4">
              <Image src="/icon.png" alt="Kapsa" width={32} height={32} className="rounded-xl" />
              <span className="font-heading text-lg font-bold text-white">Kapsa</span>
            </a>
            <p className="text-sm text-white/40 max-w-[240px]">
              {SITE.description.slice(0, 80)}...
            </p>
          </div>

          {/* Product */}
          <div>
            <h3 className="font-heading font-semibold text-white mb-4 text-sm">Product</h3>
            <ul className="space-y-3">
              <li><a href="#features" className="text-sm text-white/40 hover:text-white/70 transition-colors">Features</a></li>
              <li><a href="#pricing" className="text-sm text-white/40 hover:text-white/70 transition-colors">Pricing</a></li>
              <li><a href={LINKS.appStore} className="text-sm text-white/40 hover:text-white/70 transition-colors" target="_blank" rel="noopener noreferrer">Download</a></li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h3 className="font-heading font-semibold text-white mb-4 text-sm">Legal</h3>
            <ul className="space-y-3">
              <li><a href={LINKS.privacy} className="text-sm text-white/40 hover:text-white/70 transition-colors">Privacy Policy</a></li>
              <li><a href={LINKS.terms} className="text-sm text-white/40 hover:text-white/70 transition-colors">Terms of Service</a></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="font-heading font-semibold text-white mb-4 text-sm">Support</h3>
            <ul className="space-y-3">
              <li><a href={`mailto:${LINKS.email}`} className="text-sm text-white/40 hover:text-white/70 transition-colors">Contact</a></li>
              <li><a href={LINKS.github} className="text-sm text-white/40 hover:text-white/70 transition-colors" target="_blank" rel="noopener noreferrer">GitHub</a></li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-12 pt-8 border-t border-white/5 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-white/30">
            &copy; {new Date().getFullYear()} Kapsa. All rights reserved.
          </p>
          <p className="text-sm text-white/20">
            Made with ♥ for students everywhere
          </p>
        </div>
      </div>
    </footer>
  );
}
