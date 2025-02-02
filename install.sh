#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

set -e

cargo build --release

mkdir -p /Applications/yearprogress
cp ./target/release/year-progress /Applications/yearprogress/bin

LAUNCH_AGENT_PATH="/Library/LaunchAgents/org.boss.yearprogress.plist"

/bin/cp "./launch-data.xml" "$LAUNCH_AGENT_PATH"

chown root:wheel "$LAUNCH_AGENT_PATH"
chmod 644 "$LAUNCH_AGENT_PATH"

/bin/launchctl bootstrap system "$LAUNCH_AGENT_PATH"
