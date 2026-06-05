#!/usr/bin/env bash
set -e
cd infra/aws_cdk && pip install -r requirements.txt && cdk deploy
