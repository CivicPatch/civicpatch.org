#!/bin/bash
# Generate .env file with current user's UID/GID
echo "UID=$(id -u)" > .env
echo "GID=$(id -g)" >> .env
echo "Generated .env with UID=$(id -u) GID=$(id -g)"
