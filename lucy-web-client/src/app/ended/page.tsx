"use client";
/* eslint-disable */

import React from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Play, House } from "@phosphor-icons/react";

export default function EndedPage() {
  const router = useRouter();
  const [activeLang, setActiveLang] = React.useState("en");

  React.useEffect(() => {
    const saved = localStorage.getItem("activeLang");
    if (saved) {
      setActiveLang(saved);
    }
  }, []);

  return (
    <div className={`flex-1 flex flex-col items-center justify-center bg-[var(--bg)] min-h-screen text-center px-6 theme-${activeLang || 'en'}`}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
        className="ended-wrapper max-w-[500px]"
      >
        <h1 className="hero-title text-6xl md:text-[88px] font-black leading-[0.8] tracking-tighter mb-4 text-[var(--text-main)]">
          SESSION
          <br />
          <span className="hero-accent bg-gradient-to-r from-[var(--cyan)] to-[var(--magenta)] bg-clip-text text-transparent">
            TERMINATED.
          </span>
        </h1>
        
        <p className="text-[var(--text-muted)] text-sm md:text-base max-w-[340px] mx-auto mt-6 leading-relaxed">
          Your language practice session has safely concluded. Your progress has been logged.
        </p>

        {/* Mock Stats */}
        <div className="stats-row flex justify-center gap-16 md:gap-24 my-16 md:my-20">
          <div className="stat-box text-center">
            <div className="val text-7xl md:text-[88px] font-black leading-none tracking-tighter text-[var(--magenta)] mb-2">
              10
            </div>
            <div className="lbl font-mono text-[11px] text-[var(--text-muted)] tracking-widest uppercase">
              Minutes
            </div>
          </div>
          <div className="stat-box text-center">
            <div className="val text-7xl md:text-[88px] font-black leading-none tracking-tighter text-[var(--cyan)] mb-2">
              4
            </div>
            <div className="lbl font-mono text-[11px] text-[var(--text-muted)] tracking-widest uppercase">
              Topics
            </div>
          </div>
        </div>

        <div className="ended-actions flex gap-4 justify-center">
          <button
            onClick={() => router.push("/room/101")}
            className="btn-primary flex items-center gap-2"
          >
            <Play size={14} weight="fill" />
            NEW SESSION
          </button>
          <button
            onClick={() => router.push("/")}
            className="btn-ghost flex items-center gap-2"
          >
            <House size={14} />
            LOBBY
          </button>
        </div>
      </motion.div>
    </div>
  );
}
