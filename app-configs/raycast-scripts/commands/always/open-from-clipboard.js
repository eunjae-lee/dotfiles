#!/usr/bin/env node

// @raycast.title Open from clipboard
// @raycast.mode compact
// @raycast.schemaVersion 1

const open = require("open");
const { readClipboard } = require("../../lib");

const clipboard = readClipboard();

clipboard
  .trim()
  .split("\n")
  .forEach((line) => open(line));
