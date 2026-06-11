# Design System: LUCY (Language Unity & Collaborative Youth)

## 1. Visual Theme & Atmosphere
A restrained, gallery-airy interface with confident asymmetric layouts and fluid spring-physics motion. The atmosphere is clinical yet warm—like a well-lit architecture studio. It uses a Premium Dark mode to reduce visual strain and create a "safe zone" for anonymous language learners.

## 2. Color Palette & Roles
- **Canvas Charcoal** (#0a0a0a) — Primary background surface (Off-black)
- **Glass Surface** (rgba(24, 38, 64, 0.4)) — Card and container fill with blur
- **Starlight White** (#F1F5F9) — Primary text
- **Muted Steel** (#94A3B8) — Secondary text, descriptions, metadata
- **Whisper Border** (rgba(148, 163, 184, 0.08)) — Card borders, 1px structural lines
- **Trust Teal** (#00C9A7) — Single accent for CTAs, active states, focus rings, waveforms

## 3. Typography Rules
- **Display:** Outfit — Track-tight, controlled scale, weight-driven hierarchy
- **Body:** Be Vietnam Pro — Relaxed leading, 65ch max-width, neutral secondary color
- **Mono:** JetBrains Mono — For timer numbers, metadata, timestamps, high-density numbers
- **Banned:** Inter, generic system fonts for premium contexts. Serif fonts banned in dashboards.

## 4. Component Stylings
* **Buttons:** Flat, no outer glow. Tactile -1px translate on active. Teal fill for primary, ghost/outline for secondary.
* **Cards:** Generously rounded corners (1.5rem). Diffused whisper shadow. Used only when elevation serves hierarchy. High-density: replace with border-top dividers.
* **Inputs:** Label above, error below. Focus ring in accent color. No floating labels.
* **Loaders:** Skeletal shimmer matching exact layout dimensions. No circular spinners.
* **Avatars & Waveforms:** Speaking state triggers a teal 1px border and a smooth hardware-accelerated SVG waveform.

## 5. Layout Principles
Grid-first responsive architecture. Asymmetric splits for Hero sections.
Strict single-column collapse below 768px. Max-width containment (1280px).
No flexbox percentage math. Generous internal padding.
Gapless bento grids for high-density elements.

## 6. Motion & Interaction
Spring physics for all interactive elements. Staggered cascade reveals.
Perpetual micro-loops on active dashboard components (e.g., Live Timer glow, Waveform pulsing). Hardware-accelerated transforms only (opacity, transform). 
Isolated Client Components for CPU-heavy animations.

## 7. Anti-Patterns (Banned)
- No emojis anywhere
- No Inter font
- No generic serif fonts (Times New Roman, Georgia, Garamond)
- No pure black (#000000)
- No neon/outer glow shadows
- No oversaturated accents
- No excessive gradient text on large headers
- No custom mouse cursors
- No overlapping elements — clean spatial separation always
- No 3-column equal card layouts
- No generic names ("John Doe", "Acme", "Nexus")
- No fake round numbers (99.99%, 50%)
- No AI copywriting clichés ("Elevate", "Seamless", "Unleash", "Next-Gen")
- No filler UI text: "Scroll to explore", "Swipe down"
- No centered Hero sections (for high-variance projects)
