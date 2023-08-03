#!/usr/bin/env node

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Tweet Date to ISO Date
// @raycast.mode compact

// Optional parameters:
// @raycast.icon 🤖
// @raycast.argument1 { "type": "text", "placeholder": "Placeholder" }

// Documentation:
// @raycast.author Eunjae Lee

const tweetDate = process.argv.slice(2)[0];
// const tweetDate = "6:45 PM · Aug 23, 2022";
const [hour, date] = tweetDate.split(" · ");
console.log(new Date(`${date} ${hour}`).toISOString());
