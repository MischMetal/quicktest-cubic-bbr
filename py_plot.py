#!/usr/bin/env python3
import json
import numpy as np
import matplotlib.pyplot as plt

def load_iperf_json(filename):
    """Load iperf3 JSON and extract per-interval bandwidth."""
    with open(filename, 'r') as f:
        data = json.load(f)

    intervals = data['intervals']
    times = []
    rates = []

    t = 0
    for interval in intervals:
        bps = interval['sum']['bits_per_second']
        duration = interval['sum']['seconds']
        times.append(t)
        rates.append(bps)
        t += duration

    summary = data['end']['sum_received']['bits_per_second']
    return np.array(times), np.array(rates), summary

# Load flows
cubic_t, cubic_tp, cubic_summary = load_iperf_json("cubic.json")
bbr_t,   bbr_tp,   bbr_summary   = load_iperf_json("bbr.json")

# --- Plot Throughput vs Time ---
plt.figure(figsize=(10, 4))
plt.plot(cubic_t, cubic_tp / 1e6, label="CUBIC")
plt.plot(bbr_t,   bbr_tp   / 1e6, label="BBR")
plt.xlabel("Time (s)")
plt.ylabel("Throughput (Mbps)")
plt.title("TCP Throughput Over Time")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("throughput_time.png", dpi=150)

# --- Bar Plot of Average Throughput ---
plt.figure(figsize=(6, 4))
plt.bar(["CUBIC", "BBR"], [cubic_summary/1e6, bbr_summary/1e6])
plt.ylabel("Average Throughput (Mbps)")
plt.title("Average TCP Throughput")
plt.tight_layout()
plt.savefig("throughput_avg.png", dpi=150)

print("Plots saved:")
print(" - throughput_time.png")
print(" - throughput_avg.png")
