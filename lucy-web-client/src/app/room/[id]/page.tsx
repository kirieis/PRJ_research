"use client";

import React, { useState, useEffect, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { Microphone, MicrophoneSlash, HandWaving, Door, Record, Gift } from "@phosphor-icons/react";
import io, { Socket } from "socket.io-client";
import AgoraRTC, { IAgoraRTCClient, IMicrophoneAudioTrack } from "agora-rtc-sdk-ng";

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
      for (let i = 0; i < 50; i++) {
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
      
      // Calculate boundaries based on responsive layout sidebars
      const hasSidebars = width > 1024;
      const leftBoundary = hasSidebars ? 320 : 0;
      const rightBoundary = hasSidebars ? width - 320 : width;
      const activeWidth = rightBoundary - leftBoundary;

      const startX = isLeft ? leftBoundary : rightBoundary;
      const startY = height;
      
      // Sinuous trunk - aligned to the active stage edge to prevent overlapping sidebar participant lists
      const targetX = isLeft 
        ? leftBoundary + activeWidth * 0.08 + windOffset * 2 
        : rightBoundary - activeWidth * 0.08 + windOffset * 2;
      const targetY = height * 0.72; // Shorter
      const controlX = isLeft ? leftBoundary + activeWidth * 0.02 : rightBoundary - activeWidth * 0.02;
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
      drawBranch(topTrunk.x, topTrunk.y, 100, topTrunk.angle - 0.35, 5);
      drawBranch(topTrunk.x, topTrunk.y, 90, topTrunk.angle + 0.35, 4);

      const midTrunk = getTrunkPoint(0.55);
      const sideAngle1 = isLeft ? midTrunk.angle + 0.7 : midTrunk.angle - 0.7;
      drawBranch(midTrunk.x, midTrunk.y, 70, sideAngle1, 4);

      const highTrunk = getTrunkPoint(0.8);
      const sideAngle2 = isLeft ? highTrunk.angle - 0.6 : highTrunk.angle + 0.6;
      drawBranch(highTrunk.x, highTrunk.y, 60, sideAngle2, 3);
      
      ctx.restore();
    };

    let tick = 0;

    const renderLoop = () => {
      ctx.clearRect(0, 0, width, height);
      tick++;

      const hasSidebars = width > 1024;
      const leftBoundary = hasSidebars ? 320 : 0;
      const rightBoundary = hasSidebars ? width - 320 : width;
      const activeWidth = rightBoundary - leftBoundary;

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
              ? leftBoundary + Math.random() * activeWidth * 0.35 
              : rightBoundary - Math.random() * activeWidth * 0.35;
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

// Multilingual Mock Content
const SUB_LEVELS: Record<string, string[]> = {
  en: ["Greeting Strangers", "Daily Routines", "Travel Stories", "Future Plans"],
  ja: ["Greeting Strangers", "Daily Routines", "Travel Stories", "Future Plans"],
  zh: ["Greeting Strangers", "Daily Routines", "Travel Stories", "Future Plans"]
};

const HINTS_BY_LANG: Record<string, string[][]> = {
  en: [
    ["Introduce yourself to others briefly.", "Ask others about their day.", "Keep it polite and open."],
    ["Describe your morning routine.", "Discuss your ideal study/work hours.", "Compare weekdays and weekends."],
    ["Share a memorable trip you've had.", "What mode of transport do you prefer?", "Recommend a destination."],
    ["Your goals for the next 5 years.", "What new skill do you want to learn?", "Share your action plan."]
  ],
  ja: [
    ["Introduce yourself to others briefly.", "Ask others about their day.", "Keep it polite and open."],
    ["Describe your morning routine.", "Discuss your ideal study/work hours.", "Compare weekdays and weekends."],
    ["Share a memorable trip you've had.", "What mode of transport do you prefer?", "Recommend a destination."],
    ["Your goals for the next 5 years.", "What new skill do you want to learn?", "Share your action plan."]
  ],
  zh: [
    ["Introduce yourself to others briefly.", "Ask others about their day.", "Keep it polite and open."],
    ["Describe your morning routine.", "Discuss your ideal study/work hours.", "Compare weekdays and weekends."],
    ["Share a memorable trip you've had.", "What mode of transport do you prefer?", "Recommend a destination."],
    ["Your goals for the next 5 years.", "What new skill do you want to learn?", "Share your action plan."]
  ]
};

const VOCAB_BY_LANG: Record<string, { word: string; type: string; definition: string; ipa: string }[][]> = {
  en: [
    [
      { word: "Initiate", type: "v", definition: "Start (a conversation)", ipa: "/ɪˈnɪʃ.i.eɪt/" },
      { word: "Cordial", type: "adj", definition: "Warm and friendly", ipa: "/ˈkɔːr.dʒəl/" },
      { word: "Anonymity", type: "n", definition: "The state of remaining anonymous", ipa: "/ˌæn.əˈnɪm.ə.t̬i/" }
    ],
    [
      { word: "Productive", type: "adj", definition: "Achieving or producing a significant amount", ipa: "/prəˈdʌk.tɪv/" },
      { word: "Juggling", type: "v", definition: "Coping with or managing multiple tasks", ipa: "/ˈdʒʌɡ.lɪŋ/" },
      { word: "Monotonous", type: "adj", definition: "Dull, tedious, and repetitious", ipa: "/məˈnɑː.t̬ən.əs/" }
    ],
    [
      { word: "Wanderlust", type: "n", definition: "A strong desire to travel", ipa: "/ˈwɑːn.dɚ.lʌst/" },
      { word: "Picturesque", type: "adj", definition: "Visually attractive, especially in a quaint way", ipa: "/ˌpɪk.tʃərˈesk/" },
      { word: "Itinerary", type: "n", definition: "A planned route or journey", ipa: "/aɪˈtɪn.ə.rer.i/" }
    ],
    [
      { word: "Aspiration", type: "n", definition: "A hope or ambition of achieving something", ipa: "/ˌæs.pəˈreɪ.ʃən/" },
      { word: "Feasible", type: "adj", definition: "Possible to do easily or conveniently", ipa: "/ˈfiː.zə.bəl/" },
      { word: "Manifest", type: "v", definition: "Display or show by one's acts or appearance", ipa: "/ˈmæn.ə.fest/" }
    ]
  ],
  ja: [
    [
      { word: "Initiate", type: "v", definition: "Start (a conversation)", ipa: "/ɪˈnɪʃ.i.eɪt/" },
      { word: "Cordial", type: "adj", definition: "Warm and friendly", ipa: "/ˈkɔːr.dʒəl/" },
      { word: "Anonymity", type: "n", definition: "The state of remaining anonymous", ipa: "/ˌæn.əˈnɪm.ə.t̬i/" }
    ],
    [
      { word: "Productive", type: "adj", definition: "Achieving or producing a significant amount", ipa: "/prəˈdʌk.tɪv/" },
      { word: "Juggling", type: "v", definition: "Coping with or managing multiple tasks", ipa: "/ˈdʒʌɡ.lɪŋ/" },
      { word: "Monotonous", type: "adj", definition: "Dull, tedious, and repetitious", ipa: "/məˈnɑː.t̬ən.əs/" }
    ],
    [
      { word: "Wanderlust", type: "n", definition: "A strong desire to travel", ipa: "/ˈwɑːn.dɚ.lʌst/" },
      { word: "Picturesque", type: "adj", definition: "Visually attractive, especially in a quaint way", ipa: "/ˌpɪk.tʃərˈesk/" },
      { word: "Itinerary", type: "n", definition: "A planned route or journey", ipa: "/aɪˈtɪn.ə.rer.i/" }
    ],
    [
      { word: "Aspiration", type: "n", definition: "A hope or ambition of achieving something", ipa: "/ˌæs.pəˈreɪ.ʃən/" },
      { word: "Feasible", type: "adj", definition: "Possible to do easily or conveniently", ipa: "/ˈfiː.zə.bəl/" },
      { word: "Manifest", type: "v", definition: "Display or show by one's acts or appearance", ipa: "/ˈmæn.ə.fest/" }
    ]
  ],
  zh: [
    [
      { word: "Initiate", type: "v", definition: "Start (a conversation)", ipa: "/ɪˈnɪʃ.i.eɪt/" },
      { word: "Cordial", type: "adj", definition: "Warm and friendly", ipa: "/ˈkɔːr.dʒəl/" },
      { word: "Anonymity", type: "n", definition: "The state of remaining anonymous", ipa: "/ˌæn.əˈnɪm.ə.t̬i/" }
    ],
    [
      { word: "Productive", type: "adj", definition: "Achieving or producing a significant amount", ipa: "/prəˈdʌk.tɪv/" },
      { word: "Juggling", type: "v", definition: "Coping with or managing multiple tasks", ipa: "/ˈdʒʌɡ.lɪŋ/" },
      { word: "Monotonous", type: "adj", definition: "Dull, tedious, and repetitious", ipa: "/məˈnɑː.t̬ən.əs/" }
    ],
    [
      { word: "Wanderlust", type: "n", definition: "A strong desire to travel", ipa: "/ˈwɑːn.dɚ.lʌst/" },
      { word: "Picturesque", type: "adj", definition: "Visually attractive, especially in a quaint way", ipa: "/ˌpɪk.tʃərˈesk/" },
      { word: "Itinerary", type: "n", definition: "A planned route or journey", ipa: "/aɪˈtɪn.ə.rer.i/" }
    ],
    [
      { word: "Aspiration", type: "n", definition: "A hope or ambition of achieving something", ipa: "/ˌæs.pəˈreɪ.ʃən/" },
      { word: "Feasible", type: "adj", definition: "Possible to do easily or conveniently", ipa: "/ˈfiː.zə.bəl/" },
      { word: "Manifest", type: "v", definition: "Display or show by one's acts or appearance", ipa: "/ˈmæn.ə.fest/" }
    ]
  ]
};

const DEFAULT_USERS = [
  { id: 1, name: "Alex", role: "moderator", mic: true, speaking: true, handRaised: false },
  { id: 2, name: "Sarah", role: "pro", mic: true, speaking: false, handRaised: false },
  { id: 3, name: "Guest_03", role: "anonymous", mic: false, speaking: false, handRaised: false },
  { id: 4, name: "David", role: "pro", mic: false, speaking: false, handRaised: true },
  { id: 5, name: "Emily", role: "pro", mic: true, speaking: false, handRaised: false }
];

const TRANSLATED_LABELS: Record<string, Record<string, any>> = {
  en: {
    participants: "ACTIVE PARTICIPANTS",
    console: "SYSTEM CONSOLE",
    role: "MOD",
    new_words: "NEW WORDS TODAY",
    btn_next: "NEXT TOPIC →",
    btn_record: "● RECORD",
    btn_recording: "● RECORDING",
    btn_leave: "LEAVE ×",
    disconnect: "DISCONNECT?",
    disconnect_desc: "You are about to leave the active session.",
    btn_cancel: "CANCEL",
    btn_confirm: "CONFIRM",
    btn_raise_hand: "RAISE HAND",
    btn_hand_raised: "HAND RAISED",
    toast_completed: "All topics completed!",
    toast_advanced: "Advanced to:",
    toast_recording_start: "Session recording started.",
    toast_recording_saved: "Recording saved to system console.",
    user_names: ["Alex", "Sarah", "Guest_03", "David", "Emily"],
    user_roles: ["moderator", "pro", "anonymous", "pro", "pro"]
  },
  ja: {
    participants: "ACTIVE PARTICIPANTS",
    console: "SYSTEM CONSOLE",
    role: "MOD",
    new_words: "NEW WORDS TODAY",
    btn_next: "NEXT TOPIC →",
    btn_record: "● RECORD",
    btn_recording: "● RECORDING",
    btn_leave: "LEAVE ×",
    disconnect: "DISCONNECT?",
    disconnect_desc: "You are about to leave the active session.",
    btn_cancel: "CANCEL",
    btn_confirm: "CONFIRM",
    btn_raise_hand: "RAISE HAND",
    btn_hand_raised: "HAND RAISED",
    toast_completed: "All topics completed!",
    toast_advanced: "Advanced to:",
    toast_recording_start: "Session recording started.",
    toast_recording_saved: "Recording saved to system console.",
    user_names: ["Alex", "Sarah", "Guest_03", "David", "Emily"],
    user_roles: ["moderator", "pro", "anonymous", "pro", "pro"]
  },
  zh: {
    participants: "ACTIVE PARTICIPANTS",
    console: "SYSTEM CONSOLE",
    role: "MOD",
    new_words: "NEW WORDS TODAY",
    btn_next: "NEXT TOPIC →",
    btn_record: "● RECORD",
    btn_recording: "● RECORDING",
    btn_leave: "LEAVE ×",
    disconnect: "DISCONNECT?",
    disconnect_desc: "You are about to leave the active session.",
    btn_cancel: "CANCEL",
    btn_confirm: "CONFIRM",
    btn_raise_hand: "RAISE HAND",
    btn_hand_raised: "HAND RAISED",
    toast_completed: "All topics completed!",
    toast_advanced: "Advanced to:",
    toast_recording_start: "Session recording started.",
    toast_recording_saved: "Recording saved to system console.",
    user_names: ["Alex", "Sarah", "Guest_03", "David", "Emily"],
    user_roles: ["moderator", "pro", "anonymous", "pro", "pro"]
  }
};

const TIMER_SECONDS = 10 * 60;
const CIRCLE_CIRC = 2 * Math.PI * 110;

interface ToastMsg {
  id: number;
  text: string;
}

export default function VoiceRoomPage() {
  const params = useParams();
  const router = useRouter();
  const roomId = Number(params.id);

  // States
  const [roomName, setRoomName] = useState("Audio Session");
  const [lang, setLang] = useState("en"); // Room targeted language
  const [activeLang, setActiveLang] = useState("en"); // UI language
  const [users, setUsers] = useState<any[]>(DEFAULT_USERS);
  const [timeRemaining, setTimeRemaining] = useState(TIMER_SECONDS);
  const [sublevelIndex, setSublevelIndex] = useState(0);
  const [isMicOn, setIsMicOn] = useState(true);
  const [isHandRaised, setIsHandRaised] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [showLeaveDialog, setShowLeaveDialog] = useState(false);
  const [toasts, setToasts] = useState<ToastMsg[]>([]);
  const [showGiftDrawer, setShowGiftDrawer] = useState(false);
  const [balance, setBalance] = useState<number>(0);
  const [activeGiftAnim, setActiveGiftAnim] = useState<{ id: number; gift: string }[]>([]);

  // Refs
  const socketRef = useRef<Socket | null>(null);
  const agoraClientRef = useRef<IAgoraRTCClient | null>(null);
  const localAudioTrackRef = useRef<IMicrophoneAudioTrack | null>(null);
  const jwtTokenRef = useRef<string>("");
  const myUidRef = useRef<number>(Math.floor(Math.random() * 10000));

  // Toast System
  const showToast = (text: string) => {
    const id = Date.now();
    setToasts((prev) => [...prev, { id, text }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 3000);
  };

  // Sync active language from localStorage on mount
  useEffect(() => {
    const saved = localStorage.getItem("activeLang");
    if (saved) {
      setActiveLang(saved);
    }
  }, []);

  // Fetch JWT Token & Connect Agora + Socket
  useEffect(() => {
    let isMounted = true;
    const initRealtime = async () => {
      // 1. Fetch JWT from Next.js BFF (Cookie Proxy)
      try {
        const tokenRes = await fetch("/api/auth/token");
        if (tokenRes.ok) {
          const { token } = await tokenRes.json();
          jwtTokenRef.current = token;
        }
      } catch (e) { console.error("Failed to fetch token", e); }

      // Fetch Wallet Balance
      if (jwtTokenRef.current) {
        try {
          const authUrl = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || "http://localhost:5086";
          const balanceRes = await fetch(`${authUrl}/api/wallet/balance`, {
            headers: { "Authorization": `Bearer ${jwtTokenRef.current}` }
          });
          if (balanceRes.ok) {
            const data = await balanceRes.json();
            setBalance(data.balance);
          }
        } catch (e) { console.error("Failed to fetch balance", e); }
      }

      // 2. Fetch Room Info
      let channelName = `Room_${roomId}`;
      try {
        const res = await fetch(`http://localhost:8081/api/v1/rooms/${roomId}`);
        if (res.ok) {
          const data = await res.json();
          channelName = data.agoraChannelName || channelName;
          setRoomName(channelName);
          const roomLang = data.levelId === 2 ? "ja" : data.levelId === 3 ? "zh" : "en";
          setLang(roomLang);
          setActiveLang(roomLang);
          localStorage.setItem("activeLang", roomLang);
        }
      } catch (err) {
        console.warn("Backend content service unavailable, falling back to mock room.");
      }

      // 3. Init Socket.io
      socketRef.current = io(process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3001");
      socketRef.current.on("connect", () => {
        socketRef.current?.emit("join-room", roomId, myUidRef.current);
      });

      socketRef.current.on("speaking-state", (data: { userId: number; speaking: boolean }) => {
        setUsers((prev) => prev.map((u) => (u.id === data.userId ? { ...u, speaking: data.speaking } : u)));
      });

      socketRef.current.on("user-raised-hand", (userId: number) => {
        setUsers((prev) => prev.map((u) => (u.id === userId ? { ...u, handRaised: true } : u)));
        showToast(`User ${userId} raised hand!`);
      });

      socketRef.current.on("receive-gift", (data: any) => {
        showToast(`Gift received! ${data.amount} coins`);
        const animId = Date.now();
        const icon = data.giftType === "car" ? "🏎️" : data.giftType === "rocket" ? "🚀" : "🌹";
        setActiveGiftAnim((prev) => [...prev, { id: animId, gift: icon }]);
        setTimeout(() => setActiveGiftAnim((prev) => prev.filter(g => g.id !== animId)), 3000);
      });

      // 4. Init Agora RTC
      if (!agoraClientRef.current) {
        agoraClientRef.current = AgoraRTC.createClient({ mode: "rtc", codec: "vp8" });
      }
      const client = agoraClientRef.current;

      client.on("user-published", async (user, mediaType) => {
        await client.subscribe(user, mediaType);
        if (mediaType === "audio") {
          user.audioTrack?.play();
          setUsers((prev) => {
            if (!prev.find(u => u.id === user.uid)) {
              return [...prev, { id: user.uid, name: `User_${user.uid}`, role: "guest", mic: true, speaking: false, handRaised: false }];
            }
            return prev;
          });
        }
      });

      client.on("user-unpublished", (user) => {
        setUsers((prev) => prev.filter(u => u.id !== user.uid));
      });

      client.on("token-privilege-will-expire", async () => {
        console.log("Token expiring, renewing...");
        const baseUrl = process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3001";
        const res = await fetch(`${baseUrl}/api/agora/token`, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ channelName, uid: myUidRef.current })
        });
        const data = await res.json();
        await client.renewToken(data.token);
      });

      // Join Channel
      try {
        const baseUrl = process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3001";
        const tokenRes = await fetch(`${baseUrl}/api/agora/token`, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ channelName, uid: myUidRef.current })
        });
        const { token } = await tokenRes.json();
        // Using a dummy appId if env is not set, since the Node backend handles the token generation anyway
        await client.join(process.env.NEXT_PUBLIC_AGORA_APP_ID || "ff0b01c1072940259b3112c3f15c7e18", channelName, token, myUidRef.current);
        
        // Publish mic
        localAudioTrackRef.current = await AgoraRTC.createMicrophoneAudioTrack();
        await client.publish([localAudioTrackRef.current]);
        
        // Add self to users
        setUsers((prev) => {
          if (!prev.find(u => u.id === myUidRef.current)) {
            return [{ id: myUidRef.current, name: "Me", role: "pro", mic: true, speaking: false, handRaised: false }, ...prev.filter(u => u.name !== "Me")];
          }
          return prev;
        });
      } catch (err) {
        console.error("Agora join failed", err);
      }
    };

    initRealtime();

    return () => {
      isMounted = false;
      socketRef.current?.disconnect();
      localAudioTrackRef.current?.close();
      agoraClientRef.current?.leave();
    };
  }, [roomId]);

  // Update dynamic mock users names and roles according to UI language
  useEffect(() => {
    const labels = TRANSLATED_LABELS[activeLang] || TRANSLATED_LABELS.en;
    setUsers((prev) =>
      prev.map((u, idx) => ({
        ...u,
        name: labels.user_names[idx] || u.name,
        role: labels.user_roles[idx] || u.role
      }))
    );
  }, [activeLang]);

  // Timer loop
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeRemaining((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          router.push("/ended");
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [router]);

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  };

  const handleRaiseHand = () => {
    const nextState = !isHandRaised;
    setIsHandRaised(nextState);
    setUsers((prev) =>
      prev.map((u) => (u.id === myUidRef.current ? { ...u, handRaised: nextState } : u))
    );
    socketRef.current?.emit("raise-hand", roomId, myUidRef.current);
  };

  const handleToggleMic = async () => {
    const nextState = !isMicOn;
    setIsMicOn(nextState);
    setUsers((prev) =>
      prev.map((u) => (u.id === myUidRef.current ? { ...u, mic: nextState, speaking: nextState } : u))
    );
    if (localAudioTrackRef.current) {
      await localAudioTrackRef.current.setMuted(!nextState);
    }
    socketRef.current?.emit("speaking", { roomId, speaking: nextState });
  };

  const handleSendGift = (giftType: string, amount: number, icon: string) => {
    setShowGiftDrawer(false);
    
    // Play local animation immediately for perceived performance
    const animId = Date.now();
    setActiveGiftAnim((prev) => [...prev, { id: animId, gift: icon }]);
    setTimeout(() => setActiveGiftAnim((prev) => prev.filter(g => g.id !== animId)), 3000);

    if (!jwtTokenRef.current) {
      showToast("Demo Gift Sent: " + giftType);
      return;
    }
    socketRef.current?.emit("send-gift", roomId, {
      token: jwtTokenRef.current,
      amount: amount,
      receiverUserId: users.find(u => u.id !== myUidRef.current)?.id || 2, // Send to first other user for demo
      giftType: giftType,
      idempotencyKey: Date.now().toString()
    });
    showToast(`Sending ${giftType}...`);
  };

  const handleNextTopic = async () => {
    const labels = TRANSLATED_LABELS[activeLang] || TRANSLATED_LABELS.en;
    const subLevelsList = SUB_LEVELS[activeLang] || SUB_LEVELS.en;
    const nextIndex = sublevelIndex + 1;
    
    if (nextIndex >= subLevelsList.length) {
      router.push("/ended");
      showToast(labels.toast_completed);
    } else {
      setSublevelIndex(nextIndex);
      showToast(`${labels.toast_advanced} ${subLevelsList[nextIndex]}`);

      try {
        await fetch(`http://localhost:8081/api/v1/rooms/${roomId}/current-sub-level?subLevelId=${nextIndex + 1}`, {
          method: "PATCH"
        });
      } catch (err) {
        console.warn("Backend unable to sync sublevel, proceeding in local memory.");
      }
    }
  };

  const handleToggleRecord = () => {
    const labels = TRANSLATED_LABELS[activeLang] || TRANSLATED_LABELS.en;
    const nextState = !isRecording;
    setIsRecording(nextState);
    showToast(nextState ? labels.toast_recording_start : labels.toast_recording_saved);
  };

  const pct = timeRemaining / TIMER_SECONDS;
  const strokeOffset = CIRCLE_CIRC - pct * CIRCLE_CIRC;

  const currentHints = HINTS_BY_LANG[activeLang]?.[sublevelIndex] || [];
  const currentVocab = VOCAB_BY_LANG[activeLang]?.[sublevelIndex] || [];
  const labels = TRANSLATED_LABELS[activeLang] || TRANSLATED_LABELS.en;
  const subLevelsList = SUB_LEVELS[activeLang] || SUB_LEVELS.en;

  return (
    <div className={`flex flex-col h-screen relative overflow-hidden theme-${activeLang || 'en'}`}>
      <CountryThemeBackground lang={lang} />
      
      {/* Toast Notification Container */}
      <div className="toast-container fixed top-8 left-1/2 transform -translate-x-1/2 z-[9999] flex flex-col gap-2 pointer-events-none">
        <AnimatePresence>
          {toasts.map((toast) => (
            <motion.div
              key={toast.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
              className="toast"
            >
              {toast.text}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Nav */}
      <nav className="top-nav">
        <div className="nav-brand">
          LUCY
          <span className="nav-brand-sub">LIVE</span>
        </div>
      </nav>

      {/* Room Grid Layout */}
      <div className="room-grid-layout relative z-10 grid grid-cols-1 lg:grid-cols-[320px_1fr_320px] flex-1 overflow-hidden">
        {/* Left: Active Users */}
        <aside className="sidebar-users border-r border-[var(--border)] p-8 overflow-y-auto bg-[var(--surface)]">
          <div className="sidebar-header flex justify-between font-mono text-[11px] text-[var(--text-muted)] mb-8 tracking-wider">
            <span>{labels.participants}</span>
            <span>[{users.length}]</span>
          </div>

          <div className="user-list flex flex-col gap-4">
            {users.map((u) => (
              <div
                key={u.id}
                className={`user-item flex items-center gap-4 p-3 rounded-2xl border border-transparent transition-all duration-300 ${
                  u.speaking ? "border-[var(--cyan)]/25 bg-[var(--cyan)]/5 speaking-pulse" : ""
                } ${u.handRaised ? "border-[var(--gold)]/25 bg-[var(--gold)]/5" : ""}`}
              >
                <img
                  className={`u-avatar w-10 h-10 rounded-full border-1.5 ${
                    u.speaking
                      ? "border-[var(--cyan)] shadow-[0_0_10px_var(--cyan-glow)]"
                      : u.handRaised
                      ? "border-[var(--gold)] shadow-[0_0_10px_var(--gold-glow)]"
                      : "border-[var(--border)]"
                  }`}
                  src={`https://api.dicebear.com/9.x/notionists/svg?seed=${u.name}`}
                  alt=""
                />
                <div className="u-info flex-1">
                  <div className="u-name text-sm font-semibold">{u.name}</div>
                  <div className="u-role font-mono text-[9px] text-[var(--text-muted)] tracking-wider uppercase">
                    {u.role}
                  </div>
                </div>
                <div className={`u-mic text-lg ${u.mic ? "text-[var(--text-muted)]" : "text-[var(--danger)] drop-shadow-[0_0_8px_var(--danger-glow)]"}`}>
                  {u.mic ? <Microphone size={16} /> : <MicrophoneSlash size={16} />}
                </div>
              </div>
            ))}
          </div>
        </aside>

        {/* Center: Stage */}
        <main className="stage-area flex flex-col items-center justify-center gap-8 relative py-6 overflow-y-auto">
          <div className="stage-header flex flex-col items-center gap-6 w-full">
            <div className="stage-path text-sm font-bold tracking-wider text-[var(--text-main)] uppercase flex items-center gap-4">
              <span className="step-num font-mono text-xs text-[var(--cyan)] drop-shadow-[0_0_8px_var(--cyan-glow)]">
                {sublevelIndex + 1}
              </span>
              <span>{subLevelsList[sublevelIndex]}</span>
            </div>
            <div className="sublevel-progress flex gap-2 w-[240px]">
              {subLevelsList.map((_, i) => (
                <div
                  key={i}
                  className={`prog-step flex-1 h-[3px] rounded-full transition-all duration-300 ${
                    i < sublevelIndex
                      ? "bg-[var(--text-muted)]/40"
                      : i === sublevelIndex
                      ? "bg-[var(--cyan)] shadow-[0_0_12px_var(--cyan-glow)]"
                      : "bg-[var(--border)]"
                  }`}
                />
              ))}
            </div>
          </div>

          <div className="timer-display relative w-[240px] h-[240px] flex justify-center items-center">
            <svg className="timer-ring absolute inset-0 transform -rotate-90 w-full h-full">
              <circle
                className="ring-bg fill-none stroke-[var(--border)] stroke-[1.5]"
                cx="120"
                cy="120"
                r="110"
              />
              <motion.circle
                className="ring-progress fill-none stroke-[var(--cyan)] stroke-[3]"
                cx="120"
                cy="120"
                r="110"
                strokeDasharray={CIRCLE_CIRC}
                animate={{ strokeDashoffset: strokeOffset }}
                transition={{ duration: 1, ease: "linear" }}
              />
            </svg>
            <div className="timer-value text-7xl font-black font-display text-[var(--text-main)] tracking-tighter">
              {formatTime(timeRemaining)}
            </div>
          </div>

          <button
            onClick={handleRaiseHand}
            className={`btn-raise-hand py-4 px-12 font-extrabold text-xs tracking-widest transition-all duration-300 flex items-center gap-2 ${
              isHandRaised
                ? "bg-[var(--gold)] text-white hover:bg-[var(--gold)]/80 hover:shadow-[0_0_30px_var(--gold-glow)] border-transparent"
                : "border border-[var(--cyan)] hover:bg-[var(--cyan)]/8 hover:shadow-[0_0_25px_var(--cyan-glow)] text-[var(--text-main)]"
            }`}
          >
            <HandWaving size={16} />
            {isHandRaised ? labels.btn_hand_raised : labels.btn_raise_hand}
          </button>
        </main>

        {/* Right: Mod Console & Vocab Cards */}
        <aside className="sidebar-mod border-l border-[var(--border)] p-8 overflow-y-auto bg-[var(--surface)] flex flex-col justify-between">
          <div>
            <div className="sidebar-header flex justify-between font-mono text-[11px] text-[var(--text-muted)] mb-8 tracking-wider">
              <span>{labels.console}</span>
              <span className="text-[var(--magenta)] border border-[var(--magenta)]/30 bg-[var(--magenta)]/5 px-2 py-0.5 rounded text-[9px] font-bold">
                {labels.role}
              </span>
            </div>

            <div className="mod-hints flex flex-col gap-3">
              {currentHints.map((hint, i) => (
                <div
                  key={i}
                  className="hint-box bg-[var(--surface-hover)] border border-[var(--border)] p-5 text-[13px] leading-relaxed text-[var(--text-muted)] rounded-2xl"
                >
                  {hint}
                </div>
              ))}
            </div>

            {/* Vocabulary Widget */}
            <div className="vocab-section mt-8">
              <div className="sidebar-header flex justify-between font-mono text-[11px] text-[var(--text-muted)] mb-6 tracking-wider">
                <span>{labels.new_words}</span>
              </div>
              <div className="vocab-list flex flex-col gap-4">
                <AnimatePresence mode="popLayout">
                  {currentVocab.map((w) => (
                    <motion.div
                      key={w.word}
                      initial={{ opacity: 0, x: 20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -20 }}
                      transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                      className="vocab-card p-4 bg-[var(--surface)] hover:translate-x-1 transition-all duration-300 cursor-pointer"
                    >
                      <div className="vocab-word-row flex flex-wrap items-center gap-2 mb-1.5">
                        <span className="vocab-word font-display font-extrabold text-[15px] text-[var(--cyan)]">
                          {w.word}
                        </span>
                        <span className="vocab-type font-mono text-[9px] font-bold text-[var(--magenta)] border border-[var(--magenta)]/25 px-1.5 py-0.5 rounded bg-[var(--magenta)]/5 uppercase">
                          {w.type}
                        </span>
                        <span className="vocab-ipa font-mono text-[11px] text-[var(--text-muted)]">
                          {w.ipa}
                        </span>
                      </div>
                      <div className="vocab-definition text-[13px] text-[var(--text-main)] leading-relaxed">
                        {w.definition}
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>
            </div>
          </div>

          <div className="mod-actions flex flex-col gap-3 mt-10">
            <button
              onClick={handleNextTopic}
              className="btn-mod-action bg-[var(--cyan)] text-white font-extrabold text-[11px] py-4 tracking-wider uppercase hover:bg-[var(--cyan)]/80 hover:shadow-[0_0_20px_var(--cyan-glow)] transition-all duration-300"
            >
              {labels.btn_next}
            </button>
            <button
              onClick={handleToggleRecord}
              className={`btn-mod-action py-4 font-extrabold text-[11px] tracking-wider uppercase border transition-all duration-300 ${
                isRecording
                  ? "border-[var(--danger)] text-[var(--danger)] bg-[var(--danger)]/5"
                  : "border-[var(--border)] text-[var(--text-main)] hover:bg-[var(--surface)]"
              }`}
            >
              {isRecording ? labels.btn_recording : labels.btn_record}
            </button>
          </div>
        </aside>
      </div>

      {/* Bottom Control Bar */}
      <div className="bottom-control-bar relative z-20 h-[90px] flex justify-between items-center px-12 border-t border-[var(--border)] bg-[var(--surface)]/80 backdrop-blur-md">
        <div className="bar-left flex items-center gap-5 font-mono text-xs text-[var(--text-muted)]">
          <span className="room-id font-bold text-[var(--text-main)]">{roomName}</span>
          <span className="room-status-dot w-2 h-2 rounded-full bg-[var(--magenta)] shadow-[0_0_10px_var(--magenta-glow)]" />
          <span className="users-mini">[{users.length}]</span>
        </div>

        <div className="bar-center flex items-center justify-center">
          <button
            onClick={handleToggleMic}
            className={`btn-mic w-14 h-14 flex items-center justify-center text-2xl transition-all duration-300 ${
              isMicOn
                ? "bg-[var(--cyan)] text-white shadow-[0_0_20px_var(--cyan-glow)] hover:scale-105"
                : "bg-[var(--danger)]/10 text-[var(--danger)] border border-[var(--danger)] shadow-[0_0_20px_var(--danger-glow)] hover:scale-105"
            }`}
          >
            {isMicOn ? <Microphone weight="fill" /> : <MicrophoneSlash weight="fill" />}
          </button>
          
          <div className="relative">
            <button
              onClick={() => setShowGiftDrawer(!showGiftDrawer)}
              className={`btn-gift w-14 h-14 ml-4 flex items-center justify-center text-2xl transition-all duration-300 rounded-full ${
                showGiftDrawer 
                  ? "bg-[var(--gold)] text-white shadow-[0_0_25px_var(--gold-glow)] scale-110" 
                  : "bg-[var(--gold)]/10 text-[var(--gold)] border border-[var(--gold)] shadow-[0_0_20px_var(--gold-glow)] hover:scale-105"
              }`}
              title="Send Gift"
            >
              <Gift weight="fill" />
            </button>
            
            {/* Gift Selection Drawer */}
            <AnimatePresence>
              {showGiftDrawer && (
                <motion.div
                  initial={{ opacity: 0, y: 20, scale: 0.9 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 10, scale: 0.95 }}
                  className="absolute bottom-[80px] left-1/2 -translate-x-1/2 w-[300px] bg-[var(--surface)]/95 backdrop-blur-xl border border-[var(--border)] p-4 rounded-3xl shadow-[0_0_40px_rgba(0,0,0,0.5)] flex flex-col gap-3"
                >
                  <div className="flex justify-between items-center mb-2">
                    <div className="font-bold text-xs text-[var(--text-muted)] tracking-widest uppercase">Send a Gift</div>
                    <div className="text-xs font-bold text-[var(--gold)]">Balance: {balance} Coins</div>
                  </div>
                  <div className="grid grid-cols-3 gap-3">
                    <button onClick={() => handleSendGift("flower", 10, "🌹")} className="flex flex-col items-center p-3 rounded-2xl hover:bg-[var(--gold)]/10 border border-transparent hover:border-[var(--gold)]/30 transition-all group">
                      <span className="text-4xl group-hover:scale-110 transition-transform mb-2">🌹</span>
                      <span className="text-[10px] font-bold text-[var(--gold)]">10 Coins</span>
                    </button>
                    <button onClick={() => handleSendGift("car", 100, "🏎️")} className="flex flex-col items-center p-3 rounded-2xl hover:bg-[var(--gold)]/10 border border-transparent hover:border-[var(--gold)]/30 transition-all group">
                      <span className="text-4xl group-hover:scale-110 transition-transform mb-2">🏎️</span>
                      <span className="text-[10px] font-bold text-[var(--gold)]">100 Coins</span>
                    </button>
                    <button onClick={() => handleSendGift("rocket", 500, "🚀")} className="flex flex-col items-center p-3 rounded-2xl hover:bg-[var(--gold)]/10 border border-transparent hover:border-[var(--gold)]/30 transition-all group">
                      <span className="text-4xl group-hover:scale-110 transition-transform mb-2">🚀</span>
                      <span className="text-[10px] font-bold text-[var(--gold)]">500 Coins</span>
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>

        <div className="bar-right">
          <button
            onClick={() => setShowLeaveDialog(true)}
            className="btn-leave font-extrabold text-[12px] tracking-wider text-[var(--text-muted)] hover:text-[var(--danger)] transition-colors"
          >
            {labels.btn_leave}
          </button>
        </div>
      </div>

      {/* Leave Dialog */}
      
      {/* Gift Animations Overlay */}
      <div className="fixed inset-0 pointer-events-none z-[9999] overflow-hidden">
        <AnimatePresence>
          {activeGiftAnim.map((anim) => (
            <motion.div
              key={anim.id}
              initial={{ opacity: 0, y: "100vh", x: "50vw", scale: 0.5 }}
              animate={{ 
                opacity: [0, 1, 1, 0], 
                y: "-10vh", 
                x: ["50vw", "45vw", "55vw", "50vw"],
                scale: [0.5, 2.5, 3.5, 4]
              }}
              exit={{ opacity: 0 }}
              transition={{ duration: 3, ease: "easeOut" }}
              className="absolute text-[100px] drop-shadow-[0_0_30px_var(--gold-glow)]"
            >
              {anim.gift}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
      {showLeaveDialog && (
        <div className="dialog-overlay active">
          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="dialog-box p-12 bg-[var(--bg)] shadow-[0_20px_50px_rgba(15,23,42,0.15)] w-[440px]"
          >
            <h3 className="text-[28px] font-black text-[var(--danger)] mb-4">
              {labels.disconnect}
            </h3>
            <p className="text-[var(--text-muted)] text-[15px] leading-relaxed mb-10">
              {labels.disconnect_desc}
            </p>
            <div className="dialog-btns flex gap-4">
              <button
                onClick={() => setShowLeaveDialog(false)}
                className="btn-ghost py-4 flex-1 text-xs font-bold tracking-wider"
              >
                {labels.btn_cancel}
              </button>
              <button
                onClick={() => router.push("/ended")}
                className="btn-leave-confirm py-4 flex-1 text-xs font-extrabold tracking-wider bg-[var(--danger)] text-white shadow-[0_0_15px_var(--danger-glow)] hover:bg-[var(--danger)]/80"
              >
                {labels.btn_confirm}
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
