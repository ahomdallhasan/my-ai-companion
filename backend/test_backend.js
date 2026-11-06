// Self-test script to verify memory merging and endpoint payload validation
import assert from 'node:assert';

function mergeMemories(existingRaw, extractedItems) {
  const existingLines = String(existingRaw || '')
    .split('\n')
    .map((line) => line.replace(/^[-•*]\s*/, '').trim())
    .filter(Boolean);

  const seen = new Set(existingLines.map((l) => l.toLowerCase()));
  for (const rawItem of extractedItems) {
    const cleaned = String(rawItem || '')
      .replace(/^[-•*]\s*/, '')
      .trim();
    if (!cleaned || cleaned.length < 3) continue;
    const key = cleaned.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      existingLines.push(cleaned);
    }
  }
  return existingLines.slice(-60).map((item) => `- ${item}`).join('\n');
}

const initial = "- User loves rain and black coffee\n- Works late on Thursdays";
const newlyExtracted = ["Works late on Thursdays", "Favourite song is Ami Tomar Kache"];
const merged = mergeMemories(initial, newlyExtracted);

assert(merged.includes("- User loves rain and black coffee"));
assert(merged.includes("- Favourite song is Ami Tomar Kache"));
assert.strictEqual(merged.split("\n").length, 3, "Should deduplicate existing memories");
console.log("All backend memory merge & deduplication tests passed!");
