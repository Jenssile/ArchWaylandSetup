#!/usr/bin/env bash

while getopts ":h:v:" opt; do
	case ${opt} in
		h ) help=true;;
		v ) verbose=${OPTARG};;
	esac
done

