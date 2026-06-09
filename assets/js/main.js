// Data Mocks
const MOCK_USERS = [
  { id: 1, name: "Minh Tú", role: "moderator", mic: true, speaking: true, handRaised: false },
  { id: 2, name: "Lan Anh", role: "pro", mic: true, speaking: false, handRaised: false },
  { id: 3, name: "Guest_03", role: "anonymous", mic: false, speaking: false, handRaised: false },
  { id: 4, name: "Hoàng Duy", role: "pro", mic: false, speaking: false, handRaised: true },
  { id: 5, name: "Thanh Mai", role: "pro", mic: true, speaking: false, handRaised: false }
];

const MOCK_ROOMS = [
  { id: 101, name: "Morning Conversation", level: "B1", users: 5, status: "LIVE", desc: "Luyện phản xạ với chủ đề đời thường. Tập trung vào trôi chảy và tự nhiên.", image: "https://picsum.photos/seed/room-morning/800/600" },
  { id: 102, name: "Beginner Talk", level: "A1", users: 2, status: "LIVE", desc: "Dành cho người mới bắt đầu. Tốc độ chậm.", image: null },
  { id: 103, name: "Advanced Discussion", level: "B2", users: 0, status: "SCHEDULED", desc: "Thảo luận sâu về thời sự và văn hoá. Bắt đầu lúc 14:00.", image: null },
  { id: 104, name: "Daily Vocabulary", level: "A2", users: 8, status: "LIVE", desc: "Học từ vựng qua tình huống thực tế, có flashcard đính kèm.", image: null },
  { id: 105, name: "IELTS Speaking Club", level: "B2", users: 0, status: "ENDED", desc: "Luyện Part 2 & 3 cùng examiner ảo. Đã kết thúc.", image: null }
];

const SUB_LEVELS = ["Greeting Strangers", "Daily Routines", "Travel Stories", "Future Plans"];
const TIMER_SECONDS = 10 * 60;
const CIRCLE_CIRC = 2 * Math.PI * 95;

const state = {
  activeFilter: "",
  currentScreen: "lobby",
  users: [...MOCK_USERS],
  timeRemaining: TIMER_SECONDS,
  currentSublevelIndex: 0,
  isMicOn: true,
  isHandRaised: false,
  timerInterval: null,
  isRecording: false
};

const MOCK_HINTS = [
  ["Giới thiệu bản thân ngắn gọn bằng tiếng Anh.", "Hỏi thăm đối phương về ngày hôm nay của họ.", "Giữ giọng điệu cởi mở, lịch sự."],
  ["Kể về thói quen buổi sáng của bạn.", "Thảo luận về thời gian học tập / làm việc lý tưởng.", "So sánh thói quen ngày thường và cuối tuần."],
  ["Chia sẻ về một chuyến đi đáng nhớ nhất của bạn.", "Bạn thích đi du lịch bằng phương tiện gì và tại sao?", "Gợi ý 1 điểm đến thú vị cho người khác."],
  ["Mục tiêu nghề nghiệp/học tập của bạn trong 5 năm tới.", "Kỹ năng mới nào bạn đang muốn học hỏi nhất?", "Chia sẻ kế hoạch hành động cụ thể để đạt mục tiêu."]
];

const MOCK_VOCAB = [
  [
    { word: "Initiate", type: "v", definition: "Bắt đầu (cuộc hội thoại)", ipa: "/ɪˈnɪʃ.i.eɪt/" },
    { word: "Cordial", type: "adj", definition: "Thân ái, chân thành", ipa: "/ˈkɔːr.dʒəl/" },
    { word: "Anonymity", type: "n", definition: "Sự ẩn danh", ipa: "/ˌæn.əˈnɪm.ə.t̬i/" }
  ],
  [
    { word: "Productive", type: "adj", definition: "Năng suất, hiệu quả", ipa: "/prəˈdʌk.tɪv/" },
    { word: "Juggling", type: "v", definition: "Cân bằng nhiều công việc", ipa: "/ˈdʒʌɡ.lɪŋ/" },
    { word: "Monotonous", type: "adj", definition: "Đơn điệu, tẻ nhạt", ipa: "/məˈnɑː.t̬ən.əs/" }
  ],
  [
    { word: "Wanderlust", type: "n", definition: "Lòng cuồng đi, thích du lịch", ipa: "/ˈwɑːn.dɚ.lʌst/" },
    { word: "Picturesque", type: "adj", definition: "Đẹp như tranh vẽ", ipa: "/ˌpɪk.tʃərˈesk/" },
    { word: "Itinerary", type: "n", definition: "Lộ trình chuyến đi", ipa: "/aɪˈtɪn.ə.rer.i/" }
  ],
  [
    { word: "Aspiration", type: "n", definition: "Khát vọng, nguyện vọng", ipa: "/ˌæs.pəˈreɪ.ʃən/" },
    { word: "Feasible", type: "adj", definition: "Khả thi, thực hiện được", ipa: "/ˈfiː.zə.bəl/" },
    { word: "Manifest", type: "v", definition: "Biểu hiện, hiện thực hóa", ipa: "/ˈmæn.ə.fest/" }
  ]
];

const $ = sel => document.querySelector(sel);
const $$ = sel => document.querySelectorAll(sel);

function switchScreen(name) {
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
  
  // FIX: Force to 5 items to fit Bento Grid perfectly
  // The layout spans: item 0 -> 8, item 1 -> 4, item 2 -> 4, item 3 -> 4, item 4 -> 4.
  // Wait, 8+4 = 12 (Row 1+2 left and right).
  // Actually:
  // Item 0: col-span-8 row-span-2 (Takes 8 cols, 2 rows)
  // Item 1: col-span-4 row-span-1 (Takes 4 cols, 1 row, sits right of Item 0 top)
  // Item 2: col-span-4 row-span-1 (Takes 4 cols, 1 row, sits right of Item 0 bottom)
  // Item 3: col-span-6 row-span-1 (Takes 6 cols below)
  // Item 4: col-span-6 row-span-1 (Takes 6 cols below)
  // Total 5 items form a perfect gapless rectangle grid.
  
  const bentoClasses = ['bento-span-8 featured', 'bento-span-4', 'bento-span-4', 'bento-span-6', 'bento-span-6'];
  
  MOCK_ROOMS.forEach((room, index) => {
    if (index >= 5) return; // Keep it tight
    
    const isEnded = room.status === 'ENDED';
    const btn = isEnded ? `<button class="btn-join" disabled>ENDED</button>` : `<button class="btn-join" onclick="joinRoom(${room.id}, '${room.name}')">JOIN</button>`;
    const statusCls = room.status === 'SCHEDULED' ? 'scheduled' : '';
    const extraClass = bentoClasses[index] || 'bento-span-4';
    
    const imgBg = room.image ? `<img class="card-bg-img" src="${room.image}" alt="">` : '';
    
    list.innerHTML += `
      <div class="room-card ${extraClass}">
        ${imgBg}
        <div class="card-top">
          <div>
            <div class="card-title">${room.name}</div>
            <span class="card-level">${room.level}</span>
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
  $('#bottom-room-name').textContent = name;
  state.timeRemaining = TIMER_SECONDS;
  state.currentSublevelIndex = 0;
  state.isHandRaised = false;
  state.isMicOn = true;
  state.users[0].handRaised = false;
  state.users[0].mic = true;
  state.users[0].speaking = true;
  
  // Reset buttons to original state
  $('#btn-raise-hand').classList.remove('active');
  $('#btn-raise-hand').innerHTML = '<span class="btn-txt">RAISE HAND</span>';
  $('#btn-toggle-mic').classList.remove('off');
  $('#icon-mic-on').classList.remove('hidden');
  $('#icon-mic-off').classList.add('hidden');
  
  switchScreen('room');
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
    
    // Auto end when timer hits 0
    if (state.timeRemaining <= 0) {
      clearInterval(state.timerInterval);
      switchScreen('ended');
      showToast("Session finished.");
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
  $('#step-num').textContent = state.currentSublevelIndex + 1;
  $('#current-sublevel').textContent = SUB_LEVELS[state.currentSublevelIndex];
  
  const prog = $('#sublevel-progress');
  prog.innerHTML = '';
  SUB_LEVELS.forEach((_, i) => {
    let cls = 'prog-step';
    if (i < state.currentSublevelIndex) cls += ' done';
    if (i === state.currentSublevelIndex) cls += ' active';
    prog.innerHTML += `<div class="${cls}"></div>`;
  });
}

function renderHints() {
  const hints = MOCK_HINTS[state.currentSublevelIndex] || [];
  const container = $('#mod-hints');
  if (container) {
    container.innerHTML = hints.map(h => `<div class="hint-box">${h}</div>`).join('');
  }
}

function renderVocab() {
  const words = MOCK_VOCAB[state.currentSublevelIndex] || [];
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
  if(state.timeRemaining < 0) state.timeRemaining = 0;
  const m = Math.floor(state.timeRemaining / 60);
  const s = state.timeRemaining % 60;
  $('#timer-display').textContent = `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
  
  const pct = state.timeRemaining / TIMER_SECONDS;
  $('#timer-progress').style.strokeDashoffset = CIRCLE_CIRC - (pct * CIRCLE_CIRC);
}

// Events
$('#filter-group').addEventListener('click', e => {
  if(!e.target.classList.contains('filter-pill')) return;
  $$('.filter-pill').forEach(p => p.classList.remove('active'));
  e.target.classList.add('active');
  state.activeFilter = e.target.dataset.level;
  renderLobby();
});

$('#btn-raise-hand').addEventListener('click', function() {
  state.isHandRaised = !state.isHandRaised;
  if(state.isHandRaised) {
    this.classList.add('active'); this.innerHTML = '<span class="btn-txt">HAND RAISED</span>';
    state.users[0].handRaised = true;
  } else {
    this.classList.remove('active'); this.innerHTML = '<span class="btn-txt">RAISE HAND</span>';
    state.users[0].handRaised = false;
  }
  renderUsers();
});

$('#btn-toggle-mic').addEventListener('click', function() {
  state.isMicOn = !state.isMicOn;
  if(state.isMicOn) {
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

// System Console Handlers
$('#btn-next-sublevel').addEventListener('click', () => {
  state.currentSublevelIndex++;
  if (state.currentSublevelIndex >= SUB_LEVELS.length) {
    if (state.timerInterval) {
      clearInterval(state.timerInterval);
    }
    switchScreen('ended');
    showToast("All topics completed!");
  } else {
    renderProgress();
    renderHints();
    renderVocab();
    showToast(`Advanced to: ${SUB_LEVELS[state.currentSublevelIndex]}`);
  }
});

$('#btn-toggle-record').addEventListener('click', function() {
  state.isRecording = !state.isRecording;
  if(state.isRecording) {
    this.classList.remove('outline');
    this.innerHTML = '● RECORDING';
    this.style.color = 'var(--danger)';
    this.style.borderColor = 'var(--danger)';
    showToast('Session recording started.');
  } else {
    this.classList.add('outline');
    this.innerHTML = '● RECORD';
    this.style.color = '';
    this.style.borderColor = '';
    showToast('Recording saved to system console.');
  }
});

// Toast system
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



document.addEventListener('DOMContentLoaded', () => {
  switchScreen('lobby');
  // Entrance animation for Hero and decorative glow elements
  gsap.fromTo(".glow-blob", { opacity: 0, scale: 0.8 }, { opacity: 0.12, scale: 1, duration: 3, ease: "power2.out", stagger: 0.3 });
  gsap.from(".hero-content > *", { opacity: 0, y: 55, filter: "blur(10px)", duration: 1.4, stagger: 0.12, ease: "expo.out" });
  gsap.from(".hero-visual", { opacity: 0, scale: 0.96, filter: "blur(15px)", duration: 1.8, delay: 0.2, ease: "expo.out" });
});
