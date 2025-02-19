#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

set -e

mkdir -p target
swiftc -O src/main.swift -o target/year-progress

mkdir -p /Applications/yearprogress/bin/
cp ./target/year-progress /Applications/yearprogress/bin/year-progress

LAUNCH_AGENT_PATH="/Library/LaunchAgents/org.boss.yearprogress.plist"

/bin/cp "./launch-data.xml" "$LAUNCH_AGENT_PATH"

chown root:wheel "$LAUNCH_AGENT_PATH"
chmod 644 "$LAUNCH_AGENT_PATH"

/bin/launchctl bootstrap system "$LAUNCH_AGENT_PATH"
