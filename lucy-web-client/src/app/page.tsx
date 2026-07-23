"use client";
/* eslint-disable */

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { MagnifyingGlass, Globe, ChatCircleText, Wallet } from "@phosphor-icons/react";
import { useRouter } from "next/navigation";

// Mock Fallback Data (Multilingual EN, JA, ZH but keep copy in English)
const getLocalizedRooms = (lang: string) => {
  return [
    {
      id: 101,
      name: "Morning Conversation",
      level: "B1",
      lang: "en",
      users: 0,
      status: "LIVE",
      desc: "Practice reflexes with everyday topics. Focus on fluency and natural speech.",
      image: "https://picsum.photos/seed/morning-studio/600/400"
    },
    {
      id: 102,
      name: "Beginner Talk (日本語)",
      level: "N5",
      lang: "ja",
      users: 0,
      status: "LIVE",
      desc: "For absolute beginners learning Japanese. Slow-paced basic greetings.",
      image: "https://picsum.photos/seed/kyoto-garden/600/400"
    },
    {
      id: 103,
      name: "Advanced Discussion (中文)",
      level: "HSK 4",
      lang: "zh",
      users: 0,
      status: "SCHEDULED",
      desc: "Deep discussions on Chinese news and culture. Starts at 14:00.",
      image: "https://picsum.photos/seed/forbidden-city/600/400"
    },
    {
      id: 104,
      name: "Daily Vocabulary (English)",
      level: "A2",
      lang: "en",
      users: 0,
      status: "LIVE",
      desc: "Learn essential vocabulary through real-life situations with flashcards.",
      image: "https://picsum.photos/seed/minimal-library/600/400"
    },
    {
      id: 105,
      name: "IELTS Speaking Club",
      level: "B2",
      lang: "en",
      users: 0,
      status: "ENDED",
      desc: "Practice IELTS Parts 2 & 3 with an AI examiner. Session completed.",
      image: "https://picsum.photos/seed/oxford-exam/600/400"
    }
  ];
};

const getCertificateLabel = (langCode: string, stageNumber: number, levelNumber: number) => {
  const code = langCode.toLowerCase();
  if (code === "ja" || code === "japanese") {
    const jlptMap: Record<number, string> = { 1: "N5", 2: "N4", 3: "N3", 4: "N2", 5: "N1" };
    return jlptMap[levelNumber] || `N${6 - Math.min(Math.max(levelNumber, 1), 5)}`;
  }
  if (code === "zh" || code === "chinese" || code === "cn") {
    return `HSK ${Math.min(Math.max(levelNumber, 1), 6)}`;
  }
  const cefrMap: Record<number, string> = { 1: "A1", 2: "A2", 3: "B1", 4: "B2", 5: "C1", 6: "C2" };
  return cefrMap[levelNumber] || "B1";
};

const CountryThemeBackground = ({ lang }: { lang: string }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationId: number;
    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const handleResize = () => {
      if (!canvas) return;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    };
    window.addEventListener("resize", handleResize);

    // Particles definitions
    interface SakuraPetal {
      x: number;
      y: number;
      size: number;
      speedY: number;
      speedX: number;
      rotation: number;
      rotationSpeed: number;
      sway: number;
      swaySpeed: number;
      opacity: number;
    }

    interface Lantern {
      x: number;
      y: number;
      width: number;
      height: number;
      speedY: number;
      sway: number;
      swaySpeed: number;
      opacity: number;
    }

    interface FireworkSpark {
      x: number;
      y: number;
      vx: number;
      vy: number;
      color: string;
      size: number;
      alpha: number;
      decay: number;
    }

    interface FireworkRocket {
      x: number;
      y: number;
      tx: number;
      ty: number;
      vy: number;
      color: string;
    }

    // Initialize particles & decorative elements
    let sakuraPetals: SakuraPetal[] = [];
    let lanterns: Lantern[] = [];
    let rockets: FireworkRocket[] = [];
    let sparks: FireworkSpark[] = [];

    if (lang === "ja") {
      for (let i = 0; i < 25; i++) {
        // Spawn some near left branch tips, some near right branch tips, and some scattered
        const isLeft = Math.random() < 0.5;
        const px = isLeft 
          ? Math.random() * width * 0.35 
          : width - Math.random() * width * 0.35;
        const py = Math.random() * height * 0.7;

        sakuraPetals.push({
          x: px,
          y: py,
          size: Math.random() * 8 + 5,
          speedY: Math.random() * 1.2 + 0.8,
          speedX: Math.random() * 0.8 - 0.2,
          rotation: Math.random() * Math.PI * 2,
          rotationSpeed: Math.random() * 0.02 - 0.01,
          sway: Math.random() * Math.PI * 2,
          swaySpeed: Math.random() * 0.03 + 0.01,
          opacity: Math.random() * 0.6 + 0.3,
        });
      }
    } else if (lang === "zh") {
      for (let i = 0; i < 15; i++) {
        lanterns.push({
          x: Math.random() * width,
          y: Math.random() * height + Math.random() * 200,
          width: Math.random() * 10 + 10,
          height: Math.random() * 14 + 12,
          speedY: -(Math.random() * 0.5 + 0.4),
          sway: Math.random() * Math.PI * 2,
          swaySpeed: Math.random() * 0.02 + 0.01,
          opacity: Math.random() * 0.7 + 0.3,
        });
      }
    }

    const createSparks = (x: number, y: number) => {
      const count = Math.floor(Math.random() * 40 + 100); // Massive explosion
      const colorChoices = [
        ["#FFDF00", "#FFD700", "#FF8C00", "#FF3B30", "#D4AF37"], // Gold & Orange & Red
        ["#FF007F", "#FF00FF", "#00FFFF", "#FFD700", "#39FF14"], // Vibrant Neon mix (hot pink, magenta, cyan, gold, neon green)
        ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA"]  // Festive colors
      ];
      const selectedPalette = colorChoices[Math.floor(Math.random() * colorChoices.length)];
      for (let i = 0; i < count; i++) {
        const angle = Math.random() * Math.PI * 2;
        const speed = Math.random() * 5.5 + 2.0; // Higher velocity for huge burst
        const color = selectedPalette[Math.floor(Math.random() * selectedPalette.length)];
        sparks.push({
          x,
          y,
          vx: Math.cos(angle) * speed,
          vy: Math.sin(angle) * speed - 0.5,
          color,
          size: Math.random() * 2.8 + 1.2,
          alpha: 1,
          decay: Math.random() * 0.012 + 0.008,
        });
      }
    };

    const drawSakuraFlower = (x: number, y: number, radius: number, opacity: number) => {
      ctx.save();
      ctx.translate(x, y);
      
      const numPetals = 5;
      ctx.fillStyle = `rgba(255, 185, 200, ${opacity * 0.95})`; // Cute soft pink
      
      for (let i = 0; i < numPetals; i++) {
        ctx.save();
        ctx.rotate((i * 2 * Math.PI) / numPetals);
        
        // Draw heart-shaped petal pointing upwards
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.bezierCurveTo(-radius * 0.5, -radius * 0.5, -radius * 0.2, -radius * 1.0, 0, -radius * 0.85);
        ctx.bezierCurveTo(radius * 0.2, -radius * 1.0, radius * 0.5, -radius * 0.5, 0, 0);
        ctx.fill();
        
        // Soft outline to separate overlapping petals
        ctx.strokeStyle = `rgba(235, 120, 140, ${opacity * 0.4})`;
        ctx.lineWidth = 0.5;
        ctx.stroke();
        
        ctx.restore();
      }
      
      // Draw a darker pink center
      ctx.fillStyle = `rgba(225, 112, 137, ${opacity})`;
      ctx.beginPath();
      ctx.arc(0, 0, radius * 0.25, 0, Math.PI * 2);
      ctx.fill();
      
      // Tiny white/light yellow pistil tips
      ctx.fillStyle = `rgba(255, 255, 235, ${opacity * 0.9})`;
      for (let j = 0; j < 5; j++) {
        const angle = (j * 2 * Math.PI) / 5 + Math.PI / 5;
        const px = Math.cos(angle) * (radius * 0.2);
        const py = Math.sin(angle) * (radius * 0.2);
        ctx.beginPath();
        ctx.arc(px, py, radius * 0.06, 0, Math.PI * 2);
        ctx.fill();
      }
      
      ctx.restore();
    };

    const drawBud = (x: number, y: number, radius: number, opacity: number) => {
      ctx.save();
      ctx.translate(x, y);
      
      // Sepals (green base)
      ctx.fillStyle = `rgba(76, 120, 76, ${opacity * 0.85})`;
      ctx.beginPath();
      ctx.moveTo(-radius * 0.6, radius * 0.6);
      ctx.lineTo(0, radius * 1.2);
      ctx.lineTo(radius * 0.6, radius * 0.6);
      ctx.closePath();
      ctx.fill();
      
      // Bud body (deep pink teardrop)
      ctx.fillStyle = `rgba(235, 95, 125, ${opacity})`;
      ctx.beginPath();
      ctx.ellipse(0, 0, radius, radius * 1.4, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    };

    const drawTree = (isLeft: boolean, windOffset: number) => {
      ctx.save();
      ctx.strokeStyle = "#2d241f"; // Dark wabi-sabi bark
      ctx.lineCap = "round";
      
      const startX = isLeft ? 0 : width;
      const startY = height;
      
      // Sinuous trunk - pushed closer to the edges
      const targetX = isLeft ? width * 0.08 + windOffset * 2 : width * 0.92 + windOffset * 2;
      const targetY = height * 0.72; // Shorter
      const controlX = isLeft ? width * 0.02 : width * 0.98;
      const controlY = height * 0.88;

      const getTrunkPoint = (t: number) => {
        const x = (1 - t) * (1 - t) * startX + 2 * (1 - t) * t * controlX + t * t * targetX;
        const y = (1 - t) * (1 - t) * startY + 2 * (1 - t) * t * controlY + t * t * targetY;
        const dx = 2 * (1 - t) * (controlX - startX) + 2 * t * (targetX - controlX);
        const dy = 2 * (1 - t) * (controlY - startY) + 2 * t * (targetY - controlY);
        const angle = Math.atan2(dy, dx);
        return { x, y, angle };
      };

      ctx.beginPath();
      ctx.moveTo(startX, startY);
      ctx.quadraticCurveTo(controlX, controlY, targetX, targetY);
      ctx.lineWidth = 26;
      ctx.stroke();

      // Gnarled wood bark lines
      ctx.strokeStyle = "#1a1310"; // Deeper dark bark texture
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(startX + (isLeft ? 4 : -4), startY);
      ctx.quadraticCurveTo(controlX + (isLeft ? 2 : -2), controlY, targetX, targetY);
      ctx.stroke();
      
      const drawBranch = (bx: number, by: number, len: number, ang: number, depth: number) => {
        // Smooth out the branch joints by filling a junction circle to prevent detached lines
        ctx.fillStyle = "#2d241f";
        ctx.beginPath();
        ctx.arc(bx, by, depth * 1.8, 0, Math.PI * 2);
        ctx.fill();

        if (depth <= 0) {
          // Draw a dense cluster of 5 cute overlapping flowers for a lush look
          drawSakuraFlower(bx, by, 16, 0.9);
          drawSakuraFlower(bx - 12, by + 6, 12, 0.85);
          drawSakuraFlower(bx + 12, by - 6, 12, 0.85);
          drawSakuraFlower(bx + 6, by + 12, 10, 0.8);
          drawSakuraFlower(bx - 6, by - 12, 10, 0.8);
          
          // Buds
          drawBud(bx - 14, by - 8, 5, 0.85);
          drawBud(bx + 14, by + 8, 4.5, 0.85);
          drawBud(bx - 8, by + 14, 4, 0.8);
          return;
        }

        // Draw smaller blossoms at intermediate junctions for denser foliage
        if (depth <= 3) {
          drawSakuraFlower(bx, by, 12, 0.75);
          drawSakuraFlower(bx + 8, by - 6, 9, 0.65);
          drawBud(bx - 10, by + 5, 3.5, 0.7);
        }
        
        const branchWind = Math.sin(tick * 0.035 + depth) * 0.018;
        const nextX = bx + Math.cos(ang + branchWind) * len;
        const nextY = by + Math.sin(ang + branchWind) * len;
        
        // Calculate control point for a subtle organic curve/bend ( wiggle )
        const midX = (bx + nextX) / 2;
        const midY = (by + nextY) / 2;
        const dx = nextX - bx;
        const dy = nextY - by;
        const nx = -dy / len;
        const ny = dx / len;
        const bendOffset = Math.sin(bx * 0.05 + depth) * (len * 0.12); 
        const cx = midX + nx * bendOffset;
        const cy = midY + ny * bendOffset;

        ctx.strokeStyle = "#2d241f";
        ctx.lineWidth = depth * 3.5;
        ctx.beginPath();
        ctx.moveTo(bx, by);
        ctx.quadraticCurveTo(cx, cy, nextX, nextY);
        ctx.stroke();
        
        drawBranch(nextX, nextY, len * 0.72, ang - 0.35, depth - 1);
        drawBranch(nextX, nextY, len * 0.68, ang + 0.35, depth - 1);
      };
      
      // Organically draw branches stemming directly from calculated points on the trunk
      const topTrunk = getTrunkPoint(1.0);
      drawBranch(topTrunk.x, topTrunk.y, 100, topTrunk.angle - 0.35, 3);
      drawBranch(topTrunk.x, topTrunk.y, 90, topTrunk.angle + 0.35, 3);

      const midTrunk = getTrunkPoint(0.55);
      const sideAngle1 = isLeft ? midTrunk.angle + 0.7 : midTrunk.angle - 0.7;
      drawBranch(midTrunk.x, midTrunk.y, 70, sideAngle1, 2);

      const highTrunk = getTrunkPoint(0.8);
      const sideAngle2 = isLeft ? highTrunk.angle - 0.6 : highTrunk.angle + 0.6;
      drawBranch(highTrunk.x, highTrunk.y, 60, sideAngle2, 2);
      ctx.restore();
    };

    let tick = 0;

    const renderLoop = () => {
      ctx.clearRect(0, 0, width, height);
      tick++;

      if (lang === "ja") {
        // Draw 2 Cherry Blossom Trees at the sides
        const windOffset = Math.sin(tick * 0.025) * 6;
        drawTree(true, windOffset);  // Left Tree
        drawTree(false, windOffset); // Right Tree

        sakuraPetals.forEach((p) => {
          p.y += p.speedY;
          p.x += p.speedX + Math.sin(p.sway) * 0.5;
          p.sway += p.swaySpeed;
          p.rotation += p.rotationSpeed;

          if (p.y > height) {
            p.y = -20;
            const isLeft = Math.random() < 0.5;
            p.x = isLeft 
              ? Math.random() * width * 0.35 
              : width - Math.random() * width * 0.35;
            p.speedY = Math.random() * 1.2 + 0.8;
            p.opacity = Math.random() * 0.6 + 0.3;
          }
          if (p.x > width) p.x = 0;
          if (p.x < 0) p.x = width;

          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rotation);
          ctx.fillStyle = `rgba(255, 185, 200, ${p.opacity})`; // Soft cherry blossom pink
          
          // Draw heart-shaped petal
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.bezierCurveTo(-p.size * 0.5, -p.size * 0.5, -p.size * 0.2, -p.size * 1.0, 0, -p.size * 0.85);
          ctx.bezierCurveTo(p.size * 0.2, -p.size * 1.0, p.size * 0.5, -p.size * 0.5, 0, 0);
          ctx.fill();
          
          // Subtle highlight in the middle
          ctx.fillStyle = `rgba(255, 240, 245, ${p.opacity * 0.6})`;
          ctx.beginPath();
          ctx.moveTo(0, -p.size * 0.1);
          ctx.bezierCurveTo(-p.size * 0.25, -p.size * 0.3, -p.size * 0.1, -p.size * 0.6, 0, -p.size * 0.5);
          ctx.bezierCurveTo(p.size * 0.1, -p.size * 0.6, p.size * 0.25, -p.size * 0.3, 0, -p.size * 0.1);
          ctx.fill();
          
          ctx.restore();
        });
      } else if (lang === "zh") {
        // Floating Lanterns (softer glow)
        lanterns.forEach((l) => {
          l.y += l.speedY;
          l.x += Math.sin(l.sway) * 0.25;
          l.sway += l.swaySpeed;

          if (l.y < -30) {
            l.y = height + Math.random() * 100;
            l.x = Math.random() * width;
          }

          ctx.save();
          ctx.translate(l.x, l.y);
          
          const glow = ctx.createRadialGradient(0, 0, 2, 0, 0, l.width * 1.5);
          glow.addColorStop(0, "rgba(212, 175, 55, 0.3)");
          glow.addColorStop(0.4, "rgba(139, 0, 5, 0.15)");
          glow.addColorStop(1, "rgba(26, 0, 3, 0)");
          ctx.fillStyle = glow;
          ctx.beginPath();
          ctx.arc(0, 0, l.width * 1.5, 0, Math.PI * 2);
          ctx.fill();

          ctx.fillStyle = `rgba(179, 0, 24, ${l.opacity})`; // Warm dark crimson lantern
          ctx.strokeStyle = `rgba(212, 175, 55, ${l.opacity})`;
          ctx.lineWidth = 1;
          ctx.beginPath();
          ctx.ellipse(0, 0, l.width * 0.7, l.height * 0.6, 0, 0, Math.PI * 2);
          ctx.fill();
          ctx.stroke();

          ctx.fillStyle = `rgba(197, 160, 40, ${l.opacity})`;
          ctx.fillRect(-l.width * 0.4, -l.height * 0.65, l.width * 0.8, 2);
          ctx.fillRect(-l.width * 0.4, l.height * 0.6, l.width * 0.8, 2);

          ctx.strokeStyle = `rgba(197, 160, 40, ${l.opacity * 0.8})`;
          ctx.beginPath();
          ctx.moveTo(0, l.height * 0.62);
          ctx.lineTo(0, l.height * 0.62 + 8);
          ctx.stroke();

          ctx.restore();
        });
 
        // Firework Rockets
        if (Math.random() < 0.015 && rockets.length < 4) {
          const targetX = Math.random() * (width - 200) + 100;
          const targetY = Math.random() * (height * 0.45) + 50;
          rockets.push({
            x: Math.random() * (width - 100) + 50,
            y: height,
            tx: targetX,
            ty: targetY,
            vy: -(Math.random() * 5 + 7),
            color: "#FFDF00",
          });
        }
 
        rockets.forEach((r, idx) => {
          r.y += r.vy;
          r.x += Math.sin(tick * 0.05) * 0.5;
 
          if (Math.random() < 0.45) {
            sparks.push({
              x: r.x,
              y: r.y,
              vx: Math.random() * 0.6 - 0.3,
              vy: Math.random() * 0.6,
              color: "rgba(255, 223, 0, 0.4)",
              size: 1.5,
              alpha: 0.8,
              decay: 0.04,
            });
          }
 
          ctx.fillStyle = r.color;
          ctx.beginPath();
          ctx.arc(r.x, r.y, 2.5, 0, Math.PI * 2);
          ctx.fill();
 
          if (r.y <= r.ty) {
            createSparks(r.x, r.y);
            rockets.splice(idx, 1);
          }
        });
 
        // Backward loop to safely update sparks with air resistance and deceleration physics
        for (let idx = sparks.length - 1; idx >= 0; idx--) {
          const s = sparks[idx];
          s.x += s.vx;
          s.y += s.vy;
          s.vx *= 0.98; // Air resistance deceleration
          s.vy = s.vy * 0.98 + 0.05; // Gravity pull + air resistance
          s.alpha -= s.decay;
 
          if (s.alpha <= 0) {
            sparks.splice(idx, 1);
            continue;
          }
 
          ctx.fillStyle = s.color;
          ctx.globalAlpha = s.alpha;
          ctx.beginPath();
          ctx.arc(s.x, s.y, s.size, 0, Math.PI * 2);
          ctx.fill();
          ctx.globalAlpha = 1.0;
        }
      }

      animationId = requestAnimationFrame(renderLoop);
    };

    renderLoop();

    return () => {
      window.removeEventListener("resize", handleResize);
      cancelAnimationFrame(animationId);
    };
  }, [lang]);

  if (lang === "en" || !lang) return null;

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 w-full h-full pointer-events-none z-0"
      style={{ mixBlendMode: lang === "zh" ? "screen" : "normal" }}
    />
  );
};

const langFlags: Record<string, string> = { en: '🇺🇸 EN', ja: '🇯🇵 JA', zh: '🇨🇳 ZH' };

// Interface translations
const translations: Record<string, Record<string, string>> = {
  en: {
    brand: "LUCY",
    sub: "ARCHIVE",
    title: "SPEAK",
    titleAccent: "WITHOUT FEAR.",
    desc: "Anonymous, high-fidelity language practice rooms. Join an active session below.",
    btnStart: "START SESSION",
    btnHow: "HOW IT WORKS",
    searchPlaceholder: "Search archive...",
    filterAll: "ALL",
    langFilter: "Language",
    usersCount: "USERS",
    statusLive: "LIVE",
    statusScheduled: "SCHEDULED",
    statusEnded: "ENDED",
    join: "JOIN",
    ended: "ENDED"
  },
  ja: {
    brand: "LUCY",
    sub: "ARCHIVE",
    title: "SPEAK",
    titleAccent: "WITHOUT FEAR.",
    desc: "Anonymous, high-fidelity language practice rooms. Join an active session below.",
    btnStart: "START SESSION",
    btnHow: "HOW IT WORKS",
    searchPlaceholder: "Search archive...",
    filterAll: "ALL",
    langFilter: "Language",
    usersCount: "USERS",
    statusLive: "LIVE",
    statusScheduled: "SCHEDULED",
    statusEnded: "ENDED",
    join: "JOIN",
    ended: "ENDED"
  },
  zh: {
    brand: "LUCY",
    sub: "ARCHIVE",
    title: "SPEAK",
    titleAccent: "WITHOUT FEAR.",
    desc: "Anonymous, high-fidelity language practice rooms. Join an active session below.",
    btnStart: "START SESSION",
    btnHow: "HOW IT WORKS",
    searchPlaceholder: "Search archive...",
    filterAll: "ALL",
    langFilter: "Language",
    usersCount: "USERS",
    statusLive: "LIVE",
    statusScheduled: "SCHEDULED",
    statusEnded: "ENDED",
    join: "JOIN",
    ended: "ENDED"
  }
};

export default function LobbyPage() {
  const router = useRouter();
  const [activeLang, setActiveLang] = useState<string>("en");
  const [rooms, setRooms] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeLevel, setActiveLevel] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [isSwapping, setIsSwapping] = useState(false);
  const [userName, setUserName] = useState("User");
  const [userEmail, setUserEmail] = useState("");
  const [showUserMenu, setShowUserMenu] = useState(false);

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
    } catch (error) {
      console.error('Logout failed:', error);
    }
    // Clear cookies fallback
    document.cookie = 'lucy_token=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    document.cookie = 'lucy_user=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    router.push('/login');
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (!target.closest('.nav-user')) {
        setShowUserMenu(false);
      }
    };
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, []);

  // Sync state from localStorage & cookie on mount
  useEffect(() => {
    const savedLang = localStorage.getItem("activeLang");
    if (savedLang) {
      setActiveLang(savedLang);
    } else {
      setActiveLang("");
    }

    // Read user info from cookie
    try {
      const userCookie = document.cookie
        .split('; ')
        .find(row => row.startsWith('lucy_user='));
      if (userCookie) {
        const userJson = decodeURIComponent(userCookie.split('=').slice(1).join('='));
        const user = JSON.parse(userJson);
        if (user.displayName) {
          setUserName(user.displayName);
        } else if (user.email) {
          setUserName(user.email.split('@')[0]);
        }
        if (user.email) {
          setUserEmail(user.email);
        }
      }
    } catch (e) {
      // ignore parse errors
    }
  }, []);

  const handleLangChange = (newLang: string) => {
    setIsSwapping(true);
    // Persist language selection
    localStorage.setItem("activeLang", newLang);
    setTimeout(() => {
      setActiveLang(newLang);
      setActiveLevel(""); // Reset level filter
      setIsSwapping(false);
    }, 500);
  };

  const getLevelOptions = () => {
    if (activeLang === "en") return ["A1", "A2", "B1", "B2"];
    if (activeLang === "ja") return ["N5", "N4", "N3", "N2", "N1"];
    if (activeLang === "zh") return ["HSK 1", "HSK 2", "HSK 3", "HSK 4", "HSK 5", "HSK 6"];
    return ["A1", "A2", "B1", "B2"];
  };

  // Fetch Rooms & Sync with backend
  useEffect(() => {
    let cancelled = false;

    const fetchRoomsAndLevels = async (): Promise<void> => {
      let timeoutId: any;
      try {
        const fetchPromise = fetch("/api/v1/rooms", {
          headers: {
            "ngrok-skip-browser-warning": "69420"
          }
        }).then(r => {
          if (!r.ok) throw new Error("Not ok");
          return r.json();
        });

        const timeoutPromise = new Promise<any>((_, reject) => {
          timeoutId = setTimeout(() => reject(new Error("Timeout")), 2000);
        });

        const data = await Promise.race([fetchPromise, timeoutPromise]);
        clearTimeout(timeoutId);

        if (data && Array.isArray(data) && data.length > 0) {
          const mappedRooms = data.map((r: any) => {
            const langCode = r.levelId === 2 ? "ja" : r.levelId === 3 ? "zh" : "en";
            const levelLabel = langCode === "ja" ? "N5" : langCode === "zh" ? "HSK 4" : "B1";
            const seedName = r.agoraChannelName ? r.agoraChannelName.replace(/\s+/g, "-").toLowerCase() : `room-${r.id}`;

            return {
              id: r.id,
              name: r.name || r.agoraChannelName || `Room #${r.id}`,
              level: levelLabel, 
              lang: langCode, 
              users: 0,
              status: "LIVE",
              desc: r.topic || "Anonymous high-fidelity practice room.",
              image: `https://picsum.photos/seed/${seedName}/600/400`
            };
          });
          if (!cancelled) {
            setRooms(mappedRooms);
            setLoading(false);
          }
          return;
        }
      } catch (err) {
        clearTimeout(timeoutId);
        console.warn("Backend API not reachable. Using fallback local localized room data.");
      }
      
      if (!cancelled) {
        setRooms(getLocalizedRooms(activeLang));
      }
      // Force loading to false no matter what to prevent infinite loading screens
      setLoading(false);
    };

    fetchRoomsAndLevels();
    return () => { cancelled = true; };
  }, [activeLang]);

  const handleJoin = (id: number) => {
    router.push(`/room/${id}`);
  };

  // Filter logic
  const filteredRooms = rooms.filter((room) => {
    const matchesLevel = activeLevel ? room.level === activeLevel : true;
    const matchesLang = activeLang ? room.lang === activeLang : true;
    const matchesSearch = searchQuery
      ? room.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        room.desc.toLowerCase().includes(searchQuery.toLowerCase())
      : true;
    return matchesLevel && matchesLang && matchesSearch;
  });

  const bentoRooms = filteredRooms.slice(0, 5);
  const bentoClasses = [
    "bento-span-8 featured col-span-12 lg:col-span-8 lg:row-span-2",
    "bento-span-4 col-span-12 lg:col-span-4 lg:row-span-1",
    "bento-span-4 col-span-12 lg:col-span-4 lg:row-span-1",
    "bento-span-6 col-span-12 lg:col-span-6",
    "bento-span-6 col-span-12 lg:col-span-6"
  ];

  const t = translations[activeLang || "en"];

  return (
    <div className={`flex-1 relative overflow-hidden min-h-screen theme-${activeLang || 'en'}`}>
      <CountryThemeBackground lang={activeLang} />

      {/* GSAP / Framer Motion Curtain Switch Transition */}
      <AnimatePresence>
        {isSwapping && (
          <motion.div
            initial={{ y: "-100%" }}
            animate={{ y: ["-100%", "0%", "100%"] }}
            exit={{ y: "100%" }}
            transition={{ duration: 1.0, ease: [0.76, 0, 0.24, 1] }}
            className={`fixed inset-0 z-[10000] pointer-events-none ${
              activeLang === "ja" ? "bg-[#db8a9c]" : activeLang === "zh" ? "bg-[#8B0000]" : "bg-[#111111]"
            }`}
          />
        )}
      </AnimatePresence>
      
      {activeLang === "" ? (
        <div className="flex items-center justify-center min-h-[90dvh] px-6 py-12 z-10 relative">
          <motion.div
            initial={{ opacity: 1, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
            className="glass-panel max-w-[840px] w-full p-10 md:p-16 rounded-[32px] text-center"
          >
            <h2 className="text-3xl sm:text-5xl font-black tracking-tight mb-4 text-[var(--text-main)]">
              WHAT DO YOU WANT TO LEARN?
            </h2>
            <p className="text-[var(--text-muted)] text-sm sm:text-base max-w-[480px] mx-auto mb-12 leading-relaxed">
              Select a target language to start practicing anonymous, high-fidelity language reflexes. The UI style and certificate filters will auto-tune.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full mb-8">
              {[
                { code: "en", name: "ENGLISH", localName: "CEFR Certificate", desc: "A1 to B2 Levels", flag: "🇬🇧" },
                { code: "ja", name: "JAPANESE", localName: "JLPT Certificate", desc: "N5 to N1 Levels", flag: "🇯🇵" },
                { code: "zh", name: "CHINESE", localName: "HSK Certificate", desc: "1 to 6 Levels", flag: "🇨🇳" }
              ].map((langItem) => (
                <button
                  key={langItem.code}
                  onClick={() => handleLangChange(langItem.code)}
                  className="glass-panel flex flex-col items-center justify-center p-8 hover:border-[var(--cyan)] hover:bg-[var(--surface-hover)] hover:-translate-y-1.5 transition-all duration-300 group cursor-pointer text-center"
                >
                  <span className="text-5xl mb-4 filter drop-shadow-sm group-hover:scale-110 transition-transform duration-300">{langItem.flag}</span>
                  <span className="font-display font-black text-xl text-[var(--text-main)] group-hover:text-[var(--cyan)] transition-colors">{langItem.name}</span>
                  <span className="text-xs font-mono text-[var(--text-muted)] mt-1">{langItem.localName}</span>
                  <span className="text-[10px] font-mono font-bold text-[var(--magenta)] bg-[var(--magenta)]/5 border border-[var(--magenta)]/25 px-2 py-0.5 rounded mt-4 uppercase">
                    {langItem.desc}
                  </span>
                </button>
              ))}
            </div>

            <button
              onClick={() => handleLangChange("en")}
              className="text-xs font-mono font-bold text-[var(--text-muted)] hover:text-[var(--text-main)] transition-colors underline cursor-pointer"
            >
              PROCEED WITH DEFAULT OVERVIEW
            </button>
          </motion.div>
        </div>
      ) : (
        <>
          {/* Navigation */}
          <nav className="top-nav">
            <div className="nav-brand">
              {t.brand}
              <span className="nav-brand-sub">{t.sub}</span>
            </div>
            <div className="nav-actions flex items-center gap-4">
              <button 
                onClick={() => router.push('/wallet')}
                className="btn-nap-xu flex items-center gap-2 px-4.5 py-2 rounded-full font-bold transition-all duration-300 z-50 cursor-pointer bg-[#0f111a] hover:bg-[#161927] border border-[#fbbf24]/50 hover:border-[#fbbf24] backdrop-blur-xl shadow-[0_0_15px_rgba(251,191,36,0.25)] hover:shadow-[0_0_25px_rgba(251,191,36,0.5)] hover:scale-105 active:scale-95 group"
              >
                <Wallet size={20} weight="duotone" className="btn-nap-xu-icon text-[#fbbf24] drop-shadow-[0_0_8px_rgba(251,191,36,0.6)] group-hover:rotate-12 transition-transform duration-300" />
                <span className="btn-nap-xu-text text-[#fbbf24] font-black tracking-wide text-sm drop-shadow-[0_0_6px_rgba(251,191,36,0.4)]">
                  Nạp Xu
                </span>
              </button>
              {/* Target Language Switcher (Button Group) */}
              <div className="lang-switcher">
                <button 
                  onClick={() => handleLangChange("en")} 
                  className={`lang-btn ${activeLang === "en" ? "active" : ""}`}
                >
                  EN
                </button>
                <button 
                  onClick={() => handleLangChange("ja")} 
                  className={`lang-btn ${activeLang === "ja" ? "active" : ""}`}
                >
                  JA
                </button>
                <button 
                  onClick={() => handleLangChange("zh")} 
                  className={`lang-btn ${activeLang === "zh" ? "active" : ""}`}
                >
                  ZH
                </button>
              </div>

              <div className="nav-user" style={{ position: 'relative' }}>
                <button
                  onClick={() => {
                    if (userName === "User") {
                      // Force clear cookies and redirect by reusing handleLogout
                      handleLogout();
                    } else {
                      setShowUserMenu(!showUserMenu);
                    }
                  }}
                  className="flex items-center gap-3 cursor-pointer bg-transparent border-none outline-none"
                  style={{ background: 'none', border: 'none', padding: 0 }}
                >
                  <span className="user-name">{userName}</span>
                  <div className="avatar-wrap">
                    <img
                      src={`https://api.dicebear.com/9.x/notionists/svg?seed=${encodeURIComponent(userName)}`}
                      alt="Avatar"
                    />
                  </div>
                </button>

                {/* User Dropdown */}
                <AnimatePresence>
                  {showUserMenu && (
                    <motion.div
                      initial={{ opacity: 1, y: -8, scale: 0.95 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 1, y: -8, scale: 0.95 }}
                      transition={{ duration: 0.15 }}
                      className="user-dropdown"
                      style={{
                        position: 'absolute',
                        top: 'calc(100% + 12px)',
                        right: 0,
                        minWidth: '220px',
                        background: 'var(--surface)',
                        border: '1px solid var(--border)',
                        borderRadius: '16px',
                        padding: '8px',
                        zIndex: 999,
                        backdropFilter: 'blur(20px)',
                        boxShadow: '0 16px 48px rgba(0,0,0,0.3)',
                      }}
                    >
                      <div style={{ padding: '12px 14px', borderBottom: '1px solid var(--border)', marginBottom: '6px' }}>
                        <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--text-main)' }}>{userName}</div>
                        <div style={{ fontSize: '11px', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)', marginTop: '2px' }}>{userEmail}</div>
                      </div>
                      <button
                        onClick={handleLogout}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '10px',
                          width: '100%',
                          padding: '10px 14px',
                          background: 'none',
                          border: 'none',
                          borderRadius: '10px',
                          cursor: 'pointer',
                          color: '#ef4444',
                          fontSize: '13px',
                          fontWeight: 600,
                          transition: 'background 0.15s',
                        }}
                        onMouseEnter={(e) => (e.currentTarget.style.background = 'rgba(239,68,68,0.08)')}
                        onMouseLeave={(e) => (e.currentTarget.style.background = 'none')}
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                        Sign Out
                      </button>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </div>
          </nav>

          {/* Main Content */}
          <main className="lobby-main relative z-10 px-6 md:px-12 py-12 md:py-20 max-w-[1200px] mx-auto">
            {/* Hero split layout */}
            <header className="hero-split grid grid-cols-1 lg:grid-cols-[1.1fr_0.9fr] gap-12 lg:gap-20 items-center mb-20 md:mb-24">
              <motion.div
                initial={{ opacity: 1, y: 55 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 1.2, ease: [0.16, 1, 0.3, 1] }}
                className="hero-content"
              >
                <h1 className="hero-title text-[56px] sm:text-[76px] lg:text-[100px] font-black leading-[0.8] tracking-tighter mb-8 text-[var(--text-main)]">
                  {t.title}
                  <br />
                  <span className="hero-accent">{t.titleAccent}</span>
                </h1>
                <p className="hero-desc text-base md:text-lg text-[var(--text-muted)] max-w-[440px] leading-relaxed mb-12">
                  {t.desc}
                </p>
                <div className="hero-ctas flex gap-4 flex-wrap">
                  <button
                    onClick={() => handleJoin(101)}
                    className="btn-primary"
                  >
                    {t.btnStart}
                  </button>
                  <button className="btn-ghost">{t.btnHow}</button>
                </div>
              </motion.div>

              <motion.div
                initial={{ opacity: 1, scale: 0.96 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 1.5, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
                className="hero-visual animate-fade-in"
              >
                <img
                  className="hero-img w-full h-full object-cover"
                  src={
                    activeLang === "ja" ? "/assets/images/benthanh_sakura.png" : 
                    activeLang === "zh" ? "/assets/images/chinese_dragon_festival.png" : 
                    "/assets/images/english_minimalist_studio.png"
                  }
                  alt="LUCY Audio Space Theme Illustration"
                />
                <div className="hero-visual-overlay"></div>
              </motion.div>
            </header>

            {/* Filter Bar */}
            <div className="filter-bar flex flex-col md:flex-row justify-between items-start md:items-center gap-6 border-b border-[var(--border)] pb-6 mb-12">
              <div className="filter-group flex gap-2 flex-wrap">
                <button
                  onClick={() => setActiveLevel("")}
                  className={`filter-pill ${activeLevel === "" ? "active" : ""}`}
                >
                  {t.filterAll}
                </button>
                {getLevelOptions().map((level) => (
                  <button
                    key={level}
                    onClick={() => setActiveLevel(level)}
                    className={`filter-pill ${activeLevel === level ? "active" : ""}`}
                  >
                    {level}
                  </button>
                ))}
              </div>

              <div className="flex gap-4 w-full md:w-auto items-center">
                <div className="relative flex-1 md:flex-initial">
                  <MagnifyingGlass
                    size={16}
                    className="absolute left-4 top-1/2 transform -translate-y-1/2 text-[var(--text-muted)]"
                  />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t.searchPlaceholder}
                    className="search-input"
                  />
                </div>
              </div>
            </div>

            {/* Bento Grid */}
            <div className="grid grid-cols-12 gap-6 auto-rows-[minmax(320px,_auto)]">
              {loading && rooms.length === 0 ? (
                <div className="col-span-12 flex justify-center items-center py-20 text-xs font-mono tracking-wider text-[var(--text-muted)]">
                  LOADING REALTIME DATABASE...
                </div>
              ) : filteredRooms.length === 0 ? (
                <div className="col-span-12 flex flex-col justify-center items-center py-20 border border-dashed border-[var(--border)] rounded-3xl bg-black/[0.02]">
                  <ChatCircleText size={32} className="text-[var(--text-muted)] mb-4" />
                  <div className="text-xs font-mono tracking-wider text-[var(--text-muted)]">
                    NO ACTIVE ROOMS FOUND.
                  </div>
                </div>
              ) : (
                bentoRooms.map((room, index) => {
                  const isEnded = room.status === "ENDED";
                  const isScheduled = room.status === "SCHEDULED";
                  const extraClass = bentoClasses[index] || "col-span-12 lg:col-span-4";
                  const imgBg = room.image ? (
                    <img
                      className="card-bg-img absolute inset-0 w-full h-full object-cover z-0"
                      src={room.image}
                      alt=""
                    />
                  ) : null;

                  return (
                    <motion.div
                      key={room.id}
                      initial={{ opacity: 1, y: 30 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.8, delay: index * 0.08 }}
                      className={`room-card glass-panel relative p-10 flex flex-col justify-between overflow-hidden group ${extraClass}`}
                    >
                      {imgBg}
                      <div className="relative z-10 w-full">
                        <div className="card-top flex justify-between items-start w-full">
                          <div className="flex flex-col items-start gap-2">
                            <div className="card-title text-xl md:text-2xl font-extrabold tracking-tight text-[var(--text-main)] group-hover:text-[var(--cyan)] transition-colors">
                              {room.name}
                            </div>
                            <div className="flex gap-2">
                              <span className="card-level text-[10px] font-mono font-bold text-[var(--cyan)] border border-[var(--cyan)]/30 bg-[var(--cyan)]/5 px-2 py-0.5 rounded">
                                {room.level}
                              </span>
                              <span className="card-level text-[10px] font-mono font-bold text-[var(--magenta)] border border-[var(--magenta)]/30 bg-[var(--magenta)]/5 px-2 py-0.5 rounded">
                                {langFlags[room.lang] || room.lang.toUpperCase()}
                              </span>
                            </div>
                          </div>
                          <div
                            className={`card-status font-mono text-[10px] font-bold tracking-wider flex items-center gap-2 ${
                              isScheduled ? "text-[var(--text-muted)]" : "text-[var(--magenta)]"
                            }`}
                          >
                            <span
                              className={`w-1.5 h-1.5 rounded-full ${
                                isScheduled
                                  ? "bg-[var(--text-muted)]"
                                  : "bg-[var(--magenta)] shadow-[0_0_10px_var(--magenta-glow)]"
                              }`}
                            />
                            {isScheduled
                              ? t.statusScheduled
                              : isEnded
                              ? t.statusEnded
                              : t.statusLive}
                          </div>
                        </div>
                        <div className={`card-desc mt-6 text-[14px] max-w-[90%] leading-relaxed ${room.image ? "text-[var(--text-main)]/90" : "text-[var(--text-muted)]"}`}>
                          {room.desc}
                        </div>
                      </div>

                      <div className="card-bottom relative z-10 flex justify-between items-center mt-8 w-full">
                        <div className="card-users font-mono text-xs text-[var(--text-muted)]">
                          [ {room.users} {t.usersCount} ]
                        </div>
                        <button
                          onClick={() => handleJoin(room.id)}
                          disabled={isEnded}
                          className={`btn-join py-3 px-8 font-bold text-xs tracking-wider transition-all duration-300 ${
                            room.image
                              ? "bg-[var(--magenta)] text-white hover:bg-[var(--magenta)]/80 hover:shadow-[0_0_20px_var(--magenta-glow)] border-transparent"
                              : "bg-[var(--surface)] text-[var(--text-main)] border border-[var(--border)] hover:bg-[var(--cyan)] hover:text-white hover:border-transparent hover:shadow-[0_0_20px_var(--cyan-glow)]"
                          } disabled:opacity-20 disabled:cursor-not-allowed`}
                        >
                          {isEnded ? t.ended : t.join}
                        </button>
                      </div>
                    </motion.div>
                  );
                })
              )}
            </div>
          </main>
        </>
      )}
    </div>
  );
}
