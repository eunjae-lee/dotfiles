#!/usr/bin/env zsh
# Minimalized auto-notify plugin
# Based on: https://github.com/MichaelAquilina/zsh-auto-notify

# Threshold in seconds for when to automatically trigger notification
[[ -z "$AUTO_NOTIFY_THRESHOLD" ]] && export AUTO_NOTIFY_THRESHOLD=10

# List of commands/programs to ignore
[[ -z "$AUTO_NOTIFY_IGNORE" ]] && export AUTO_NOTIFY_IGNORE=(
    'vim'
    'nvim'
    'less'
    'more'
    'man'
    'watch'
    'git commit'
    'top'
    'htop'
    'ssh'
    'nano'
)

function _is_auto_notify_ignored() {
    local command="$1"
    # Split the command if it's been piped
    local command_list=("${(@s/|/)command}")
    local target_command="${command_list[-1]}"
    # Remove leading whitespace
    target_command="$(echo "$target_command" | sed -e 's/^ *//')"

    # Remove sudo prefix if detected
    if [[ "$target_command" == "sudo "* ]]; then
        target_command="${target_command/sudo /}"
    fi

    # If whitelist is defined, use it instead of blacklist
    if [[ -n "$AUTO_NOTIFY_WHITELIST" ]]; then
        for allowed in $AUTO_NOTIFY_WHITELIST; do
            if [[ "$target_command" == "$allowed"* ]]; then
                print "no"
                return
            fi
        done
        print "yes"
    else
        for ignore in $AUTO_NOTIFY_IGNORE; do
            if [[ "$target_command" == "$ignore"* ]]; then
                print "yes"
                return
            fi
        done
        print "no"
    fi
}

function _auto_notify_send() {
    local exit_code="$?"

    if [[ -z "$AUTO_COMMAND" && -z "$AUTO_COMMAND_START" ]]; then
        return
    fi

    if [[ "$(_is_auto_notify_ignored "$AUTO_COMMAND_FULL")" == "no" ]]; then
        local current="$(date +"%s")"
        let "elapsed = current - AUTO_COMMAND_START"

        if [[ $elapsed -gt $AUTO_NOTIFY_THRESHOLD ]]; then
            # Run ding command instead of sending notification
            ding
        fi
    fi

    _auto_notify_reset_tracking
}

function _auto_notify_track() {
    AUTO_COMMAND="${1:-$2}"
    AUTO_COMMAND_FULL="$3"
    AUTO_COMMAND_START="$(date +"%s")"
}

function _auto_notify_reset_tracking() {
    unset AUTO_COMMAND_START
    unset AUTO_COMMAND_FULL
    unset AUTO_COMMAND
}

function disable_auto_notify() {
    add-zsh-hook -D preexec _auto_notify_track
    add-zsh-hook -D precmd _auto_notify_send
}

function enable_auto_notify() {
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _auto_notify_track
    add-zsh-hook precmd _auto_notify_send
}

_auto_notify_reset_tracking

# Check if ding command exists
if ! type ding > /dev/null 2>&1; then
    printf "'ding' command not found in PATH\n"
    printf "Please ensure ding is available before enabling auto-notify\n"
else
    enable_auto_notify
fi
