#!/usr/bin/env node

// @raycast.title Convert Time France - Brazil
//
// @raycast.mode compact
// @raycast.icon 🗓
// @raycast.schemaVersion 1
// @raycast.argument1 { "type": "text", "placeholder": "Time in France" }

import { AI, Clipboard } from "@raycast/api";

export default async function command() {
  const answer =
    await AI.ask(`Based on the given time in France's timezone, I want you to convert it to Brailian timezone time. Format the result like the following:
  
  \`\`\`
  CET: 12:00
  BRT: 08:00
  \`\`\`
`);

  await Clipboard.copy(answer);
}
