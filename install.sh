#!/bin/bash

# Default values
VERBOSE=false
DRY_RUN=false
USERNAME="jeeb"
HYPERLAND_CONFIG_DIR="/home/$USERNAME/.config/hypr"
AUTOSTART_FILE="$HYPERLAND_CONFIG_DIR/autostart.conf"
SDDM_MIN_VERSION="0.20.0"

# Help message
print_help() {
	echo "Usage: $0 [OPTIONS]"
	echo
	echo "Options:"
	echo "  -v, --verbose	Enable verbose output"
	echo "  -d, --dry-run	Show what would be doen, without doing it"
	echo "  -h, --help	Show this help message and exit"
}

log() {
	$VERBOSE && echo "$@"
}

# input flag parseing
while [[ "$#" -gt 0 ]]; do
	case "$1" in
		-[!-]*)
			# handle combiend short hand options like -vh
			for (( i=1; i<${#1}; i++ )); do
				case "${1:$i:1}" in
					v) VERBOSE=true ;;
					d) DRY_RUN=true ;;
					h) print_help; exit 0;;
					*) echo "Unknown option: -${1:$i:1}"; print_help; exit 1;;
				esac
			done
			;;
		--verbose)
			VERBOSE=true
			;;
		--dry-run)
			DRY_RUN=true
			;;
		--help)
			print_help
			exit 0
			;;
		-*)
			echo "Unknown option: $1"
			exit 1
			;;
		*)
			echo "Unexpected argument: $1"
			print_help
			exit 1
			;;
	esac
	shift
done

run_cmd() {
	if $DRY_RUN; then
		echo "[dry-run] $*"
	else
		eval "$@"
	fi
}

log "Verbose output enabled"

### Check/install dependancies
for pkg in sddm hyprland; do
	if ! command -v "$pkg" &>/dev/null; then
		log "X $pkg not found. installing ..."
		run_cmd "sudo pacman -Syu --noconfirm $pkg"
	else
		log "* $pkg is already installed."
	fi
done

### Check SDDM version (make sure its greater than or equal to 0.20.0)
