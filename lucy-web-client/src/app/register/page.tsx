"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";

export default function RegisterPage() {
  const router = useRouter();
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password || !displayName) {
      setError("Please fill in all fields.");
      return;
    }
    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }

    setLoading(true);
    setError("");
    setSuccessMsg("");

    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, displayName }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Registration failed.");
      } else {
        setSuccessMsg("Account created! Redirecting to login...");
        setTimeout(() => {
          router.push("/login");
        }, 1500);
      }
    } catch (err) {
      setError("Network error. Make sure the backend is running.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: "#FBFBFA",
      fontFamily: "var(--font-body), sans-serif",
      color: "#111111",
      display: "flex",
      flexDirection: "column",
      position: "relative",
    }}>
      {/* Top Nav */}
      <nav style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "20px 48px",
        borderBottom: "1px solid #EAEAEA",
        background: "rgba(251, 251, 250, 0.85)",
        backdropFilter: "blur(20px)",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <span style={{
            fontFamily: "var(--font-display), serif",
            fontWeight: 900,
            fontSize: "20px",
            letterSpacing: "-0.03em",
          }}>
            LUCY
          </span>
          <span style={{
            fontFamily: "var(--font-mono), monospace",
            fontSize: "10px",
            color: "#9F2F2D",
            letterSpacing: "0.15em",
            fontWeight: "bold",
          }}>
            ARCHIVE
          </span>
        </div>
      </nav>

      {/* Main Container */}
      <main style={{
        flex: 1,
        display: "grid",
        gridTemplateColumns: "1.1fr 0.9fr",
        maxWidth: "1200px",
        width: "100%",
        margin: "0 auto",
        padding: "60px 48px",
        gap: "80px",
        alignItems: "center",
      }} className="grid-cols-1 lg:grid-cols-2">
        
        {/* Left Side: Editorial Typography - Exact match to Lobby */}
        <div style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          >
            <h1 style={{
              fontFamily: "var(--font-display), serif",
              fontSize: "76px",
              fontWeight: 900,
              lineHeight: 0.9,
              letterSpacing: "-0.04em",
              marginBottom: "32px",
            }}>
              JOIN<br />
              <span style={{ color: "#9F2F2D", fontStyle: "italic" }}>THE</span><br />
              SESSION.
            </h1>
            <p style={{
              fontSize: "15px",
              color: "#787774",
              lineHeight: 1.6,
              maxWidth: "380px",
            }}>
              Create your account to unlock real-time language practice rooms and start speaking with learners worldwide.
            </p>
          </motion.div>
        </div>

        {/* Right Side: Clean Form Card */}
        <div style={{ display: "flex", justifyContent: "center" }}>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1], delay: 0.1 }}
            style={{
              width: "100%",
              maxWidth: "400px",
              background: "#ffffff",
              border: "1px solid #EAEAEA",
              borderRadius: "12px",
              padding: "40px",
              boxShadow: "0 4px 20px rgba(0,0,0,0.02)",
            }}
          >
            <h2 style={{
              fontFamily: "var(--font-display), serif",
              fontSize: "24px",
              fontWeight: 900,
              letterSpacing: "-0.02em",
              marginBottom: "6px",
            }}>
              Sign Up
            </h2>
            <p style={{
              fontFamily: "var(--font-mono), monospace",
              fontSize: "10px",
              color: "#787774",
              textTransform: "uppercase",
              letterSpacing: "0.1em",
              marginBottom: "28px",
            }}>
              Create your account
            </p>

            {error && (
              <motion.div
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                style={{
                  marginBottom: "20px",
                  padding: "12px 14px",
                  background: "rgba(159, 47, 45, 0.05)",
                  border: "1px solid rgba(159, 47, 45, 0.2)",
                  borderRadius: "6px",
                  color: "#9F2F2D",
                  fontSize: "13px",
                  fontWeight: 600,
                }}
              >
                {error}
              </motion.div>
            )}

            {successMsg && (
              <motion.div
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                style={{
                  marginBottom: "20px",
                  padding: "12px 14px",
                  background: "rgba(22, 163, 74, 0.05)",
                  border: "1px solid rgba(22, 163, 74, 0.2)",
                  borderRadius: "6px",
                  color: "#16a34a",
                  fontSize: "13px",
                  fontWeight: 600,
                  textAlign: "center",
                }}
              >
                {successMsg}
              </motion.div>
            )}

            <form onSubmit={handleRegister} style={{ display: "flex", flexDirection: "column", gap: "18px" }}>
              <div>
                <label style={{
                  display: "block",
                  fontFamily: "var(--font-mono), monospace",
                  fontSize: "10px",
                  fontWeight: 700,
                  color: "#787774",
                  textTransform: "uppercase",
                  letterSpacing: "0.1em",
                  marginBottom: "8px",
                }}>
                  Display Name
                </label>
                <input
                  type="text"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="John Doe"
                  style={{
                    width: "100%",
                    padding: "12px 14px",
                    background: "#ffffff",
                    border: "1px solid #EAEAEA",
                    borderRadius: "6px",
                    outline: "none",
                    color: "#111111",
                    fontSize: "14px",
                    transition: "border-color 0.2s",
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "#111111";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "#EAEAEA";
                  }}
                />
              </div>

              <div>
                <label style={{
                  display: "block",
                  fontFamily: "var(--font-mono), monospace",
                  fontSize: "10px",
                  fontWeight: 700,
                  color: "#787774",
                  textTransform: "uppercase",
                  letterSpacing: "0.1em",
                  marginBottom: "8px",
                }}>
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  style={{
                    width: "100%",
                    padding: "12px 14px",
                    background: "#ffffff",
                    border: "1px solid #EAEAEA",
                    borderRadius: "6px",
                    outline: "none",
                    color: "#111111",
                    fontSize: "14px",
                    transition: "border-color 0.2s",
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "#111111";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "#EAEAEA";
                  }}
                />
              </div>

              <div>
                <label style={{
                  display: "block",
                  fontFamily: "var(--font-mono), monospace",
                  fontSize: "10px",
                  fontWeight: 700,
                  color: "#787774",
                  textTransform: "uppercase",
                  letterSpacing: "0.1em",
                  marginBottom: "8px",
                }}>
                  Password
                </label>
                <div style={{ position: "relative" }}>
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Min 8 characters"
                    style={{
                      width: "100%",
                      padding: "12px 50px 12px 14px",
                      background: "#ffffff",
                      border: "1px solid #EAEAEA",
                      borderRadius: "6px",
                      outline: "none",
                      color: "#111111",
                      fontSize: "14px",
                      transition: "border-color 0.2s",
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = "#111111";
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = "#EAEAEA";
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: "absolute",
                      right: "12px",
                      top: "50%",
                      transform: "translateY(-50%)",
                      background: "none",
                      border: "none",
                      color: "#787774",
                      cursor: "pointer",
                      fontSize: "10px",
                      fontWeight: 700,
                      letterSpacing: "0.05em",
                    }}
                  >
                    {showPassword ? "HIDE" : "SHOW"}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                style={{
                  width: "100%",
                  height: "46px",
                  marginTop: "8px",
                  background: "#111111",
                  color: "#ffffff",
                  border: "none",
                  borderRadius: "6px",
                  fontSize: "12px",
                  fontWeight: 700,
                  letterSpacing: "0.08em",
                  cursor: loading ? "not-allowed" : "pointer",
                  opacity: loading ? 0.7 : 1,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  transition: "background 0.2s, transform 0.1s",
                }}
                onMouseEnter={(e) => {
                  if (!loading) e.currentTarget.style.background = "#222222";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = "#111111";
                }}
                onMouseDown={(e) => {
                  if (!loading) e.currentTarget.style.transform = "scale(0.98)";
                }}
                onMouseUp={(e) => {
                  e.currentTarget.style.transform = "scale(1)";
                }}
              >
                {loading ? (
                  <div style={{
                    width: "18px",
                    height: "18px",
                    border: "2px solid rgba(255,255,255,0.3)",
                    borderTopColor: "#fff",
                    borderRadius: "50%",
                    animation: "spin 0.6s linear infinite",
                  }} />
                ) : "CREATE ACCOUNT"}
              </button>
            </form>

            <div style={{
              marginTop: "24px",
              textAlign: "center",
              fontSize: "12px",
              color: "#787774",
            }}>
              Already have an account?{" "}
              <a
                href="/login"
                style={{
                  color: "#9F2F2D",
                  fontWeight: 700,
                  textDecoration: "none",
                }}
              >
                Sign In
              </a>
            </div>
          </motion.div>
        </div>

      </main>

      {/* Styled JSX for keyframe spin */}
      <style jsx global>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        @media (max-width: 1024px) {
          main {
            grid-template-columns: 1fr !important;
            text-align: center;
            gap: 40px !important;
            padding: 40px 24px !important;
          }
          main > div:first-child h1 {
            font-size: 56px !important;
          }
          main > div:first-child p {
            margin: 0 auto !important;
          }
        }
      `}</style>
    </div>
  );
}
