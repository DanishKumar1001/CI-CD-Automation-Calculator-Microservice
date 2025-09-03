#!/usr/bin/env bash
set -euo pipefail

echo "[SMOKE] GET /health"
curl -fsS http://localhost:3000/health | grep -i ok

echo "[SMOKE] GET /add?num1=10&num2=5"
OUT=$(curl -fsS "http://localhost:3000/add?num1=10&num2=5")
echo "$OUT" | grep -E '15|{"result":15}'
echo "[SMOKE] OK"
