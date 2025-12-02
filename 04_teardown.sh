#!/bin/bash
set -e

echo "[*] Stopping iperf3 servers..."
sudo pkill -f "iperf3" 2>/dev/null || true

echo "[*] Deleting namespaces..."
for ns in sender router receiver; do
    sudo ip netns del $ns 2>/dev/null || true
done

echo "[*] Cleaning up stray qdiscs on host interfaces..."
for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
    sudo tc qdisc del dev $iface root 2>/dev/null || true
done

echo "[✓] Teardown complete."
