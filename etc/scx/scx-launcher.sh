#!/bin/bash
# SCX Launcher for uBlue/Fedora Atomic
# This script handles dynamic kconfig injection for libbpf

SCHEDULER=${SCX_SCHEDULER:-scx_lavd}
KCONFIG_PATH="/usr/lib/modules/$(uname -r)/config"

echo "Starting SCX Scheduler: $SCHEDULER"

if [ -f "$KCONFIG_PATH" ]; then
    echo "Found kernel config at $KCONFIG_PATH. Injecting..."
    # Filter only enabled options (=y) to keep the argument length reasonable
    KCONFIG_CONTENT=$(grep '=y' "$KCONFIG_PATH" | tr '\n' ' ')
    exec /usr/bin/"$SCHEDULER" --kconfig "$KCONFIG_CONTENT" "$@"
else
    echo "Warning: Kernel config not found at $KCONFIG_PATH. Falling back to default search."
    exec /usr/bin/"$SCHEDULER" "$@"
fi
