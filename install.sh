#!/bin/bash

# Default values
VERBOSE=false
DRY_RUN=false
USERNAME="jeeb"
SRC_CONFIG_DIR="./configs"
HYPRLAND_CONFIG_DIR="/home/$USERNAME/.config/hypr"
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

compare_versions() {
	# Returns 0 if $1 >= $2
	[[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
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
SDDM_VERSION=$(sddm --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

if [[ -z "$SDDM_VERSION" ]];; then
	echo "faild to detect SDDM version."
	exit 1
fi

log "Detected SDDM version: $SDDM_VERSION"

if ! compare_versions "$SDDM_VERSION" "$SDDM_MIN_VERSION"; then
	echo "!!!! SDDM version $SDDM_VERSION is less than the requierd $SDDM_MIN_VERSION"
	exit 1
fi

### Configure SDDM autologin
SDDM_CONF="/etc/sddm.conf"

run_cmd "sudo tocuh $SDDM_CONF"

if ! grep -q '^\[Autologin\]' "$SDDM_CONF"; then
	run_cmd "echo -e '\n[Autologin]\nUser=$USERNAME\nSession=Hyprland' | sudo tee -a $SDDM_CONF"
else
	run_cmd "sudo sed -i '/^\[Autologin\]/,/^\[/{s/^User=.*/User=$USERNAME/;s/^Session=Hyprland/}' $SDDM_CONF"
fi

run_cmd "cp -r $SRC_CONFIG_DIR/* $HYPRLAND_CONFIG_DIR/"
run_cmd "chown -R $USERNAME:$USERNAME $HYPRLAND_CONFIG_DIR"
