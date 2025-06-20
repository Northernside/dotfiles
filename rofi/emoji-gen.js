import fs from "fs";

const url = "https://unicode.org/Public/emoji/16.0/emoji-test.txt";

const res = await fetch(url);
if (!res.ok) throw new Error(`Failed to fetch: ${res.status} ${res.statusText}`);

const text = await res.text();
const lines = text.split("\n");

const csvLines = ["emoji,name"];

for (const line of lines) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) continue;

  const m = trimmed.match(/^([0-9A-F ]+)\s*;\s*fully-qualified\s*#\s*(.+)$/);
  if (!m) continue;

  const rest = m[2];
  const emojiMatch = rest.match(/^(\S+)/);
  if (!emojiMatch) continue;
  const emoji = emojiMatch[1];

  const nameMatch = rest.match(/E[\d.]+\s+(.+)/);
  if (!nameMatch) continue;
  const name = nameMatch[1].replace(/"/g, '""').trim();

  csvLines.push(`${emoji},${name}`);
}

fs.writeFileSync("emojis.csv", csvLines.join("\n"), "utf8");
console.log("emojis.csv generated!");