#!/bin/bash
set -e

echo "[*] Starting iperf3 receivers in namespace 'receiver'..."

sudo ip netns exec receiver iperf3 -s -p 5001 -D
sudo ip netns exec receiver iperf3 -s -p 5002 -D

echo "[✓] Receivers running:"
echo "    - CUBIC server on port 5001"
echo "    - BBR   server on port 5002"
