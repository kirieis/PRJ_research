const fs = require('fs');
let c = fs.readFileSync('src/app/page.tsx', 'utf-8');
c = c.replace('{ code: "en", name: "ENGLISH", localName: "CEFR Certificate", desc: "A1 to B2 Levels", flag: "????" }', '{ code: "en", name: "ENGLISH", localName: "CEFR Certificate", desc: "A1 to B2 Levels", flag: "🇬🇧" }');
c = c.replace('{ code: "ja", name: "JAPANESE", localName: "JLPT Certificate", desc: "N5 to N1 Levels", flag: "????" }', '{ code: "ja", name: "JAPANESE", localName: "JLPT Certificate", desc: "N5 to N1 Levels", flag: "🇯🇵" }');
c = c.replace('{ code: "zh", name: "CHINESE", localName: "HSK Certificate", desc: "1 to 6 Levels", flag: "????" }', '{ code: "zh", name: "CHINESE", localName: "HSK Certificate", desc: "1 to 6 Levels", flag: "🇨🇳" }');
fs.writeFileSync('src/app/page.tsx', c);
console.log('done');
