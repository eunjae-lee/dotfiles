const { exec } = require("shelljs");
const clipboardy = require("clipboardy");
const applescript = require("applescript");
const fs = require("fs");
const path = require("path");
const dotenv = require("dotenv");
const fetch = require("node-fetch");
dotenv.config({ path: path.join(__dirname, "..", "..", ".env") });

const readClipboard = () => clipboardy.readSync();

const writeToClipboard = (text) => clipboardy.writeSync(text);

const runShellScript = (script, opts = { printError: true }) => {
  const result = exec(script, { silent: true, ...opts });
  if (opts.printError) {
    console.log(result.stderr);
  }
  return result;
};

const runAppleScript = (script) =>
  new Promise((resolve, reject) => {
    applescript.execString(script, (err, result) => {
      if (err) {
        reject(err);
      } else {
        resolve(result);
      }
    });
  });

const getFrontMostApp = async () => {
  const result = await runAppleScript(`
    tell application "System Events"
      set frontApp to first application process whose frontmost is true
      set appName to name of frontApp
      set processId to unix id of frontApp
      tell process appName
        tell (1st window whose value of attribute "AXMain" is true)
          set windowTitle to value of attribute "AXTitle"
          set documentPath to value of attribute "AXDocument"
        end tell
      end tell
      return {appName, processId, windowTitle, documentPath}
    end tell
  `);
  const [appName, processId, windowTitle, documentPath] = result;
  return { appName, processId, windowTitle, documentPath };
};

const addContextualCommand = (context, filename) => {
  fs.copyFileSync(
    path.join(__dirname, "..", "raycast", "pool", filename),
    path.join(__dirname, "..", "raycast", `context-${context}`, filename)
  );
};

const clearContextualCommands = (context) => {
  exec(`rm -f *.{js,sh}`, {
    cwd: path.join(__dirname, "..", "raycast", `context-${context}`),
  });
};

const setContextualCommands = (context, filenamesToSet) => {
  const dir = path.join(__dirname, "..", "raycast", `context-${context}`);
  const alreadyExistingFiles = fs
    .readdirSync(dir)
    .filter((filename) => filename !== ".gitkeep");
  const filesToRemove = alreadyExistingFiles.filter(
    (filename) => !filenamesToSet.includes(filename)
  );
  const filesToAdd = filenamesToSet.filter(
    (filename) => !alreadyExistingFiles.includes(filename)
  );

  filesToAdd.forEach((filename) => addContextualCommand(context, filename));
  filesToRemove.forEach((filename) => fs.unlinkSync(path.join(dir, filename)));
};

const slack = ({
  text,
  channel = "#general",
  username = "bot",
  iconEmoji = ":ghost:",
}) => {
  fetch(process.env.SLACK_INCOMING_HOOK, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      channel,
      username,
      text,
      icon_emoji: iconEmoji,
    }),
  });
};

const config = {
  homedir: "/Users/eunjae.lee",
  workspace: "/Users/eunjae.lee/workspace",
  sandbox: "/Users/eunjae.lee/sandbox",
};

module.exports = {
  readClipboard,
  writeToClipboard,
  runShellScript,
  runAppleScript,
  getFrontMostApp,
  addContextualCommand,
  clearContextualCommands,
  setContextualCommands,
  config,
  slack,
};
