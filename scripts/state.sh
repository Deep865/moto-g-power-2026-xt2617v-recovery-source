#!/bin/bash
# Single source of truth for the build chain state.
# Prints exactly: OK | RUN | IDLE
if grep -q 'BUILD_OK' /root/build14.log 2>/dev/null; then
  echo OK
  exit 0
fi
if pgrep -f '10-build-14.1.sh' >/dev/null 2>&1; then echo RUN; exit 0; fi
if pgrep -f '11-rebuild.sh'    >/dev/null 2>&1; then echo RUN; exit 0; fi
if pgrep -f 'repo/main.py'     >/dev/null 2>&1; then echo RUN; exit 0; fi
if pgrep -x soong_ui           >/dev/null 2>&1; then echo RUN; exit 0; fi
if pgrep -x ninja              >/dev/null 2>&1; then echo RUN; exit 0; fi
echo IDLE
