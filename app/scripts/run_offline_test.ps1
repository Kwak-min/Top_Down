Set-Location backend; pytest -q; if ($?) { Set-Location ..; python tools/offline_runtime_smoke.py }
