#!/usr/bin/env zsh

for i in *.flac; do ffmpeg -y -i "$i" -vcodec copy -acodec alac  "alac/${i%.flac}".m4a; done
