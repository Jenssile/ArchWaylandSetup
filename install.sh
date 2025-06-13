#!/bin/bash

# Default values
VERBOSE=false

# Help message
print_help() {
	echo "Usage: $0 [OPTIONS]"
	echo
	echo "Options:"
	echo "  -v, --verbose	Enable verbose output"
	echo "  -h, --help	Show this help message and exit"
}

# input flag parseing
while [[ "$#" -gt 0 ]]; do
	case "$1" in
		-[!-]*)
			# handle combiend short hand options like -vh
			for (( i=1; i<${#1}; i++ )); do
				case "${1:$i:1}" in
					v) VERBOSE=true ;;
					h) print_help; exit 0;;
					*) echo "Unknown option: -${1:$i:1}"; print_help; exit 1;;
				esac
			done
			;;
		--verbose)
			VERBOSE=true
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

if $VERBOSE; then
	echo "Verbose output enabled."
fi

ehco "rest of scrit from here"
