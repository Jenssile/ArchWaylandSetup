#!/bin/bash

PKG_FILE="packages.txt"

if [[ ! -f "$PKG_FILE" ]]; then
	echo "ERROR: Package file '$PKG_FILE' not found."
	exit 1
fi

IFS=',' read -ra ALL_PKG <<< "$(tr -d ' \n' < "$PKG_FILE")"

# Display menu
echo "Available packages:"
for i in "${!ALL_PKG[@]}"; do
	printf "%2d) %s\n" $((i+1)) "${ALL_PKG[$i]}"
done

echo
read -p "Enter nubers of packages to install (e.g., 1 2 5), or 'a' to install all: " SELECTION

if [[ "$SELECTION" == "a" || "$SELECTION" == "A" ]]; then
	SELECTED_PKGS=("${ALL_PKG[@]})
else
	SELECTED_PKGS=()
	for index in $SELECTION; do
		if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= ${#ALL_PKG[@]} )); then
			SELECTED_PKGS+=("${ALL_PKG[$((index-1))]}")
		else
			echo "Invalid selection $index"
		fi
	done
fi

if  [[ ${#SELECTED_PKGS[@]} -eq 0 ]]; then
	echo "No valid packages selected. Exiting."
	exit 1
fi

echo "Installing: ${SELECTED_PKGS[*]}"
sudo pacman -Syu --noconfirm --needed "${SELECTED_PKGS[@]}"
