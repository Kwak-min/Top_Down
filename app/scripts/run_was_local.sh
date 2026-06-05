#!/usr/bin/env bash
set -e
cd backend && gunicorn app.main:app -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 --workers 2
