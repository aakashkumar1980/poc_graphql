#!/usr/bin/env bash
# ============================================
# Install all host-level prerequisites
# Ubuntu 22.04 / AWS WorkSpace
# ============================================
# Run once on a fresh machine:
#   chmod +x install-host-prerequisites.sh
#   ./install-host-prerequisites.sh
# ============================================
set -euo pipefail

echo "==========================================="
echo " GraphQL POC — Host Prerequisites Installer"
echo "==========================================="
echo ""

# ─────────────────────────────────────────────
# 1. System update
# ─────────────────────────────────────────────
echo "[1/6] Updating system packages..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release software-properties-common

# ─────────────────────────────────────────────
# 2. Docker & Docker Compose
# ─────────────────────────────────────────────
echo ""
echo "[2/6] Installing Docker..."

if command -v docker &> /dev/null; then
    echo "  Docker already installed: $(docker --version)"
else
    # Add Docker GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Allow current user to run Docker without sudo
    sudo usermod -aG docker "$USER"
    echo "  Docker installed: $(docker --version)"
    echo "  Docker Compose:   $(docker compose version)"
    echo "  NOTE: Log out and back in (or run 'newgrp docker') for group changes to take effect."
fi

# ─────────────────────────────────────────────
# 3. Java 21
# ─────────────────────────────────────────────
echo ""
echo "[3/6] Installing Java 21..."

if java -version 2>&1 | grep -q "21\."; then
    echo "  Java 21 already installed: $(java -version 2>&1 | head -1)"
else
    sudo apt install -y openjdk-21-jdk
    echo "  Java installed: $(java -version 2>&1 | head -1)"
fi

# Set JAVA_HOME if not already set
if ! grep -q "JAVA_HOME" ~/.bashrc 2>/dev/null; then
    echo 'export JAVA_HOME=/usr/lib/jvm/java-1.21.0-openjdk-amd64' >> ~/.bashrc
    echo "  JAVA_HOME added to ~/.bashrc"
fi

# ─────────────────────────────────────────────
# 4. Gradle (wrapper) — just need unzip
# ─────────────────────────────────────────────
echo ""
echo "[4/6] Installing unzip (needed by Gradle wrapper)..."

sudo apt install -y unzip
echo "  unzip installed. Gradle will use the wrapper (gradlew) bundled in the project."

# ─────────────────────────────────────────────
# 5. Rover CLI (Apollo schema tooling)
# ─────────────────────────────────────────────
echo ""
echo "[5/6] Installing Rover CLI..."

if command -v rover &> /dev/null; then
    echo "  Rover already installed: $(rover --version)"
else
    curl -sSL https://rover.apollo.dev/nix/latest | sh

    # Add to PATH if not already there
    if ! grep -q ".rover/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.rover/bin:$PATH"' >> ~/.bashrc
        echo "  Rover PATH added to ~/.bashrc"
    fi

    # Make rover available in the current shell
    export PATH="$HOME/.rover/bin:$PATH"
    echo "  Rover installed: $(rover --version 2>/dev/null || echo 'installed (restart shell to verify)')"
fi

# ─────────────────────────────────────────────
# 6. Git, curl, jq
# ─────────────────────────────────────────────
echo ""
echo "[6/6] Installing utilities (git, curl, jq)..."
sudo apt install -y git curl jq

# ─────────────────────────────────────────────
# Verification
# ─────────────────────────────────────────────
echo ""
echo "==========================================="
echo " Installation Verification"
echo "==========================================="
echo ""
echo -n "  Docker:         "; docker --version 2>/dev/null || echo "NOT FOUND"
echo -n "  Docker Compose: "; docker compose version 2>/dev/null || echo "NOT FOUND"
echo -n "  Java:           "; java -version 2>&1 | head -1
echo -n "  Gradle:         "; echo "Uses wrapper (gradlew) — no system install needed"
echo -n "  Git:            "; git --version
echo -n "  curl:           "; curl --version 2>&1 | head -1
echo -n "  jq:             "; jq --version
echo -n "  Rover:          "; rover --version 2>/dev/null || echo "NOT FOUND (restart shell)"
echo ""
echo "==========================================="
echo " Postman — Install Manually"
echo "==========================================="
echo ""
echo "  Option A:  sudo snap install postman"
echo "  Option B:  Download from https://www.postman.com/downloads/"
echo ""
echo "  (Snap may not be available on all AWS WorkSpaces,"
echo "   so both options are listed.)"
echo ""
echo "==========================================="
echo " All Done!"
echo "==========================================="
echo ""
echo "  Next steps:"
echo "    1. Log out and back in (for Docker group permissions)"
echo "    2. Install Postman (see above)"
echo "    3. Set up Apollo Studio (see INSTALLATION.md Part B)"
echo "    4. cd installation/ && ./scripts/start.sh"
echo ""
