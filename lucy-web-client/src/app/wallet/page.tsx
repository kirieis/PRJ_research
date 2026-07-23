"use client";
/* eslint-disable */

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Wallet, QrCode, ArrowLeft, Coin, Copy, CheckCircle } from "@phosphor-icons/react";

// Thay đổi thông tin ngân hàng của bạn ở đây!
const MY_BANK_BIN = "970422"; // MB Bank
const MY_ACCOUNT_NO = "3399377355"; // Điền số tài khoản của bạn
const MY_ACCOUNT_NAME = "NGUYEN TRI THIEN"; // Tên chủ tài khoản

const PACKAGES = [
  { id: "pack1", amount: 10000, coins: 100 },
  { id: "pack2", amount: 20000, coins: 200 },
  { id: "pack3", amount: 50000, coins: 500 },
  { id: "pack4", amount: 100000, coins: 1000 },
  { id: "pack5", amount: 500000, coins: 5000 },
];

export default function WalletPage() {
  const router = useRouter();
  const [userId, setUserId] = useState<number>(2); // Mặc định ID 2, có thể lấy từ token
  const [selectedAmount, setSelectedAmount] = useState<number>(10000);
  const [copied, setCopied] = useState(false);
  const [balance, setBalance] = useState<number>(0);

  // Load cached balance & parse token từ cookie để lấy ID thật nếu có
  useEffect(() => {
    const cachedBalance = localStorage.getItem("lucy_user_balance");
    if (cachedBalance !== null) {
      setBalance(parseInt(cachedBalance, 10) || 0);
    }

    const cookies = document.cookie.split("; ");
    const tokenCookie = cookies.find(c => c.startsWith("lucy_token="));
    if (tokenCookie) {
      const token = tokenCookie.split("=")[1];
      try {
        const payload = JSON.parse(atob(token.split(".")[1]));
        if (payload.nameid) setUserId(parseInt(payload.nameid, 10));
      } catch (e) {
        console.error("Could not parse token");
      }
    }
  }, []);

  // Poll balance
  useEffect(() => {
    const fetchBalance = async () => {
      try {
        const cookies = document.cookie.split("; ");
        const tokenCookie = cookies.find(c => c.startsWith("lucy_token="));
        if (!tokenCookie) return;
        const token = tokenCookie.split("=")[1];

        const baseUrl = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || "";
        const res = await fetch(`${baseUrl}/api/wallet/balance`, {
          headers: {
            "Authorization": `Bearer ${token}`,
            "ngrok-skip-browser-warning": "69420"
          }
        });
        if (res.ok) {
          const data = await res.json();
          const newBal = typeof data.balance === "number" ? data.balance : 0;
          setBalance(newBal);
          localStorage.setItem("lucy_user_balance", newBal.toString());
        }
      } catch (e) {
        // ignore
      }
    };
    
    fetchBalance();
    const interval = setInterval(fetchBalance, 3000);

    // Listen for instant real-time socket update from SePay Webhook
    const handleRealtimeBalance = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      if (detail && typeof detail.newBalance === "number") {
        setBalance(detail.newBalance);
        localStorage.setItem("lucy_user_balance", detail.newBalance.toString());
      }
    };
    window.addEventListener("lucy_balance_updated", handleRealtimeBalance);

    return () => {
      clearInterval(interval);
      window.removeEventListener("lucy_balance_updated", handleRealtimeBalance);
    };
  }, [userId]);

  const transferContent = `LUCY ${userId}`;
  const qrUrl = `https://img.vietqr.io/image/${MY_BANK_BIN}-${MY_ACCOUNT_NO}-compact2.png?amount=${selectedAmount}&addInfo=${encodeURIComponent(transferContent)}&accountName=${encodeURIComponent(MY_ACCOUNT_NAME)}`;

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-screen bg-[var(--background)] flex flex-col items-center p-4 lg:p-12 relative overflow-hidden">
      {/* Background elements */}
      <div className="absolute top-[-10%] right-[-5%] w-96 h-96 bg-[var(--cyan)] rounded-full mix-blend-screen filter blur-[150px] opacity-20 animate-pulse-slow"></div>
      <div className="absolute bottom-[-10%] left-[-5%] w-96 h-96 bg-[var(--magenta)] rounded-full mix-blend-screen filter blur-[150px] opacity-20 animate-pulse-slow delay-1000"></div>

      {/* Header */}
      <div className="w-full max-w-4xl flex items-center justify-between mb-8 z-10">
        <button 
          onClick={() => router.push("/")}
          className="flex items-center gap-2 text-white/70 hover:text-white transition-colors p-2 rounded-xl hover:bg-white/5"
        >
          <ArrowLeft size={20} weight="bold" />
          <span className="font-semibold tracking-wide text-sm uppercase">Quay lại</span>
        </button>
        <div className="flex items-center gap-3 bg-[#0f111a]/80 px-6 py-3 rounded-2xl border border-[var(--gold)]/30 backdrop-blur-xl shadow-[0_0_15px_rgba(251,191,36,0.15)]">
          <Wallet size={24} weight="duotone" className="text-[var(--gold)] drop-shadow-[0_0_6px_rgba(251,191,36,0.6)]" />
          <div>
            <div className="text-[10px] text-white/60 uppercase font-bold tracking-widest">Số dư hiện tại</div>
            <div className="font-mono text-xl font-extrabold text-white flex items-center gap-1.5">
              {balance.toLocaleString()} <span className="text-[var(--gold)] text-sm font-bold bg-[var(--gold)]/10 px-2 py-0.5 rounded-full border border-[var(--gold)]/30">Xu</span>
            </div>
          </div>
        </div>
      </div>

      <div className="w-full max-w-4xl grid grid-cols-1 lg:grid-cols-2 gap-8 z-10">
        {/* Left Col: Packages */}
        <div className="flex flex-col gap-6">
          <div>
            <h1 className="text-3xl font-extrabold bg-gradient-to-r from-white via-white to-[var(--gold)] bg-clip-text text-transparent mb-2 tracking-tight">Nạp Xu</h1>
            <p className="text-white/70 text-sm">Chọn mệnh giá bạn muốn nạp. Tỷ giá quy đổi: 100 VND = 1 Xu.</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            {PACKAGES.map((pkg) => (
              <motion.div
                key={pkg.id}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => setSelectedAmount(pkg.amount)}
                className={`cursor-pointer p-5 rounded-2xl border transition-all duration-300 flex flex-col gap-3 relative overflow-hidden backdrop-blur-xl ${
                  selectedAmount === pkg.amount 
                    ? "bg-gradient-to-br from-[var(--cyan)]/25 via-[var(--magenta)]/20 to-[var(--gold)]/25 border-[var(--gold)] shadow-[0_0_25px_rgba(251,191,36,0.35)]" 
                    : "bg-[#0f111a]/80 border-white/15 hover:border-[var(--gold)]/50 hover:bg-[#161929]"
                }`}
              >
                {selectedAmount === pkg.amount && (
                  <div className="absolute inset-0 bg-gradient-to-br from-[var(--cyan)]/20 via-transparent to-[var(--gold)]/20 pointer-events-none"></div>
                )}
                
                <div className="flex justify-between items-start relative z-10">
                  <div className="flex items-center justify-center w-10 h-10 rounded-xl bg-[var(--gold)]/15 border border-[var(--gold)]/30 text-[var(--gold)] shadow-inner">
                    <Coin size={24} weight="duotone" className="text-[var(--gold)] drop-shadow-[0_0_6px_rgba(251,191,36,0.8)]" />
                  </div>
                  {selectedAmount === pkg.amount && (
                    <CheckCircle size={24} weight="fill" className="text-[var(--gold)] drop-shadow-[0_0_8px_rgba(251,191,36,0.8)]" />
                  )}
                </div>

                <div className="relative z-10">
                  <div className="text-2xl font-black text-white tracking-tight flex items-baseline gap-1">
                    {pkg.coins} <span className="text-sm font-bold text-[var(--gold)]">Xu</span>
                  </div>
                  <div className="text-[var(--cyan)] text-sm font-mono font-bold mt-1">{pkg.amount.toLocaleString()} VND</div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Right Col: Payment Info & QR */}
        <div className="bg-black/40 backdrop-blur-xl border border-white/10 rounded-3xl p-8 flex flex-col items-center relative shadow-2xl">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-[var(--cyan)] via-[var(--magenta)] to-[var(--cyan)] opacity-50"></div>
          
          <div className="flex items-center gap-3 mb-6 w-full justify-center">
            <QrCode size={28} weight="duotone" className="text-[var(--cyan)]" />
            <h2 className="text-xl font-bold text-white tracking-wide">Quét mã thanh toán</h2>
          </div>

          <div className="bg-white p-4 rounded-2xl shadow-xl mb-8 group relative transition-transform hover:scale-105 duration-500">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img 
              src={qrUrl} 
              alt="QR Code" 
              className="w-64 h-64 object-contain rounded-xl"
            />
            <div className="absolute inset-0 border-2 border-[var(--cyan)] opacity-0 group-hover:opacity-100 rounded-2xl transition-opacity pointer-events-none"></div>
          </div>

          <div className="w-full bg-white/5 rounded-2xl p-5 border border-white/10 flex flex-col gap-4">
            <div className="flex justify-between items-center">
              <span className="text-white/50 text-sm">Số tiền chuyển:</span>
              <span className="text-lg font-mono font-bold text-[var(--magenta)]">{selectedAmount.toLocaleString()} VND</span>
            </div>
            
            <div className="w-full h-px bg-white/10"></div>
            
            <div className="flex justify-between items-center group">
              <div className="flex flex-col">
                <span className="text-white/50 text-sm mb-1">Nội dung chuyển khoản (Bắt buộc):</span>
                <span className="text-xl font-black text-white tracking-widest">{transferContent}</span>
              </div>
              <button 
                onClick={() => handleCopy(transferContent)}
                className="p-3 bg-white/10 hover:bg-white/20 rounded-xl transition-colors text-white active:scale-95"
                title="Copy nội dung"
              >
                {copied ? <CheckCircle size={20} weight="bold" className="text-green-400" /> : <Copy size={20} weight="bold" />}
              </button>
            </div>
          </div>
          
          <div className="mt-6 text-center text-white/40 text-xs flex flex-col items-center gap-2">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
              Hệ thống xử lý tự động trong 3-5 giây
            </div>
            <p>Vui lòng chuyển ĐÚNG nội dung để hệ thống nhận diện tài khoản của bạn.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
