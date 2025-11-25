#!/bin/bash
set -x

# Use uv run to execute your script, uv uses the managed .venv environment automatically
uv run src/gshock-server/gshock_server.py
