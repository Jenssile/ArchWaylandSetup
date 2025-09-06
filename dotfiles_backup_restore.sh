#!/bin/bash

# ============================
# CONFIG + LOGGING SETUP
# ============================

CONFIG_PATH="$HOME/.config/dotfiles_backup/config"
LOG_FORMAT="yaml"
LOG_FILE="$HOME/.dotfiles_backup.log"
LOG_MAX_FILES=5
LOG_ROTATION_ENABLED=true

load_config() {
    if [[ -f "$CONFIG_PATH" ]]; then
        while IFS=": " read -r key value; do
            case "$key" in
                log_format) LOG_FORMAT="${value,,}" ;;
                log_file) LOG_FILE="${value/#\~/$HOME}" ;;
                log_max_files) LOG_MAX_FILES="$value" ;;
                log_rotation_enabled) LOG_ROTATION_ENABLED="${value,,}" ;;
            esac
        done < <(grep -Ev '^\s*#|^\s*$' "$CONFIG_PATH")
    fi
}

rotate_logs() {
    [[ "$LOG_ROTATION_ENABLED" != "true" ]] && return

    for ((i=LOG_MAX_FILES-1; i>=1; i--)); do
        [[ -f "$LOG_FILE.$i" ]] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
    done

    [[ -f "$LOG_FILE" ]] && mv "$LOG_FILE" "$LOG_FILE.1"
}

log() {
    local msg="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    if [[ "$LOG_FORMAT" == "json" ]]; then
        echo "{\"timestamp\":\"$timestamp\",\"message\":\"$msg\"}" >> "$LOG_FILE"
    else
        echo "[$timestamp] $msg" >> "$LOG_FILE"
    fi
}

# ============================
# BACKUP CONFIGURATION
# ============================

CONFIG_DIRS=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/wofi"
    "$HOME/.config/kitty"
    "$HOME/.config/nvim"
    "$HOME/.config/rofi"
    "$HOME/.config/swaylock"
    "$HOME/.config/wlogout"
    "$HOME/.config/gtk-3.0"
    "$HOME/.config/gtk-4.0"
    "$HOME/.bashrc"
    "$HOME/.profile"
)

BACKUP_DIR="$HOME/backups"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# ============================
# ARG PARSING
# ============================

DRY_RUN=false
NO_MENU=false
ACTION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --no-menu) NO_MENU=true ;;
        --action) ACTION="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

load_config
rotate_logs

# ============================
# CALLER INFO LOGGING
# ============================

CALLER_PATH=$(ps -o command= --ppid $$ | awk '{print $1}')
CALLER_DISPLAY=$([[ "$CALLER_PATH" != "$0" ]] && echo "$CALLER_PATH -> $0" || echo "$0")
USER_NAME=$(whoami)
EUID_NAME=$(id -un "$EUID")
UID_VAL=$(id -u)
EUID_VAL=$EUID

log "🔧 User: $USER_NAME (UID: $UID_VAL) | Effective UID: $EUID_VAL ($EUID_NAME)"
log "📍 Caller: $CALLER_DISPLAY"
log "🚀 Action started: ${ACTION:-menu} (no-menu: $NO_MENU, dry-run: $DRY_RUN)"

# ============================
# FUNCTIONS
# ============================

perform_backup() {
    if $NO_MENU; then
        selected_dirs=("${CONFIG_DIRS[@]}")
    else
        echo "Choose directories to back up (TAB to select, ENTER to confirm):"
        selected_dirs=$(printf "%s\n" "${CONFIG_DIRS[@]}" | fzf --multi --prompt="Select directories: " --preview="ls -la {}")
        [[ -z "$selected_dirs" ]] && echo "No directories selected. Aborting." && return
    fi

    output="$BACKUP_DIR/arch_config_backup_$TIMESTAMP.tar.gz"
    echo
    echo "Would back up the following:"
    printf "%s\n" "${selected_dirs[@]}"
    echo "Would create: $output"

    if ! $DRY_RUN; then
        tar -czf "$output" -C "$HOME" $(printf "%s\n" "${selected_dirs[@]}" | sed "s|^$HOME/||")
        [[ $? -eq 0 ]] && echo "✅ Backup complete." || echo "❌ Backup failed."
    else
        echo "Dry run — no archive created."
        echo "Command would be: tar -czf \"$output\" -C \"$HOME\" [relative paths]"
    fi

    log "✅ Action completed: backup"
}

restore_latest() {
    latest_backup=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n 1)
    [[ -z "$latest_backup" ]] && echo "No backups found." && return

    echo "Would restore from latest: $latest_backup"
    echo "Command: tar -xzf \"$latest_backup\" -C \"$HOME\""

    if ! $DRY_RUN; then
        tar -xzf "$latest_backup" -C "$HOME"
        echo "✅ Restore complete."
    else
        echo "Dry run — no files restored."
    fi

    log "✅ Action completed: restore-latest"
}

restore_specific() {
    if $NO_MENU; then
        echo "❌ '--action restore-specific' cannot be used with '--no-menu'"
        exit 1
    fi

    selected_backup=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | fzf --prompt="Select backup to restore: ")
    [[ -z "$selected_backup" ]] && echo "No backup selected." && return

    file_list=$(tar -tzf "$selected_backup")
    selected_files=$(echo "$file_list" | fzf --multi --prompt="Select files/folders to restore: ")
    [[ -z "$selected_files" ]] && echo "Nothing selected." && return

    echo "Would extract:"
    echo "$selected_files"
    echo "From: $selected_backup"
    echo "To: $HOME"
    echo "Command: tar -xzf \"$selected_backup\" -C \"$HOME\" -T -"

    if ! $DRY_RUN; then
        echo "$selected_files" | tar -xzf "$selected_backup" -C "$HOME" -T -
        echo "✅ Restore complete."
    else
        echo "Dry run — no files extracted."
    fi

    log "✅ Action completed: restore-specific"
}

show_main_menu() {
    echo
    echo "1) Backup configs"
    echo "2) Restore from latest backup"
    echo "3) Restore from specific backup"
    echo "q) Quit"
    echo
    read -p "Choose an option: " option
    case "$option" in
        1) perform_backup ;;
        2) restore_latest ;;
        3) restore_specific ;;
        q|Q) echo "Goodbye!"; log "👋 User exited interactive menu"; exit 0 ;;
        *) echo "Invalid option."; show_main_menu ;;
    esac
}

# ============================
# ENTRY POINT
# ============================

if $NO_MENU; then
    case "$ACTION" in
        backup) perform_backup ;;
        restore-latest) restore_latest ;;
        restore-specific)
            echo "❌ '--action restore-specific' requires the menu."
            exit 1 ;;
        *)
            echo "⚠️ Invalid --action. Use: backup or restore-latest"
            exit 1 ;;
    esac
else
    show_main_menu
fi
