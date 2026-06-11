// Data Mocks (Base Values - will be overwritten dynamically by translations)
const MOCK_USERS = [
  { id: 1, name: "Alex", role: "moderator", mic: true, speaking: true, handRaised: false },
  { id: 2, name: "Sarah", role: "pro", mic: true, speaking: false, handRaised: false },
  { id: 3, name: "Guest_03", role: "anonymous", mic: false, speaking: false, handRaised: false },
  { id: 4, name: "David", role: "pro", mic: false, speaking: false, handRaised: true },
  { id: 5, name: "Emily", role: "pro", mic: true, speaking: false, handRaised: false }
];

const MOCK_ROOMS = [
  { id: 101, name: "Morning Conversation", level: "B1", lang: "en", users: 5, status: "LIVE", desc: "Practice reflexes with everyday topics. Focus on fluency and natural speech.", image: "assets/images/english_minimalist_studio.png" },
  { id: 102, name: "Beginner Talk (日本語)", level: "A1", lang: "ja", users: 2, status: "LIVE", desc: "For absolute beginners learning Japanese. Slow-paced basic greetings.", image: "assets/images/benthanh_sakura.png" },
  { id: 103, name: "Advanced Discussion (中文)", level: "B2", lang: "zh", users: 0, status: "SCHEDULED", desc: "Deep discussions on Chinese news and culture. Starts at 14:00.", image: "assets/images/chinese_dragon_festival.png" },
  { id: 104, name: "Daily Vocabulary (English)", level: "A2", lang: "en", users: 8, status: "LIVE", desc: "Learn essential vocabulary through real-life situations with flashcards.", image: "assets/images/english_minimalist_studio.png" },
  { id: 105, name: "IELTS Speaking Club", level: "B2", lang: "en", users: 0, status: "ENDED", desc: "Practice IELTS Parts 2 & 3 with an AI examiner. Session completed.", image: "assets/images/english_minimalist_studio.png" }
];

const TIMER_SECONDS = 10 * 60;
const CIRCLE_CIRC = 2 * Math.PI * 95;

// Translation Dictionaries (Full Multilingual Translation System)
const TRANSLATIONS = {
  en: {
    brand_sub: "ARCHIVE",
    hero_title: 'SPEAK<br><span class="hero-accent">WITHOUT FEAR.</span>',
    hero_desc: "Anonymous, high-fidelity language practice rooms. Join an active session below.",
    btn_start: "START SESSION",
    btn_how: "HOW IT WORKS",
    filter_all: "ALL",
    search_placeholder: "Search archive...",
    users_lbl: "ACTIVE PARTICIPANTS",
    console_lbl: "SYSTEM CONSOLE",
    console_role: "MOD",
    vocab_lbl: "NEW WORDS TODAY",
    btn_next_topic: "NEXT TOPIC →",
    btn_record: "● RECORD",
    btn_recording: "● RECORDING",
    btn_leave: "LEAVE ×",
    disconnect_title: "DISCONNECT?",
    disconnect_desc: "You are about to leave the active session.",
    btn_cancel: "CANCEL",
    btn_confirm: "CONFIRM DISCONNECT",
    session_ended_title: 'SESSION<br><span class="hero-accent">TERMINATED.</span>',
    lbl_minutes: "MINUTES",
    lbl_topics: "TOPICS",
    btn_new_session: "NEW SESSION",
    btn_lobby: "LOBBY",
    btn_raise_hand: "RAISE HAND",
    btn_hand_raised: "HAND RAISED",
    toast_session_finished: "Session finished.",
    toast_topics_completed: "All topics completed!",
    toast_recording_started: "Session recording started.",
    toast_recording_saved: "Recording saved to system console.",
    rooms: [
      { id: 101, name: "Morning Conversation", desc: "Practice reflexes with everyday topics. Focus on fluency and natural speech." },
      { id: 102, name: "Beginner Talk (日本語)", desc: "For absolute beginners learning Japanese. Slow-paced basic greetings." },
      { id: 103, name: "Advanced Discussion (中文)", desc: "Deep discussions on Chinese news and culture. Starts at 14:00." },
      { id: 104, name: "Daily Vocabulary (English)", desc: "Learn essential vocabulary through real-life situations with flashcards." },
      { id: 105, name: "IELTS Speaking Club", desc: "Practice IELTS Parts 2 & 3 with an AI examiner. Session completed." }
    ],
    sub_levels: ["Greeting Strangers", "Daily Routines", "Travel Stories", "Future Plans"],
    mock_users: [
      { id: 1, name: "Alex", role: "moderator" },
      { id: 2, name: "Sarah", role: "pro" },
      { id: 3, name: "Guest_03", role: "anonymous" },
      { id: 4, name: "David", role: "pro" },
      { id: 5, name: "Emily", role: "pro" }
    ],
    hints: [
      ["Introduce yourself to others briefly.", "Ask others about their day.", "Keep it polite and open."],
      ["Describe your morning routine.", "Discuss your ideal study/work hours.", "Compare weekdays and weekends."],
      ["Share a memorable trip you've had.", "What mode of transport do you prefer?", "Recommend a destination."],
      ["Your goals for the next 5 years.", "What new skill do you want to learn?", "Share your action plan."]
    ],
    vocab: [
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
  },
  ja: {
    brand_sub: "アーカイブ",
    hero_title: '恐れずに<br><span class="hero-accent">話そう。</span>',
    hero_desc: "匿名で高音質な言語練習ルーム。以下からアクティブなセッションに参加してください。",
    btn_start: "セッションを開始",
    btn_how: "使い方",
    filter_all: "すべて",
    search_placeholder: "アーカイブを検索...",
    users_lbl: "参加中のメンバー",
    console_lbl: "システムコンソール",
    console_role: "管理",
    vocab_lbl: "今日の新しい単語",
    btn_next_topic: "次のトピックへ →",
    btn_record: "● 録音",
    btn_recording: "● 録音中",
    btn_leave: "退室 ×",
    disconnect_title: "接続を切断しますか？",
    disconnect_desc: "現在のアクティブなセッションから退室しようとしています。",
    btn_cancel: "キャンセル",
    btn_confirm: "切断を確定",
    session_ended_title: 'セッション<br><span class="hero-accent">終了。</span>',
    lbl_minutes: "経過時間（分）",
    lbl_topics: "トピック数",
    btn_new_session: "新しいセッション",
    btn_lobby: "ロビーに戻る",
    btn_raise_hand: "挙手する",
    btn_hand_raised: "挙手しています",
    toast_session_finished: "セッションが終了しました。",
    toast_topics_completed: "すべてのトピックが完了しました！",
    toast_recording_started: "セッションの録音を開始しました。",
    toast_recording_saved: "録音がシステムコンソールに保存されました。",
    rooms: [
      { id: 101, name: "朝の英会話フリートーク", desc: "日常会話で口慣らし。流暢さと自然な表現力にフォーカス。" },
      { id: 102, name: "ビギナートーク (日本語)", desc: "日本語初心者向け。ゆっくりとしたペースで基礎の挨拶を練習。" },
      { id: 103, name: "上級ディスカッション (中文)", desc: "中国の時事ニュースや伝統文化について。14:00開始。" },
      { id: 104, name: "デイリー単語習得 (English)", desc: "実際のシチュエーションに応じた必須単語の学習とフラッシュカード。" },
      { id: 105, name: "IELTSスピーキングクラブ", desc: "AI面接官とIELTS Part 2 & 3の練習。セッション終了。" }
    ],
    sub_levels: ["初対面の挨拶", "一日の習慣", "旅行の思い出", "将来の計画"],
    mock_users: [
      { id: 1, name: "アレックス", role: "管理" },
      { id: 2, name: "サラ", role: "プロ" },
      { id: 3, name: "ゲスト_03", role: "匿名" },
      { id: 4, name: "デビッド", role: "プロ" },
      { id: 5, name: "エミリー", role: "プロ" }
    ],
    hints: [
      ["簡単に自己紹介をしてください。", "相手の今日の一日について聞いてみましょう。", "礼儀正しく、オープンな態度で。"],
      ["朝のルーティンについて説明してください。", "理想的な勉強や仕事の時間について話し合います。", "平日と週末のルーティンを比較します。"],
      ["最も印象に残っている旅行について教えてください。", "どの交通手段が好きですか？理由も教えてください。", "おすすめの旅行先を提案してください。"],
      ["今後5年間の目標を教えてください。", "今一番学びたい新しいスキルは何ですか？", "目標達成のための具体的な計画を共有します。"]
    ],
    vocab: [
      [
        { word: "自己紹介 (Jikoshoukai)", type: "名", definition: "自分の名前や経歴を人に紹介すること", ipa: "じこしょうかい" },
        { word: "緊張 (Kinchou)", type: "名/動", definition: "心が引き締まり、体がこわばること", ipa: "きんちょう" },
        { word: "匿名 (Tokumei)", type: "名", definition: "名前を隠して明かさないこと", ipa: "とくめい" }
      ],
      [
        { word: "習慣 (Shuukan)", type: "名", definition: "日常の決まりきった行動パターン", ipa: "しゅうかん" },
        { word: "早起き (Hayaoki)", type: "名/動", definition: "朝早くに目を覚まして起きること", ipa: "はやおき" },
        { word: "効率的 (Kouritsuteki)", type: "形動", definition: "労力に対して効果や成果が高い様子", ipa: "こうりつてき" }
      ],
      [
        { word: "思い出 (Omoide)", type: "名", definition: "心に残っている過去の出来事", ipa: "おもいで" },
        { word: "観光地 (Kankouchi)", type: "名", definition: "旅行者が訪れる魅力的な場所", ipa: "かんこうち" },
        { word: "日程 (Nittei)", type: "名", definition: "旅行やイベントのスケジュールのこと", ipa: "にってい" }
      ],
      [
        { word: "目標 (Mokuhyou)", type: "名", definition: "目指すべき将来の到達点", ipa: "もくひょう" },
        { word: "計画 (Keikaku)", type: "名/動", definition: "目標を達成するための具体的な手順", ipa: "けいかく" },
        { word: "実現 (Jitsugen)", type: "名/動", definition: "計画や夢を現実にすること", ipa: "じつげん" }
      ]
    ]
  },
  zh: {
    brand_sub: "存檔",
    hero_title: '大膽開口<br><span class="hero-accent">無需畏懼。</span>',
    hero_desc: "匿名、高保真語言練習語音房。加入下方活躍的對話吧。",
    btn_start: "開始對話",
    btn_how: "運作方式",
    filter_all: "全部",
    search_placeholder: "搜索存檔...",
    users_lbl: "當前麥上成員",
    console_lbl: "系統控制台",
    console_role: "主持",
    vocab_lbl: "今日新詞推薦",
    btn_next_topic: "下一主題 →",
    btn_record: "● 錄音",
    btn_recording: "● 錄音中",
    btn_leave: "退出 ×",
    disconnect_title: "確認斷開連接？",
    disconnect_desc: "您即將退出當前的活躍對話房。",
    btn_cancel: "取消",
    btn_confirm: "確認退出",
    session_ended_title: '語音會話<br><span class="hero-accent">已結束。</span>',
    lbl_minutes: "通話時長（分鐘）",
    lbl_topics: "討論主題數",
    btn_new_session: "新會話",
    btn_lobby: "大廳",
    btn_raise_hand: "申請發言",
    btn_hand_raised: "已申請發言",
    toast_session_finished: "會話已完成。",
    toast_topics_completed: "所有主題討論完畢！",
    toast_recording_started: "已開始錄音。",
    toast_recording_saved: "錄音已保存至控制台。",
    rooms: [
      { id: 101, name: "晨間英語日常對話", desc: "鍛煉日常口語反射。側重於表達流暢度與自然感。" },
      { id: 102, name: "日語新手基礎交流 (日本語)", desc: "適合日語初學者。緩慢語速的日常問候與簡單對話。" },
      { id: 103, name: "中文高級深度研討 (中文)", desc: "深入討論中國時事新聞與傳統文化背景。14:00 開始。" },
      { id: 104, name: "每日核心詞彙學習 (English)", desc: "結合實際情景學習核心單詞，附帶記憶閃卡。" },
      { id: 105, name: "雅思口語模擬俱樂部", desc: "與AI考官練習雅思口語 Part 2 & 3。會話已結束。" }
    ],
    sub_levels: ["初次問候", "日常作息", "旅行見聞", "未來規劃"],
    mock_users: [
      { id: 1, name: "亞歷克斯", role: "主持" },
      { id: 2, name: "莎拉", role: "專業" },
      { id: 3, name: "訪客_03", role: "匿名" },
      { id: 4, name: "大衛", role: "專業" },
      { id: 5, name: "艾米麗", role: "專業" }
    ],
    hints: [
      ["简单地向大家介绍一下自己。", "询问对方今天过得怎么样。", "保持礼貌和开放的态度。"],
      ["描述你早晨的日常习惯。", "讨论你理想的学习或工作时间。", "对比工作日和周末的日常习惯。"],
      ["分享一次你最难忘的旅行经历。", "你喜欢用什么交通工具旅行？为什么？", "给别人推荐一个有趣的旅游景点。"],
      ["你未来5年的职业或学习目标是什么？", "你目前最想学习哪项新技能？", "分享具体可行的行动计划。"]
    ],
    vocab: [
      [
        { word: "自我介绍 (Zìwǒ jièshào)", type: "名/动", definition: "向他人介绍自己的名字、背景等", ipa: "zì wǒ jiè shào" },
        { word: "亲切 (Qīnqiè)", type: "形", definition: "态度热情、温和、容易接近", ipa: "qīn qiè" },
        { word: "匿名 (Nìmíng)", type: "动/形", definition: "不署名或不公开真实姓名", ipa: "nì míng" }
      ],
      [
        { word: "规律 (Guīlǜ)", type: "名/形", definition: "事物运动过程中的本性联系，有条理", ipa: "guī lǜ" },
        { word: "充实 (Chōngshí)", type: "形", definition: "丰富，内容充足，有意义", ipa: "chōng shí" },
        { word: "枯燥 (Kūzào)", type: "形", definition: "单调无趣，没有生气", ipa: "kū zào" }
      ],
      [
        { word: "难忘 (Nánwàng)", type: "形", definition: "印象深刻，难以忘记的经历", ipa: "nán wàng" },
        { word: "风景 (Fēngjǐng)", type: "名", definition: "自然景物或人文景致", ipa: "fēng jǐng" },
        { word: "行程 (Xíngchéng)", type: "名", definition: "路程，或者是旅行的计划路线", ipa: "xíng chéng" }
      ],
      [
        { word: "目标 (Mùbiāo)", type: "名", definition: "想要达到的境地或标准", ipa: "mù biāo" },
        { word: "展望 (Zhǎnwàng)", type: "名/动", definition: "对未来的期望、预见与展望", ipa: "zhǎn wàng" },
        { word: "落后 (Luòhòu)", type: "动/形", definition: "落入人后，发展慢于平均水平", ipa: "luò hòu" }
      ]
    ]
  }
};

const state = {
  activeFilter: "",
  currentScreen: "lobby",
  users: [],
  timeRemaining: TIMER_SECONDS,
  currentSublevelIndex: 0,
  isMicOn: true,
  isHandRaised: false,
  timerInterval: null,
  isRecording: false,
  currentLang: "en", // Active Room language
  activeLang: "en"   // UI language
};

const $ = sel => document.querySelector(sel);
const $$ = sel => document.querySelectorAll(sel);

// ==========================================================================
// BACKGROUND CANVAS PARTICLE SYSTEMS
// ==========================================================================
let canvas, ctx;
let particles = [];
let animFrameId = null;
let currentParticleTheme = 'en';

class SakuraPetal {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.reset();
    this.y = Math.random() * h;
  }
  
  reset() {
    this.x = Math.random() * this.w;
    this.y = -20;
    this.size = Math.random() * 8 + 6;
    this.speedY = Math.random() * 1.0 + 0.5; // slow drift downwards
    this.speedX = (Math.random() * 0.4 - 0.2) - 0.2; // slight drift to left
    this.opacity = Math.random() * 0.6 + 0.3;
    this.rotation = Math.random() * Math.PI * 2;
    this.spin = Math.random() * 0.02 - 0.01;
    this.swingAngle = Math.random() * Math.PI;
    this.swingSpeed = Math.random() * 0.01 + 0.005;
  }
  
  update() {
    this.y += this.speedY;
    this.swingAngle += this.swingSpeed;
    this.x += this.speedX + Math.sin(this.swingAngle) * 0.3;
    this.rotation += this.spin;
    
    if (this.y > this.h + 20 || this.x < -20 || this.x > this.w + 20) {
      this.reset();
    }
  }
  
  draw() {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.rotation);
    ctx.beginPath();
    ctx.ellipse(0, 0, this.size, this.size / 2, 0, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(219, 138, 156, ${this.opacity})`; // #db8a9c sakura color
    ctx.fill();
    ctx.restore();
  }
}

class Lantern {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.reset();
    this.y = Math.random() * h + h;
  }
  
  reset() {
    this.x = Math.random() * this.w;
    this.y = this.h + Math.random() * 150 + 50;
    this.sizeW = Math.random() * 12 + 10;
    this.sizeH = this.sizeW * 1.35;
    this.speedY = -(Math.random() * 0.5 + 0.3); // rise upwards slowly
    this.swingAngle = Math.random() * Math.PI;
    this.swingSpeed = Math.random() * 0.008 + 0.004;
    this.opacity = Math.random() * 0.5 + 0.4;
  }
  
  update() {
    this.y += this.speedY;
    this.swingAngle += this.swingSpeed;
    this.x += Math.sin(this.swingAngle) * 0.25;
    
    if (this.y < -this.sizeH - 20) {
      this.reset();
    }
  }
  
  draw() {
    ctx.save();
    ctx.translate(this.x, this.y);
    
    // Draw string
    ctx.strokeStyle = `rgba(255, 215, 0, ${this.opacity * 0.3})`;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, -this.sizeH / 2 - 8);
    ctx.lineTo(0, this.sizeH / 2 + 12);
    ctx.stroke();
    
    // Draw Lantern Body (oval red shape)
    ctx.fillStyle = `rgba(211, 47, 47, ${this.opacity})`;
    ctx.strokeStyle = `rgba(255, 215, 0, ${this.opacity * 0.7})`;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.ellipse(0, 0, this.sizeW / 2, this.sizeH / 2, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    
    // Draw caps
    ctx.fillStyle = `rgba(255, 215, 0, ${this.opacity})`;
    ctx.fillRect(-this.sizeW / 4, -this.sizeH / 2 - 1.5, this.sizeW / 2, 3);
    ctx.fillRect(-this.sizeW / 4, this.sizeH / 2 - 1.5, this.sizeW / 2, 3);
    
    // Lantern glow shadow effect
    ctx.shadowColor = 'rgba(255, 234, 0, 0.3)';
    ctx.shadowBlur = 10;
    ctx.fillStyle = `rgba(255, 234, 0, ${this.opacity * 0.2})`;
    ctx.beginPath();
    ctx.arc(0, 0, this.sizeW * 0.9, 0, Math.PI * 2);
    ctx.fill();
    
    ctx.restore();
  }
}

class FireworkSpark {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.reset();
  }
  
  reset() {
    if (Math.random() < 0.012) {
      this.centerX = Math.random() * this.w;
      this.centerY = Math.random() * (this.h * 0.65);
      this.angle = Math.random() * Math.PI * 2;
      this.speed = Math.random() * 2.2 + 0.8;
      this.x = this.centerX;
      this.y = this.centerY;
      this.life = Math.random() * 35 + 25;
      this.maxLife = this.life;
      this.size = Math.random() * 2 + 1;
      this.color = Math.random() > 0.5 ? 'rgba(255, 234, 0, ' : 'rgba(255, 215, 0, ';
    } else {
      this.x = -100;
      this.y = -100;
      this.life = 0;
    }
  }
  
  update() {
    if (this.life > 0) {
      this.x += Math.cos(this.angle) * this.speed;
      this.y += Math.sin(this.angle) * this.speed + 0.04; // Gravity
      this.life--;
    } else {
      this.reset();
    }
  }
  
  draw() {
    if (this.life > 0) {
      ctx.save();
      const pct = this.life / this.maxLife;
      ctx.fillStyle = this.color + pct + ')';
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.size * pct, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }
}

function initThemeParticles(theme) {
  currentParticleTheme = theme;
  particles = [];
  
  if (!canvas) {
    canvas = document.getElementById('theme-particles-canvas');
    if (!canvas) return;
    ctx = canvas.getContext('2d');
    
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();
  }
  
  function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }
  
  if (theme === 'ja') {
    const numPetals = Math.min(Math.floor(window.innerWidth / 22), 65);
    for (let i = 0; i < numPetals; i++) {
      particles.push(new SakuraPetal(canvas.width, canvas.height));
    }
  } else if (theme === 'zh') {
    const numLanterns = Math.min(Math.floor(window.innerWidth / 110), 14);
    for (let i = 0; i < numLanterns; i++) {
      particles.push(new Lantern(canvas.width, canvas.height));
    }
    const numSparks = 85;
    for (let i = 0; i < numSparks; i++) {
      particles.push(new FireworkSpark(canvas.width, canvas.height));
    }
  }
  
  if (!animFrameId && theme !== 'en') {
    tick();
  }
}

function tick() {
  if (currentParticleTheme === 'en') {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    animFrameId = null;
    return;
  }
  
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  particles.forEach(p => {
    p.update();
    p.draw();
  });
  
  animFrameId = requestAnimationFrame(tick);
}

// ==========================================================================
// TRANSLATION ENGINE & UI UPDATE functions
// ==========================================================================
function applyTranslations(lang) {
  const t = TRANSLATIONS[lang];
  if (!t) return;
  
  // Set UI lang state
  state.activeLang = lang;
  
  // Update Brand Sub
  const brandSub = document.querySelector('.nav-brand-sub');
  if (brandSub) brandSub.textContent = t.brand_sub;
  
  // Update Lobby Hero content (only if elements exist)
  const heroTitle = document.querySelector('.hero-title');
  if (heroTitle && state.currentScreen === 'lobby') {
    heroTitle.innerHTML = t.hero_title;
  }
  const heroDesc = document.querySelector('.hero-desc');
  if (heroDesc) heroDesc.textContent = t.hero_desc;
  
  const btnStart = document.querySelector('.hero-ctas .btn-primary');
  if (btnStart) btnStart.textContent = t.btn_start;
  const btnHow = document.querySelector('.hero-ctas .btn-ghost');
  if (btnHow) btnHow.textContent = t.btn_how;
  
  // Lobby Filter bar & search
  const filterAll = document.querySelector('.filter-pill[data-level=""]');
  if (filterAll) filterAll.textContent = t.filter_all;
  
  const searchInput = document.getElementById('search-room');
  if (searchInput) searchInput.placeholder = t.search_placeholder;
  
  // Ended Screen
  const endedTitle = document.querySelector('#screen-ended .hero-title');
  if (endedTitle) endedTitle.innerHTML = t.session_ended_title;
  
  const statLabels = document.querySelectorAll('.stat-box .lbl');
  if (statLabels.length >= 2) {
    statLabels[0].textContent = t.lbl_minutes;
    statLabels[1].textContent = t.lbl_topics;
  }
  
  const btnJoinOther = document.getElementById('btn-join-other');
  if (btnJoinOther) btnJoinOther.textContent = t.btn_new_session;
  const btnBackLobby = document.getElementById('btn-back-lobby');
  if (btnBackLobby) btnBackLobby.textContent = t.btn_lobby;
  
  // Voice Room details
  const usersLbl = document.querySelector('.sidebar-users .sidebar-header .lbl');
  if (usersLbl) usersLbl.textContent = t.users_lbl;
  
  const consoleLbl = document.querySelector('.sidebar-mod .sidebar-header .lbl');
  if (consoleLbl) consoleLbl.textContent = t.console_lbl;
  const consoleRole = document.querySelector('.sidebar-mod .sidebar-header .role-badge');
  if (consoleRole) consoleRole.textContent = t.console_role;
  
  const vocabLbl = document.querySelector('.vocab-section .sidebar-header .lbl');
  if (vocabLbl) vocabLbl.textContent = t.vocab_lbl;
  
  const btnNextTopic = document.getElementById('btn-next-sublevel');
  if (btnNextTopic) btnNextTopic.textContent = t.btn_next_topic;
  
  const btnRecord = document.getElementById('btn-toggle-record');
  if (btnRecord) {
    if (state.isRecording) {
      btnRecord.textContent = t.btn_recording;
    } else {
      btnRecord.textContent = t.btn_record;
    }
  }
  
  const btnLeave = document.getElementById('btn-leave-room');
  if (btnLeave) btnLeave.textContent = t.btn_leave;
  
  // Dialog box
  const dialogBox = document.querySelector('.dialog-box');
  if (dialogBox) {
    const dialogH3 = dialogBox.querySelector('h3');
    if (dialogH3) dialogH3.textContent = t.disconnect_title;
    const dialogP = dialogBox.querySelector('p');
    if (dialogP) dialogP.textContent = t.disconnect_desc;
    
    const btnCancelLeave = document.getElementById('btn-cancel-leave');
    if (btnCancelLeave) btnCancelLeave.textContent = t.btn_cancel;
    const btnConfirmLeave = document.getElementById('btn-confirm-leave');
    if (btnConfirmLeave) btnConfirmLeave.textContent = t.btn_confirm;
  }
  
  // Dynamic user objects (translated user names & roles)
  state.users = MOCK_USERS.map((u, idx) => {
    const translationUser = t.mock_users[idx];
    return {
      ...u,
      name: translationUser ? translationUser.name : u.name,
      role: translationUser ? translationUser.role : u.role
    };
  });
  
  // Update mock room details and hero image
  const heroImg = document.querySelector('.hero-img');
  if (heroImg) {
    if (lang === 'en') {
      heroImg.src = 'assets/images/english_minimalist_studio.png';
    } else if (lang === 'ja') {
      heroImg.src = 'assets/images/benthanh_sakura.png';
    } else if (lang === 'zh') {
      heroImg.src = 'assets/images/chinese_dragon_festival.png';
    }
  }
  
  // Dynamically map room details for active list
  MOCK_ROOMS.forEach((r) => {
    const tr = t.rooms.find(room => room.id === r.id);
    if (tr) {
      r.name = tr.name;
      r.desc = tr.desc;
    }
    // Swap image based on room language/theme
    if (r.lang === 'en') {
      r.image = 'assets/images/english_minimalist_studio.png';
    } else if (r.lang === 'ja') {
      r.image = 'assets/images/benthanh_sakura.png';
    } else if (r.lang === 'zh') {
      r.image = 'assets/images/chinese_dragon_festival.png';
    }
  });
  
  // Render views
  if (state.currentScreen === 'lobby') {
    renderLobby();
  } else if (state.currentScreen === 'room') {
    renderUsers();
    renderProgress();
    renderHints();
    renderVocab();
  }
}

// ==========================================================================
// CORE APP ROUTING & DISPLAY
// ==========================================================================
function switchScreen(name) {
  state.currentScreen = name;
  ['lobby', 'room', 'ended'].forEach(s => $(`#screen-${s}`).classList.add('hidden'));
  $(`#screen-${name}`).classList.remove('hidden');
  
  if (name === 'lobby') {
    renderLobby();
    gsap.fromTo(".room-card", { opacity: 0, y: 50, filter: "blur(10px)" }, { opacity: 1, y: 0, filter: "blur(0px)", duration: 1.2, stagger: 0.08, ease: "expo.out" });
  } else if (name === 'room') {
    initRoom();
    gsap.fromTo(".user-item", { opacity: 0, x: -30, filter: "blur(5px)" }, { opacity: 1, x: 0, filter: "blur(0px)", duration: 0.8, stagger: 0.05, ease: "expo.out" });
    gsap.fromTo(".timer-display", { scale: 0.8, opacity: 0 }, { scale: 1, opacity: 1, duration: 1.5, ease: "elastic.out(1, 0.75)" });
  }
}

function renderLobby() {
  const list = $('#room-list');
  list.innerHTML = '';
  
  const bentoClasses = ['bento-span-8 featured', 'bento-span-4', 'bento-span-4', 'bento-span-6', 'bento-span-6'];
  const langFlags = { en: "🇬🇧 EN", ja: "🇯🇵 JA", zh: "🇨🇳 ZH" };
  
  MOCK_ROOMS.forEach((room, index) => {
    if (index >= 5) return;
    
    const isEnded = room.status === 'ENDED';
    const btn = isEnded ? `<button class="btn-join" disabled>ENDED</button>` : `<button class="btn-join" onclick="joinRoom(${room.id}, '${room.name}')">JOIN</button>`;
    const statusCls = room.status === 'SCHEDULED' ? 'scheduled' : '';
    const extraClass = bentoClasses[index] || 'bento-span-4';
    
    const imgBg = room.image ? `<img class="card-bg-img" src="${room.image}" alt="">` : '';
    const langBadge = `<span class="card-level" style="margin-left: 8px;">${langFlags[room.lang] || room.lang.toUpperCase()}</span>`;
    
    list.innerHTML += `
      <div class="room-card ${extraClass}">
        ${imgBg}
        <div class="card-top">
          <div>
            <div class="card-title">${room.name}</div>
            <span class="card-level">${room.level}</span>
            ${langBadge}
          </div>
          <div class="card-status ${statusCls}">${room.status}</div>
        </div>
        <div class="card-desc">${room.desc}</div>
        <div class="card-bottom">
          <div class="card-users">[ ${room.users} USERS ]</div>
          ${btn}
        </div>
      </div>
    `;
  });
}

function joinRoom(id, name) {
  const room = MOCK_ROOMS.find(r => r.id === id);
  const targetLang = room ? room.lang : "en";
  
  // Transition curtain sweep when entering a room of a different language!
  const curtain = document.getElementById('curtain-transition');
  gsap.timeline()
    .to(curtain, { y: "0%", duration: 0.5, ease: "power2.inOut" })
    .call(() => {
      state.currentLang = targetLang;
      state.activeLang = targetLang;
      
      // Update switcher active state
      document.querySelectorAll('.lang-btn').forEach(b => {
        if (b.dataset.lang === targetLang) b.classList.add('active');
        else b.classList.remove('active');
      });
      
      // Change body class
      document.body.className = `theme-${targetLang}`;
      
      // Load particles
      initThemeParticles(targetLang);
      
      // Load translations
      applyTranslations(targetLang);
      
      // Prepare room variables
      $('#bottom-room-name').textContent = name;
      state.timeRemaining = TIMER_SECONDS;
      state.currentSublevelIndex = 0;
      state.isHandRaised = false;
      state.isMicOn = true;
      state.users[0].handRaised = false;
      state.users[0].mic = true;
      state.users[0].speaking = true;
      
      // Reset controls
      $('#btn-raise-hand').classList.remove('active');
      $('#btn-raise-hand').innerHTML = `<span class="btn-txt">${TRANSLATIONS[targetLang].btn_raise_hand}</span>`;
      $('#btn-toggle-mic').classList.remove('off');
      $('#icon-mic-on').classList.remove('hidden');
      $('#icon-mic-off').classList.add('hidden');
      
      switchScreen('room');
    })
    .to(curtain, { y: "100%", duration: 0.5, ease: "power2.inOut" })
    .set(curtain, { y: "-100%" });
}

function initRoom() {
  renderUsers();
  renderProgress();
  renderHints();
  renderVocab();
  updateTimer();
  
  if (state.timerInterval) {
    clearInterval(state.timerInterval);
  }
  
  state.timerInterval = setInterval(() => {
    state.timeRemaining--;
    updateTimer();
    
    if (state.timeRemaining <= 0) {
      clearInterval(state.timerInterval);
      switchScreen('ended');
      showToast(TRANSLATIONS[state.activeLang].toast_session_finished);
    }
  }, 1000);
}

function renderUsers() {
  const list = $('#active-users');
  list.innerHTML = '';
  $('#user-count').textContent = state.users.length;
  $('#bottom-user-count').textContent = state.users.length;
  
  state.users.forEach(u => {
    const spkCls = u.speaking ? 'speaking' : '';
    const hndCls = u.handRaised ? 'raised-hand' : '';
    const micIco = u.mic ? '<i class="ph ph-microphone icon"></i>' : '<i class="ph ph-microphone-slash icon"></i>';
    
    list.innerHTML += `
      <div class="user-item ${spkCls} ${hndCls}">
        <img class="u-avatar" src="https://api.dicebear.com/9.x/notionists/svg?seed=${u.name}" alt="">
        <div class="u-info">
          <div class="u-name">${u.name}</div>
          <div class="u-role">${u.role.toUpperCase()}</div>
        </div>
        <div class="u-mic ${u.mic ? '' : 'off'}">${micIco}</div>
      </div>
    `;
  });
}

function renderProgress() {
  const t = TRANSLATIONS[state.activeLang];
  $('#step-num').textContent = state.currentSublevelIndex + 1;
  $('#current-sublevel').textContent = t.sub_levels[state.currentSublevelIndex];
  
  const prog = $('#sublevel-progress');
  prog.innerHTML = '';
  t.sub_levels.forEach((_, i) => {
    let cls = 'prog-step';
    if (i < state.currentSublevelIndex) cls += ' done';
    if (i === state.currentSublevelIndex) cls += ' active';
    prog.innerHTML += `<div class="${cls}"></div>`;
  });
}

function renderHints() {
  const hints = TRANSLATIONS[state.activeLang].hints[state.currentSublevelIndex] || [];
  const container = $('#mod-hints');
  if (container) {
    container.innerHTML = hints.map(h => `<div class="hint-box">${h}</div>`).join('');
  }
}

function renderVocab() {
  const words = TRANSLATIONS[state.activeLang].vocab[state.currentSublevelIndex] || [];
  const container = $('#vocab-list');
  if (container) {
    container.innerHTML = words.map(w => `
      <div class="vocab-card">
        <div class="vocab-word-row">
          <span class="vocab-word">${w.word}</span>
          <span class="vocab-type">${w.type}</span>
          <span class="vocab-ipa">${w.ipa}</span>
        </div>
        <div class="vocab-definition">${w.definition}</div>
      </div>
    `).join('');
    gsap.fromTo(".vocab-card", { opacity: 0, x: 20 }, { opacity: 1, x: 0, duration: 0.5, stagger: 0.08, ease: "expo.out" });
  }
}

function updateTimer() {
  if (state.timeRemaining < 0) state.timeRemaining = 0;
  const m = Math.floor(state.timeRemaining / 60);
  const s = state.timeRemaining % 60;
  $('#timer-display').textContent = `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
  
  const pct = state.timeRemaining / TIMER_SECONDS;
  $('#timer-progress').style.strokeDashoffset = CIRCLE_CIRC - (pct * CIRCLE_CIRC);
}

// ==========================================================================
// INTERACTIVE EVENT LISTENERS
// ==========================================================================
document.addEventListener('DOMContentLoaded', () => {
  // Setup click listener for dynamic language switching buttons
  $('#lang-switcher').addEventListener('click', e => {
    const btn = e.target.closest('.lang-btn');
    if (!btn || btn.classList.contains('active')) return;
    
    const targetLang = btn.dataset.lang;
    const curtain = document.getElementById('curtain-transition');
    
    gsap.timeline()
      .to(curtain, { y: "0%", duration: 0.5, ease: "power2.inOut" })
      .call(() => {
        // Toggle active button
        $$('.lang-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        // Swap stylesheet theme class on body
        document.body.className = `theme-${targetLang}`;
        
        // Clear & Load theme particles
        initThemeParticles(targetLang);
        
        // Translate entire app copy
        applyTranslations(targetLang);
      })
      .to(curtain, { y: "100%", duration: 0.5, ease: "power2.inOut" })
      .set(curtain, { y: "-100%" });
  });

  // Filter lobby group
  $('#filter-group').addEventListener('click', e => {
    if (!e.target.classList.contains('filter-pill')) return;
    $$('.filter-pill').forEach(p => p.classList.remove('active'));
    e.target.classList.add('active');
    state.activeFilter = e.target.dataset.level;
    renderLobby();
  });

  // Raise hand interaction
  $('#btn-raise-hand').addEventListener('click', function() {
    const t = TRANSLATIONS[state.activeLang];
    state.isHandRaised = !state.isHandRaised;
    if (state.isHandRaised) {
      this.classList.add('active'); 
      this.innerHTML = `<span class="btn-txt">${t.btn_hand_raised}</span>`;
      state.users[0].handRaised = true;
    } else {
      this.classList.remove('active'); 
      this.innerHTML = `<span class="btn-txt">${t.btn_raise_hand}</span>`;
      state.users[0].handRaised = false;
    }
    renderUsers();
  });

  // Toggle microphone
  $('#btn-toggle-mic').addEventListener('click', function() {
    state.isMicOn = !state.isMicOn;
    if (state.isMicOn) {
      this.classList.remove('off');
      $('#icon-mic-on').classList.remove('hidden'); $('#icon-mic-off').classList.add('hidden');
      state.users[0].mic = true; state.users[0].speaking = true;
    } else {
      this.classList.add('off');
      $('#icon-mic-on').classList.add('hidden'); $('#icon-mic-off').classList.remove('hidden');
      state.users[0].mic = false; state.users[0].speaking = false;
    }
    renderUsers();
  });

  // Disconnect overlays
  $('#btn-leave-room').addEventListener('click', () => $('#leave-dialog').classList.add('active'));
  $('#btn-cancel-leave').addEventListener('click', () => $('#leave-dialog').classList.remove('active'));
  $('#btn-confirm-leave').addEventListener('click', () => {
    $('#leave-dialog').classList.remove('active');
    if (state.timerInterval) {
      clearInterval(state.timerInterval);
    }
    switchScreen('ended');
  });

  $('#btn-back-lobby').addEventListener('click', () => switchScreen('lobby'));
  $('#btn-join-other').addEventListener('click', () => switchScreen('lobby'));

  // Next topic advancement
  $('#btn-next-sublevel').addEventListener('click', () => {
    const t = TRANSLATIONS[state.activeLang];
    state.currentSublevelIndex++;
    if (state.currentSublevelIndex >= t.sub_levels.length) {
      if (state.timerInterval) {
        clearInterval(state.timerInterval);
      }
      switchScreen('ended');
      showToast(t.toast_topics_completed);
    } else {
      renderProgress();
      renderHints();
      renderVocab();
      showToast(`${t.btn_next_topic.replace(' →', '')}: ${t.sub_levels[state.currentSublevelIndex]}`);
    }
  });

  // Toggle record button
  $('#btn-toggle-record').addEventListener('click', function() {
    const t = TRANSLATIONS[state.activeLang];
    state.isRecording = !state.isRecording;
    if (state.isRecording) {
      this.classList.remove('outline');
      this.innerHTML = t.btn_recording;
      this.style.color = 'var(--danger)';
      this.style.borderColor = 'var(--danger)';
      showToast(t.toast_recording_started);
    } else {
      this.classList.add('outline');
      this.innerHTML = t.btn_record;
      this.style.color = '';
      this.style.borderColor = '';
      showToast(t.toast_recording_saved);
    }
  });

  // Initial setup and startup animations
  switchScreen('lobby');
  applyTranslations('en');
  initThemeParticles('en');
  
  gsap.fromTo(".glow-blob", { opacity: 0, scale: 0.8 }, { opacity: 0.12, scale: 1, duration: 3, ease: "power2.out", stagger: 0.3 });
  gsap.from(".hero-content > *", { opacity: 0, y: 55, filter: "blur(10px)", duration: 1.4, stagger: 0.12, ease: "expo.out" });
  gsap.from(".hero-visual", { opacity: 0, scale: 0.96, filter: "blur(15px)", duration: 1.8, delay: 0.2, ease: "expo.out" });
});

// Toast System
function showToast(msg) {
  const container = $('#toast-container');
  if (!container) return;
  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.textContent = msg;
  container.appendChild(toast);
  gsap.fromTo(toast, { opacity: 0, y: 20 }, { opacity: 1, y: 0, duration: 0.3 });
  setTimeout(() => {
    gsap.to(toast, { opacity: 0, y: -20, duration: 0.3, onComplete: () => toast.remove() });
  }, 3000);
}
