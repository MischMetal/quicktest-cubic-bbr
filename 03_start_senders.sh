#!/bin/bash
set -e

RECEIVER_IP="10.0.2.1"
DURATION=30

echo "[*] Running CUBIC and BBR flows for $DURATION seconds..."

echo "[*] Starting CUBIC flow..."
sudo ip netns exec sender sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null
sudo ip netns exec sender iperf3 -c $RECEIVER_IP -p 5001 -t $DURATION -C cubic -J > cubic.json &

echo "[*] Starting BBR flow..."
sudo ip netns exec sender sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null
sudo ip netns exec sender iperf3 -c $RECEIVER_IP -p 5002 -t $DURATION -C bbr -J > bbr.json &

wait

# Extract summary throughput (bits per second)
CUBIC_TP=$(jq '.end.sum_received.bits_per_second' cubic.json)
BBR_TP=$(jq '.end.sum_received.bits_per_second' bbr.json)

echo ""
echo "================ Throughput Results ================"
echo "CUBIC throughput: $CUBIC_TP bps"
echo "BBR throughput:   $BBR_TP bps"
echo "===================================================="
echo ""
echo "[✓] Results saved to cubic.json and bbr.json"
