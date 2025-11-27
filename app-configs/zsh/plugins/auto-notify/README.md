# Auto-Notify Plugin

A minimalized zsh plugin that automatically runs the `ding` command when a long-running task completes.

Based on [zsh-auto-notify](https://github.com/MichaelAquilina/zsh-auto-notify) by Michael Aquilina.

## Features

- Automatically triggers `ding` command after commands that take longer than a threshold
- Configurable threshold (default: 10 seconds)
- Blacklist/whitelist support for ignoring specific commands
- Simple and lightweight implementation

## Installation

### oh-my-zsh

Add this plugin to your `.zshrc`:

```zsh
plugins=(auto-notify $plugins)
```

Make sure the line is **before** `source $ZSH/oh-my-zsh.sh`.

### Manual

Source the plugin in your `.zshrc`:

```zsh
source /path/to/auto-notify/auto-notify.plugin.zsh
```

## Configuration

### Notification Threshold

Set how long a command must run before triggering `ding` (in seconds):

```zsh
export AUTO_NOTIFY_THRESHOLD=20  # Default: 10
```

### Ignored Commands

By default, the following commands are ignored:

- vim, nvim
- less, more, man
- watch
- git commit
- top, htop
- ssh
- nano

You can add more commands to ignore:

```zsh
AUTO_NOTIFY_IGNORE+=("docker" "kubectl")
```

Or completely redefine the ignore list:

```zsh
export AUTO_NOTIFY_IGNORE=("vim" "nvim" "ssh")
```

### Whitelist Approach

Instead of blacklisting, you can use a whitelist:

```zsh
export AUTO_NOTIFY_WHITELIST=("npm" "cargo" "make" "pytest")
```

When `AUTO_NOTIFY_WHITELIST` is set, only commands in the whitelist will trigger notifications.

## Usage

### Temporarily Disable/Enable

Disable notifications:

```zsh
disable_auto_notify
```

Re-enable notifications:

```zsh
enable_auto_notify
```

## Requirements

- zsh
- `ding` command must be available in PATH
