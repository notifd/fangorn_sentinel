#!/bin/bash

set -e

# Set default values
RUNNER_URL="${RUNNER_URL:-https://github.com/notifd}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_WORK_DIRECTORY="${RUNNER_WORK_DIRECTORY:-_work}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,Linux,X64}"

# Check if token is provided
if [ -z "$RUNNER_TOKEN" ]; then
    echo "Error: RUNNER_TOKEN environment variable must be set"
    exit 1
fi

# Configure the runner
./config.sh \
    --url "$RUNNER_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$RUNNER_NAME" \
    --work "$RUNNER_WORK_DIRECTORY" \
    --labels "$RUNNER_LABELS" \
    --unattended \
    --replace

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "$RUNNER_TOKEN"
}

# Trap cleanup on exit
trap cleanup EXIT INT TERM

# Run the runner
./run.sh
