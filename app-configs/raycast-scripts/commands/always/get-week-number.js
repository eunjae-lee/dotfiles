#!/usr/bin/env node

// @raycast.title Get Week Number
//
// @raycast.mode inline
// @raycast.icon 🗓
// @raycast.schemaVersion 1

const currentDate = new Date();
const startDate = new Date(currentDate.getFullYear(), 0, 1);
const days = Math.floor((currentDate - startDate) / (24 * 60 * 60 * 1000));

const weekNumber = Math.ceil(days / 7);

console.log(weekNumber);
