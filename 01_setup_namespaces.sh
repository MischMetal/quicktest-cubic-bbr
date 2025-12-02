#!/bin/bash
set -e

#network config
LINK_DELAY=10ms
BW=10mbit
BUFF=10

# Clean up old namespaces
for ns in sender router receiver; do
    sudo ip netns del $ns 2>/dev/null || true
done

echo "[*] Creating namespaces..."
sudo ip netns add sender
sudo ip netns add router
sudo ip netns add receiver

echo "[*] Creating veth pairs..."
sudo ip link add veth-s type veth peer name veth-r1
sudo ip link add veth-r2 type veth peer name veth-recv

echo "[*] Moving interfaces into namespaces..."
sudo ip link set veth-s netns sender
sudo ip link set veth-r1 netns router
sudo ip link set veth-r2 netns router
sudo ip link set veth-recv netns receiver

echo "[*] Configuring IP addresses..."
sudo ip netns exec sender   ip addr add 10.0.1.1/24 dev veth-s
sudo ip netns exec router   ip addr add 10.0.1.254/24 dev veth-r1
sudo ip netns exec router   ip addr add 10.0.2.254/24 dev veth-r2
sudo ip netns exec receiver ip addr add 10.0.2.1/24 dev veth-recv

echo "[*] Bringing up interfaces..."
sudo ip netns exec sender   ip link set lo up
sudo ip netns exec router   ip link set lo up
sudo ip netns exec receiver ip link set lo up

sudo ip netns exec sender   ip link set veth-s up
sudo ip netns exec router   ip link set veth-r1 up
sudo ip netns exec router   ip link set veth-r2 up
sudo ip netns exec receiver ip link set veth-recv up

echo "[*] Enabling IP forwarding in router..."
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[*] Adding routes..."
sudo ip netns exec sender   ip route add default via 10.0.1.254
sudo ip netns exec receiver ip route add default via 10.0.2.254

# =========================================================
# Configure bottleneck link (veth-r2) with:
#   - HTB rate limit: 10 Mbps
#   - NETEM delay: 25ms in both directions
#   - PFIFO queue: 100 packets
# =========================================================

echo "[*] Clearing existing qdisc on router..."
sudo ip netns exec router tc qdisc del dev veth-r2 root 2>/dev/null || true

echo "[*] Creating unified HTB + NETEM + PFIFO hierarchy..."

# Root: HTB
sudo ip netns exec router tc qdisc add dev veth-r2 root handle 1: htb default 10

# HTB class for bottleneck rate
sudo ip netns exec router tc class add dev veth-r2 parent 1: classid 1:10 htb rate $BW

# NETEM for propagation delay
sudo ip netns exec router tc qdisc add dev veth-r2 parent 1:10 handle 10: netem delay $LINK_DELAY

# PFIFO as bottleneck buffer
sudo ip netns exec router tc qdisc add dev veth-r2 parent 10: handle 20: pfifo limit $BUFF

echo "[✓] Namespaces + bottleneck configured."
echo ""
echo "Topology:"
echo "  sender ---- router ---- receiver"
echo ""
echo "Bottleneck:"
echo "  Rate limit: ${BW}"
echo "  Delay:      ${LINK_DELAY} each direction"
echo "  Buffer:     ${BUFF} packets (pfifo)"
echo "  RTT ≈ $(( 4 * ${LINK_DELAY%ms} )) ms end-to-end"
