#!/usr/bin/env bash
set -e
cd backend && pytest -q && cd .. && python tools/offline_runtime_smoke.py
