#!/bin/bash
# Start the OrangeFox 14.1 sync with repo on PATH.
export PATH=/root/bin:$PATH
cd /root/ofox-sync
exec ./orangefox_sync.sh --branch 14.1 --path /root/fox_14.1 > /root/fox14_sync.log 2>&1
