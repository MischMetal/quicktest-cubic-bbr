#!/bin/bash
set -e

BUFFERS_CSV="buffers.csv"
BWS_CSV="bandwidths.csv"
DELAYS_CSV="delays.csv"

RESULT_DIR="results"
mkdir -p "$RESULT_DIR"

echo "[*] Experiment automation script starting..."
echo "[*] Using:"
echo "    Buffers:     $BUFFERS_CSV"
echo "    Bandwidths:  $BWS_CSV"
echo "    Delays:      $DELAYS_CSV"
echo ""

# Load CSV values into arrays
mapfile -t BUFFERS < "$BUFFERS_CSV"
mapfile -t BWS < "$BWS_CSV"
mapfile -t DELAYS < "$DELAYS_CSV"

# MAIN 3D PARAMETER SWEEP
for bw in "${BWS[@]}"; do
  for buf in "${BUFFERS[@]}"; do
    for delay in "${DELAYS[@]}"; do

      EXP_NAME="bw_${bw}_buf_${buf}_delay_${delay}"
      EXP_DIR="${RESULT_DIR}/${EXP_NAME}"
      mkdir -p "$EXP_DIR"

      echo "===================================================="
      echo "[*] Starting experiment: BW=$bw  Buffer=$buf  Delay=$delay"
      echo "===================================================="

      # 1. Setup namespaces (bw, delay, buffer)
      .././01_setup_namespaces.sh "$bw" "$delay" "$buf"

      # 2. Start receivers
      .././02_start_receivers.sh > "${EXP_DIR}/receivers.log"
      
      # Allow startup
      sleep 1

      # 3. Run senders
      echo "[*] Running senders..."
      .././03_start_senders.sh > "${EXP_DIR}/senders.log"

      # 4. Save router qdisc state
      echo "[*] Saving qdisc state..."
      sudo ip netns exec router tc qdisc show dev veth-r2 \
        > "${EXP_DIR}/qdisc_state.txt"

      # Save sender output logs if your sender script writes them
      cp /tmp/flow_cubic.txt "${EXP_DIR}/" 2>/dev/null || true
      cp /tmp/flow_bbr.txt   "${EXP_DIR}/" 2>/dev/null || true

      # 5. Teardown
      echo "[*] Cleaning up namespaces..."
      .././04_teardown.sh

      echo "[✓] Finished experiment ${EXP_NAME}"
      echo ""
    done
  done
done

echo "[✓✓✓] All experiments completed!"
