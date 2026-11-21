#!/bin/bash
# Stop only the TWRP build processes so a patched rebuild can start cleanly.
pkill -9 -f '11-rebuild.sh' 2>/dev/null || true
pkill -9 -f '10-build-14.1.sh' 2>/dev/null || true
pkill -9 -f 'soong_ui' 2>/dev/null || true
pkill -9 -f 'ckati' 2>/dev/null || true
pkill -9 -f 'ninja' 2>/dev/null || true
pkill -9 -f 'repo/main.py' 2>/dev/null || true
sleep 3
ps -eo pid,args | grep -E '11-rebuild|10-build-14.1|soong_ui|ckati|ninja|repo/main' | grep -v grep || echo clean
