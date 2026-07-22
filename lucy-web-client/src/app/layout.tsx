import type { Metadata } from "next";
import { Outfit, Be_Vietnam_Pro, JetBrains_Mono, Instrument_Serif, Shippori_Mincho, Noto_Serif_SC } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["300", "400", "600", "800", "900"],
});

const beVietnam = Be_Vietnam_Pro({
  variable: "--font-body",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["400", "700"],
});

const instrumentSerif = Instrument_Serif({
  variable: "--font-instrument",
  subsets: ["latin"],
  weight: ["400"],
  style: ["normal", "italic"]
});

const shipporiMincho = Shippori_Mincho({
  variable: "--font-shippori",
  subsets: ["latin"],
  weight: ["400", "700"],
});

const notoSerifSC = Noto_Serif_SC({
  variable: "--font-noto",
  subsets: ["latin"],
  weight: ["400", "700"],
});

export const metadata: Metadata = {
  title: "LUCY - Premium Multilingual Audio Space",
  description: "Anonymous, high-fidelity language practice rooms. Speak without fear in English, Japanese, and Chinese.",
};

import RealtimeCallModal from "@/components/RealtimeCallModal";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${outfit.variable} ${beVietnam.variable} ${jetbrainsMono.variable} ${instrumentSerif.variable} ${shipporiMincho.variable} ${notoSerifSC.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col overflow-x-hidden bg-[var(--bg)] text-[var(--text-main)]">
        {/* Floating background mesh gradients for Cyberpunk vibe */}
        <div className="glow-blob blob-1"></div>
        <div className="glow-blob blob-2"></div>
        <div className="glow-blob blob-3"></div>

        {children}

        {/* Global Real-time 1-on-1 Call & Webhook Deposit Notification Listener */}
        <RealtimeCallModal />
      </body>
    </html>
  );
}
