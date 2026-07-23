"use client";
/* eslint-disable */

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Phone, PhoneDisconnect, Microphone, MicrophoneSlash, VideoCamera, VideoCameraSlash, Coin, Sparkle } from "@phosphor-icons/react";
import io, { Socket } from "socket.io-client";
import type { IAgoraRTCClient, IMicrophoneAudioTrack, ICameraVideoTrack } from "agora-rtc-sdk-ng";

interface CallState {
  status: "idle" | "calling" | "incoming" | "connected";
  channelName: string;
  callerId?: number;
  callerName?: string;
  callerAvatar?: string;
  targetUserId?: number;
  targetUserName?: string;
  isVideo: boolean;
  token?: string;
}

interface CoinToast {
  id: number;
  coins: number;
  newBalance: number;
}

export default function RealtimeCallModal() {
  const [callState, setCallState] = useState<CallState>({
    status: "idle",
    channelName: "",
    isVideo: true,
  });

  const [currentUserId, setCurrentUserId] = useState<number>(2);
  const [isMicOn, setIsMicOn] = useState<boolean>(true);
  const [isVideoOn, setIsVideoOn] = useState<boolean>(true);
  const [callDuration, setCallDuration] = useState<number>(0);
  const [coinToasts, setCoinToasts] = useState<CoinToast[]>([]);

  const socketRef = useRef<Socket | null>(null);
  const agoraClientRef = useRef<IAgoraRTCClient | null>(null);
  const localAudioTrackRef = useRef<IMicrophoneAudioTrack | null>(null);
  const localVideoTrackRef = useRef<ICameraVideoTrack | null>(null);

  const localVideoContainerRef = useRef<HTMLDivElement | null>(null);
  const remoteVideoContainerRef = useRef<HTMLDivElement | null>(null);

  // Load userId from cookie / token
  useEffect(() => {
    const cookies = document.cookie.split("; ");
    const tokenCookie = cookies.find((c) => c.startsWith("lucy_token="));
    if (tokenCookie) {
      const token = tokenCookie.split("=")[1];
      try {
        const payload = JSON.parse(atob(token.split(".")[1]));
        if (payload.nameid) setCurrentUserId(parseInt(payload.nameid, 10));
      } catch (e) {
        // fallback
      }
    }
  }, []);

  // Connect Socket & Listen for Realtime Call + Coin Deposit events
  useEffect(() => {
    const socketUrl = process.env.NEXT_PUBLIC_SOCKET_URL || (typeof window !== "undefined" ? window.location.origin : "http://localhost:3001");
    const socket = io(socketUrl, {
      extraHeaders: {
        "ngrok-skip-browser-warning": "69420"
      }
    });
    socketRef.current = socket;

    socket.on("connect", () => {
      console.log("[Socket] Connected to Realtime Server:", socket.id);
      socket.emit("register-user", currentUserId);
    });

    // Handle Incoming Call
    socket.on("incoming-call", (data: { callerId: number; callerName: string; callerAvatar: string; channelName: string; isVideo: boolean; callerToken: string }) => {
      console.log("[Socket] Incoming Call from:", data.callerName);
      setCallState({
        status: "incoming",
        channelName: data.channelName,
        callerId: data.callerId,
        callerName: data.callerName,
        callerAvatar: data.callerAvatar,
        isVideo: data.isVideo,
        token: data.callerToken,
      });
    });

    // Caller receives call-accepted
    socket.on("call-accepted", async (data: { channelName: string; receiverId: number; receiverName?: string }) => {
      console.log("[Socket] Call accepted by receiver");
      setCallState((prev) => ({
        ...prev,
        status: "connected",
        targetUserName: data.receiverName || `User ${data.receiverId}`,
      }));
    });

    // Receiver receives call confirmation
    socket.on("call-joined-receiver", (data: { channelName: string; receiverToken: string }) => {
      setCallState((prev) => ({
        ...prev,
        status: "connected",
        token: data.receiverToken,
      }));
    });

    // Call Rejected
    socket.on("call-rejected", (data: { reason: string }) => {
      alert(`Call declined: ${data.reason}`);
      cleanupCall();
    });

    // Call Ended
    socket.on("call-ended", () => {
      cleanupCall();
    });

    // Realtime Coin Deposit Notification Event from SePay Webhook!
    socket.on("coin-deposited", (data: { coins: number; newBalance: number; transactionId: string }) => {
      console.log("🎉 [Realtime Socket] Coin Deposited!", data);
      const toastId = Date.now();
      setCoinToasts((prev) => [...prev, { id: toastId, coins: data.coins, newBalance: data.newBalance }]);
      
      // Dispatch custom window event so pages like /wallet or navbar can update balance state automatically
      window.dispatchEvent(new CustomEvent("lucy_balance_updated", { detail: data }));

      setTimeout(() => {
        setCoinToasts((prev) => prev.filter((t) => t.id !== toastId));
      }, 5000);
    });

    // Expose global trigger for initiating call from anywhere in app
    (window as any).lucyCallUser = (targetUserId: number, targetName: string, isVideo: boolean = true) => {
      initiateCall(targetUserId, targetName, isVideo);
    };

    return () => {
      socket.disconnect();
    };
  }, [currentUserId]);

  // Call timer
  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (callState.status === "connected") {
      timer = setInterval(() => {
        setCallDuration((prev) => prev + 1);
      }, 1000);
    } else {
      setCallDuration(0);
    }
    return () => clearInterval(timer);
  }, [callState.status]);

  // Agora RTC Setup on Call Connected
  async function cleanupAgora() {
    try {
      localAudioTrackRef.current?.close();
      localVideoTrackRef.current?.close();
      if (agoraClientRef.current) {
        await agoraClientRef.current.leave();
      }
    } catch (e) {
      // ignore
    }
  }

  useEffect(() => {
    let isMounted = true;

    const setupAgora = async () => {
      if (callState.status !== "connected" || !callState.channelName) return;

      try {
        const AgoraRTC = (await import("agora-rtc-sdk-ng")).default;
        if (!agoraClientRef.current) {
          agoraClientRef.current = AgoraRTC.createClient({ mode: "rtc", codec: "vp8" });
        }
        const client = agoraClientRef.current;

        client.on("user-published", async (user, mediaType) => {
          await client.subscribe(user, mediaType);
          if (mediaType === "audio") {
            user.audioTrack?.play();
          }
          if (mediaType === "video" && remoteVideoContainerRef.current) {
            user.videoTrack?.play(remoteVideoContainerRef.current);
          }
        });

        client.on("user-unpublished", (user, mediaType) => {
          if (mediaType === "video" && remoteVideoContainerRef.current) {
            remoteVideoContainerRef.current.innerHTML = "";
          }
        });

        // Join Agora Channel Safely
        const appId = process.env.NEXT_PUBLIC_AGORA_APP_ID;
        const uid = currentUserId || Math.floor(Math.random() * 10000);
        
        if (appId && appId !== "ff0b01c1072940259b3112c3f15c7e18") {
          try {
            await client.join(appId, callState.channelName, callState.token || null, uid);

            // Create and publish local mic & camera tracks
            localAudioTrackRef.current = await AgoraRTC.createMicrophoneAudioTrack();
            const tracks: any[] = [localAudioTrackRef.current];

            if (callState.isVideo) {
              localVideoTrackRef.current = await AgoraRTC.createCameraVideoTrack();
              tracks.push(localVideoTrackRef.current);
              if (localVideoContainerRef.current) {
                localVideoTrackRef.current.play(localVideoContainerRef.current);
              }
            }

            await client.publish(tracks);
          } catch (joinErr) {
            console.warn("Agora channel join warning:", joinErr);
          }
        } else {
          console.warn("Agora App ID not configured or using demo mode. Call stage active in UI preview mode.");
        }
      } catch (err) {
        console.warn("Agora call setup non-fatal error:", err);
      }
    };

    setupAgora();

    return () => {
      if (callState.status !== "connected") {
        cleanupAgora();
      }
    };
  }, [callState.status, callState.channelName]);

  function cleanupCall() {
    cleanupAgora();
    setCallState({ status: "idle", channelName: "", isVideo: true });
    setIsMicOn(true);
    setIsVideoOn(true);
  }

  // Initiate Outgoing Call
  function initiateCall(targetUserId: number, targetName: string, isVideo: boolean = true) {
    setCallState({
      status: "calling",
      channelName: "",
      targetUserId,
      targetUserName: targetName,
      isVideo,
    });

    socketRef.current?.emit("call-user", {
      targetUserId,
      callerId: currentUserId,
      callerName: `User_${currentUserId}`,
      isVideo,
    });
  }

  // Accept Incoming Call
  const handleAcceptCall = () => {
    if (!callState.callerId || !callState.channelName) return;

    socketRef.current?.emit("accept-call", {
      channelName: callState.channelName,
      callerId: callState.callerId,
      receiverId: currentUserId,
      receiverName: `User_${currentUserId}`,
    });

    setCallState((prev) => ({ ...prev, status: "connected" }));
  };

  // Reject Call
  const handleRejectCall = () => {
    if (callState.callerId) {
      socketRef.current?.emit("reject-call", { callerId: callState.callerId });
    }
    cleanupCall();
  };

  // End Active Call
  const handleEndCall = () => {
    const target = callState.callerId || callState.targetUserId || 0;
    socketRef.current?.emit("end-call", { targetUserId: target, channelName: callState.channelName });
    cleanupCall();
  };

  // Toggle Mute
  const handleToggleMic = async () => {
    const next = !isMicOn;
    setIsMicOn(next);
    if (localAudioTrackRef.current) {
      await localAudioTrackRef.current.setMuted(!next);
    }
  };

  // Toggle Video
  const handleToggleVideo = async () => {
    const next = !isVideoOn;
    setIsVideoOn(next);
    if (localVideoTrackRef.current) {
      await localVideoTrackRef.current.setMuted(!next);
    }
  };

  const formatDuration = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  };

  return (
    <>
      {/* Realtime Coin Deposit Toast Popup */}
      <div className="fixed top-6 right-6 z-[10000] flex flex-col gap-3 pointer-events-none">
        <AnimatePresence>
          {coinToasts.map((toast) => (
            <motion.div
              key={toast.id}
              initial={{ opacity: 0, x: 100, scale: 0.8 }}
              animate={{ opacity: 1, x: 0, scale: 1 }}
              exit={{ opacity: 0, x: 100, scale: 0.8 }}
              className="pointer-events-auto bg-gradient-to-r from-yellow-500/20 via-amber-500/30 to-yellow-600/20 border-2 border-yellow-400/60 backdrop-blur-xl p-5 rounded-3xl shadow-[0_0_30px_rgba(234,179,8,0.4)] flex items-center gap-4 text-white max-w-sm"
            >
              <div className="w-12 h-12 rounded-2xl bg-yellow-400/20 border border-yellow-400/40 flex items-center justify-center text-yellow-300 shadow-inner shrink-0 animate-bounce">
                <Coin size={32} weight="duotone" />
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5 text-xs font-bold text-yellow-300 uppercase tracking-widest">
                  <Sparkle size={14} weight="fill" /> Nạp Coin Thành Công!
                </div>
                <div className="text-xl font-black font-mono text-white mt-0.5">
                  +{toast.coins.toLocaleString()} Xu
                </div>
                <div className="text-[11px] text-white/70">
                  Số dư mới: <span className="font-bold text-yellow-300">{toast.newBalance.toLocaleString()} Xu</span>
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Real-time Call Modals */}
      <AnimatePresence>
        {callState.status !== "idle" && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[9999] bg-black/80 backdrop-blur-2xl flex items-center justify-center p-4 overflow-hidden"
          >
            {/* 1. OUTGOING CALLING OVERLAY */}
            {callState.status === "calling" && (
              <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
                className="flex flex-col items-center gap-6 p-8 rounded-3xl bg-slate-900/90 border border-cyan-500/30 shadow-[0_0_50px_rgba(6,182,212,0.25)] max-w-md w-full text-center relative"
              >
                <div className="relative">
                  <div className="absolute inset-0 rounded-full bg-cyan-500/20 animate-ping"></div>
                  <img
                    src={`https://api.dicebear.com/9.x/notionists/svg?seed=${callState.targetUserName || "User"}`}
                    alt="Target Avatar"
                    className="w-28 h-28 rounded-full border-4 border-cyan-400 shadow-[0_0_25px_rgba(6,182,212,0.5)] relative z-10"
                  />
                </div>
                <div>
                  <h3 className="text-2xl font-bold text-white mb-1">Đang gọi cho {callState.targetUserName}...</h3>
                  <p className="text-cyan-400/80 text-sm animate-pulse">Đang kết nối tín hiệu Real-time...</p>
                </div>

                <button
                  onClick={handleEndCall}
                  className="mt-4 w-16 h-16 rounded-full bg-red-500/20 border border-red-500 text-red-400 hover:bg-red-500 hover:text-white flex items-center justify-center transition-all shadow-[0_0_20px_rgba(239,68,68,0.4)]"
                >
                  <PhoneDisconnect size={28} weight="fill" />
                </button>
              </motion.div>
            )}

            {/* 2. INCOMING CALL OVERLAY */}
            {callState.status === "incoming" && (
              <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
                className="flex flex-col items-center gap-6 p-8 rounded-3xl bg-slate-900/90 border border-pink-500/30 shadow-[0_0_50px_rgba(236,72,153,0.3)] max-w-md w-full text-center relative"
              >
                <div className="relative">
                  <div className="absolute inset-0 rounded-full bg-pink-500/30 animate-ping"></div>
                  <img
                    src={callState.callerAvatar || `https://api.dicebear.com/9.x/notionists/svg?seed=${callState.callerName}`}
                    alt="Caller Avatar"
                    className="w-28 h-28 rounded-full border-4 border-pink-500 shadow-[0_0_25px_rgba(236,72,153,0.5)] relative z-10"
                  />
                </div>
                <div>
                  <div className="text-pink-400 font-bold text-xs uppercase tracking-widest mb-1">Cuộc gọi trực tiếp đến</div>
                  <h3 className="text-2xl font-extrabold text-white">{callState.callerName}</h3>
                </div>

                <div className="flex items-center gap-8 mt-4">
                  <button
                    onClick={handleRejectCall}
                    className="w-16 h-16 rounded-full bg-red-500/20 border border-red-500 text-red-400 hover:bg-red-500 hover:text-white flex items-center justify-center transition-all shadow-[0_0_20px_rgba(239,68,68,0.4)]"
                    title="Từ chối"
                  >
                    <PhoneDisconnect size={28} weight="fill" />
                  </button>

                  <button
                    onClick={handleAcceptCall}
                    className="w-16 h-16 rounded-full bg-emerald-500/20 border border-emerald-500 text-emerald-400 hover:bg-emerald-500 hover:text-white flex items-center justify-center transition-all shadow-[0_0_25px_rgba(16,185,129,0.5)] animate-bounce"
                    title="Chấp nhận"
                  >
                    <Phone size={28} weight="fill" />
                  </button>
                </div>
              </motion.div>
            )}

            {/* 3. ACTIVE CONNECTED CALL STAGE */}
            {callState.status === "connected" && (
              <div className="w-full max-w-4xl h-[80vh] bg-slate-950 rounded-3xl border border-white/10 overflow-hidden flex flex-col relative shadow-2xl">
                {/* Header */}
                <div className="px-6 py-4 border-b border-white/10 flex justify-between items-center bg-slate-900/50 backdrop-blur-md">
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_10px_rgba(16,185,129,0.8)]"></div>
                    <span className="font-bold text-white text-sm">
                      LUCY Real-time Call ({callState.callerName || callState.targetUserName || "Direct Session"})
                    </span>
                  </div>
                  <div className="font-mono text-cyan-400 font-bold bg-cyan-500/10 border border-cyan-500/30 px-3 py-1 rounded-full text-xs">
                    {formatDuration(callDuration)}
                  </div>
                </div>

                {/* Main Video View Stage */}
                <div className="flex-1 relative bg-slate-950 flex items-center justify-center overflow-hidden">
                  {/* Remote Video Container */}
                  <div ref={remoteVideoContainerRef} className="w-full h-full object-cover flex items-center justify-center">
                    {/* Placeholder when remote video is not active */}
                    <div className="flex flex-col items-center gap-3 text-white/40">
                      <div className="w-24 h-24 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-3xl font-bold">
                        {(callState.callerName || callState.targetUserName || "U")[0]}
                      </div>
                      <p className="text-sm">Đang phát âm thanh/video HD...</p>
                    </div>
                  </div>

                  {/* Local Video Container (Floating PiP) */}
                  {callState.isVideo && (
                    <div
                      ref={localVideoContainerRef}
                      className="absolute bottom-6 right-6 w-48 h-36 rounded-2xl border-2 border-cyan-500/50 bg-slate-900 shadow-2xl overflow-hidden"
                    />
                  )}
                </div>

                {/* Bottom Control Actions */}
                <div className="p-6 bg-slate-900/80 border-t border-white/10 flex justify-center items-center gap-6 backdrop-blur-md">
                  <button
                    onClick={handleToggleMic}
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all ${
                      isMicOn
                        ? "bg-white/10 text-white hover:bg-white/20"
                        : "bg-red-500/20 border border-red-500 text-red-400"
                    }`}
                  >
                    {isMicOn ? <Microphone size={22} /> : <MicrophoneSlash size={22} />}
                  </button>

                  <button
                    onClick={handleToggleVideo}
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all ${
                      isVideoOn
                        ? "bg-white/10 text-white hover:bg-white/20"
                        : "bg-red-500/20 border border-red-500 text-red-400"
                    }`}
                  >
                    {isVideoOn ? <VideoCamera size={22} /> : <VideoCameraSlash size={22} />}
                  </button>

                  <button
                    onClick={handleEndCall}
                    className="w-14 h-12 rounded-2xl bg-red-500 text-white hover:bg-red-600 flex items-center justify-center transition-all shadow-[0_0_20px_rgba(239,68,68,0.5)]"
                  >
                    <PhoneDisconnect size={24} weight="fill" />
                  </button>
                </div>
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
