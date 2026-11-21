#!/bin/bash
export PATH=/root/bin:$PATH
cd /root/ofox-sync
exec ./orangefox_sync.sh --branch 12.1 --path /root/fox_12.1 > /root/fox12_sync.log 2>&1
