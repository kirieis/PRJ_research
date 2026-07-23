"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Vui lòng điền đầy đủ email và mật khẩu.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { 
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "69420"
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản.");
      } else {
        router.push("/");
      }
    } catch (err) {
      setError("Lỗi kết nối mạng. Vui lòng kiểm tra lại server.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAFAFA] flex flex-col justify-between font-sans">
      {/* Top Nav */}
      <nav className="flex justify-between items-center px-8 py-6 border-b border-[#E5E5E5] bg-white z-10">
        <div className="flex items-center gap-2">
          <span className="font-extrabold text-2xl tracking-tighter text-[#111]">LUCY</span>
          <span className="text-[10px] font-bold tracking-widest text-[#B33939] uppercase mt-1">
            ARCHIVE
          </span>
        </div>
        <button
          onClick={() => router.push("/")}
          className="text-xs font-bold text-[#666] hover:text-[#111] transition-colors tracking-widest uppercase"
        >
          ← VỀ TRANG CHỦ
        </button>
      </nav>

      {/* Main Container */}
      <main className="flex-1 flex items-center justify-center p-6 z-10 my-8">
        <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          
          {/* Left Side: Branding */}
          <div className="space-y-6">
            <h1 className="text-7xl lg:text-[7rem] font-black tracking-tighter leading-[0.75] font-[var(--font-instrument)] uppercase">
              <span className="text-[#111] block mb-2">SPEAK</span>
              <span className="text-[#A63A2E] block">WITHOUT FEAR.</span>
            </h1>
            <p className="text-[#666] text-lg max-w-md leading-relaxed mt-8">
              Anonymous, high-fidelity language practice rooms.<br />
              Join an active session below.
            </p>
          </div>

          {/* Right Side: Light Login Card */}
          <div className="bg-white border border-[#E5E5E5] rounded-xl p-8 lg:p-10 shadow-[0_8px_30px_rgb(0,0,0,0.04)] relative">
            <div className="mb-8">
              <h2 className="text-2xl font-bold tracking-tight text-[#111] mb-2 font-[var(--font-instrument)]">Đăng Nhập</h2>
              <p className="text-xs font-sans text-[#666] uppercase tracking-widest">Nhập tài khoản của bạn để tiếp tục</p>
            </div>

            {error && (
              <div className="mb-6 p-4 rounded-xl bg-[#FFF0F0] border border-[#FFD6D6] text-[#D93025] text-sm font-medium">
                {error}
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-5">
              <div>
                <label className="block text-xs font-bold text-[#111] uppercase tracking-wider mb-2">
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="w-full px-4 py-3.5 bg-[#F9F9F9] border border-[#E5E5E5] rounded-md text-[#111] placeholder-[#999] focus:outline-none focus:border-[#111] focus:ring-1 focus:ring-[#111] transition-all text-sm"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#111] uppercase tracking-wider mb-2">
                  Mật khẩu
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full px-4 py-3.5 bg-[#F9F9F9] border border-[#E5E5E5] rounded-md text-[#111] placeholder-[#999] focus:outline-none focus:border-[#111] focus:ring-1 focus:ring-[#111] transition-all text-sm pr-16"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-[#666] hover:text-[#111] transition-colors"
                  >
                    {showPassword ? "ẨN" : "HIỆN"}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-4 bg-[#111] hover:bg-black text-white font-bold text-xs tracking-widest uppercase rounded-md transition-all active:scale-[0.99] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 mt-4"
              >
                {loading ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  "ĐĂNG NHẬP"
                )}
              </button>
            </form>

            <div className="mt-8 text-center text-xs text-[#666]">
              Chưa có tài khoản?{" "}
              <a href="/register" className="text-[#A63A2E] font-bold hover:underline ml-1">
                Đăng ký ngay
              </a>
            </div>
          </div>

        </div>
      </main>

      {/* Footer */}
      <footer className="px-8 py-6 border-t border-[#E5E5E5] bg-white text-center text-xs font-bold tracking-widest text-[#999] relative z-10">
        LUCY ARCHIVE SYSTEM © 2026
      </footer>
    </div>
  );
}
