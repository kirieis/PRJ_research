import re

with open('assets/css/styles.css', 'r', encoding='utf-8') as f:
    css = f.read()

# Replace :root block with upgraded tokens
new_root = """:root {
  --bg-deepest: #0a0a0a;
  --bg-base: #111111;
  --bg-surface: #18181b;
  --bg-elevated: #27272a;
  --bg-glass: rgba(24, 24, 27, 0.65);
  --border-subtle: rgba(255, 255, 255, 0.08);
  --border-focus: rgba(0, 201, 167, 0.5);
  --teal: #00C9A7;
  --teal-dim: #00A896;
  --teal-glow: rgba(0, 201, 167, 0.25);
  --teal-surface: rgba(0, 201, 167, 0.08);
  --gold: #F4A435;
  --gold-warm: #FFBA5C;
  --gold-surface: rgba(244, 164, 53, 0.10);
  --danger: #ef4444;
  --danger-deep: #dc2626;
  --danger-surface: rgba(239, 68, 68, 0.10);
  --text-primary: #F1F5F9;
  --text-secondary: #94A3B8;
  --text-muted: #71717a;
  --white: #FFFFFF;
  --font-display: 'Outfit', sans-serif;
  --font-body: 'Be Vietnam Pro', sans-serif;
  --s1: 4px; --s2: 8px; --s3: 12px; --s4: 16px;
  --s5: 20px; --s6: 24px; --s7: 32px; --s8: 40px;
  --s9: 48px; --s10: 64px;
  --r-sm: 8px; --r-md: 14px; --r-lg: 20px; --r-xl: 28px; --r-full: 9999px;
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.5), 0 1px 2px rgba(0,0,0,0.3);
  --shadow-md: 0 4px 12px rgba(0,0,0,0.6);
  --shadow-lg: 0 12px 32px rgba(0,0,0,0.8);
  --shadow-xl: 0 24px 48px rgba(0,0,0,0.9);
  --glow-teal: 0 0 40px rgba(0, 201, 167, 0.15);
  --glow-gold: 0 0 30px rgba(244, 164, 53, 0.15);
  --glow-danger: 0 0 20px rgba(248, 113, 113, 0.2);
  --inset-glow: inset 0 1px 0 rgba(255,255,255,0.02);
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-smooth: cubic-bezier(0.4, 0, 0.2, 1);
  --dur-fast: 150ms;
  --dur-normal: 250ms;
  --dur-slow: 400ms;
}"""

css = re.sub(r':root\s*\{.*?\n    \}', new_root, css, flags=re.DOTALL)

with open('assets/css/styles.css', 'w', encoding='utf-8') as f:
    f.write(css)

# Update JS with GSAP
with open('assets/js/main.js', 'r', encoding='utf-8') as f:
    js = f.read()

# Add GSAP screen transitions
js_gsap = """
// GSAP Integrations
function animateScreenIn(screenEl) {
    gsap.fromTo(screenEl, 
        { opacity: 0, y: 20 }, 
        { opacity: 1, y: 0, duration: 0.6, ease: "power3.out" }
    );
}

function animateLobbyCards() {
    gsap.fromTo(".room-card", 
        { opacity: 0, y: 30 }, 
        { opacity: 1, y: 0, duration: 0.5, stagger: 0.05, ease: "back.out(1.2)" }
    );
}

function animateUsers() {
    gsap.fromTo(".user-item", 
        { opacity: 0, x: -20 }, 
        { opacity: 1, x: 0, duration: 0.4, stagger: 0.05, ease: "power2.out" }
    );
}
"""

js = js.replace("el.screenLobby.classList.remove('hidden');\n        renderLobbyRooms();", "el.screenLobby.classList.remove('hidden');\n        renderLobbyRooms();\n        animateScreenIn(el.screenLobby);\n        animateLobbyCards();")
js = js.replace("el.screenRoom.classList.remove('hidden');\n        initRoom();", "el.screenRoom.classList.remove('hidden');\n        initRoom();\n        animateScreenIn(el.screenRoom);\n        animateUsers();")

with open('assets/js/main.js', 'w', encoding='utf-8') as f:
    f.write(js + "\n" + js_gsap)

print("CSS and JS upgraded.")
