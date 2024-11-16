#!/bin/zsh
npm install pm2@latest -g
cd app-configs/cli && pm2 start ecosystem.config.js
pm2 startup
