#!/bin/bash

set -e

ROOT_DIRS=". widgets custom_models shaders"

for root in $ROOT_DIRS; do
	for dir in $root/*; do
		echo $dir
		if [ -d "$dir" -a -f "$dir/Makefile" ]; then
			make -C "$dir"
		fi
	done
done
