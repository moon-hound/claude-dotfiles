#!/bin/bash
# ha-ultimate install script
# SOURCE: danbuhler/claude-code-ha (adapted — added Python tools deps, updated paths)
#
# Installs CLI tools and Python dependencies for ha-ultimate.
# Re-run after each Home Assistant OS update (HA OS resets the root filesystem).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ha-ultimate Home Assistant Skill Setup ==="
echo ""

# Detect OS / package manager
if command -v apk &> /dev/null; then
    PKG_MANAGER="apk"
    INSTALL_CMD="apk add --quiet"
elif command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="apt-get install -y"
elif command -v brew &> /dev/null; then
    PKG_MANAGER="brew"
    INSTALL_CMD="brew install"
else
    echo "Warning: Unknown package manager. Please install dependencies manually:"
    echo "  python3, pip, curl, jq"
    PKG_MANAGER="unknown"
fi

# Install system dependencies
if [ "$PKG_MANAGER" != "unknown" ]; then
    echo "Installing system packages..."
    case "$PKG_MANAGER" in
        apk) $INSTALL_CMD python3 py3-pip curl jq ;;
        apt) sudo $INSTALL_CMD python3 python3-pip curl jq ;;
        brew) $INSTALL_CMD python3 curl jq ;;
    esac
fi

# Install Python dependencies
echo "Installing Python packages (websockets, pyyaml)..."
if command -v pip3 &> /dev/null; then
    pip3 install websockets pyyaml --break-system-packages --quiet 2>/dev/null \
        || pip3 install websockets pyyaml --quiet
elif command -v pip &> /dev/null; then
    pip install websockets pyyaml --quiet
else
    echo "Warning: pip not found. Install websockets and pyyaml manually."
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/bin/"*

# Determine HA config directory
if [ -d "/config" ]; then
    HA_CONFIG="/config"
elif [ -d "/homeassistant" ]; then
    HA_CONFIG="/homeassistant"
else
    HA_CONFIG="$HOME"
fi

# Determine bin install location
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

# Create symlinks for CLI tools
echo ""
echo "Creating symlinks in $BIN_DIR..."
for script in ha-api ha-ws lovelace-sync; do
    if [ -f "$SCRIPT_DIR/bin/$script" ]; then
        ln -sf "$SCRIPT_DIR/bin/$script" "$BIN_DIR/$script"
        echo "  [symlink] $script -> $BIN_DIR/$script"
    fi
done

# Copy SKILL.md to HA config as CLAUDE.md (only if not present)
echo ""
echo "Copying SKILL.md to $HA_CONFIG/CLAUDE.md..."
if [ -f "$HA_CONFIG/CLAUDE.md" ]; then
    echo "  [skipped] CLAUDE.md already exists (won't overwrite your customizations)"
    echo "            To refresh: cp $SCRIPT_DIR/SKILL.md $HA_CONFIG/CLAUDE.md"
else
    cp "$SCRIPT_DIR/SKILL.md" "$HA_CONFIG/CLAUDE.md"
    echo "  [copied] SKILL.md -> $HA_CONFIG/CLAUDE.md"
fi

# Create .env file if missing
if [ ! -f "$HA_CONFIG/.env" ]; then
    cat > "$HA_CONFIG/.env" <<EOF
# Home Assistant connection settings
# Get your token: Settings → Profile → Long-Lived Access Tokens
HA_URL=https://homeassistant.local:8123
HA_TOKEN=your_long_lived_access_token_here
EOF
    echo "  [created] $HA_CONFIG/.env — edit it with your token!"
else
    echo "  [skipped] .env already exists"
fi

# Add to PATH (HA OS)
if [ -d "/etc/profile.d" ] && [ -w "/etc/profile.d" ]; then
    PROFILE_FILE="/etc/profile.d/ha-ultimate.sh"
    echo ""
    echo "Adding tools to PATH..."
    cat > "$PROFILE_FILE" <<EOF
# ha-ultimate Home Assistant skill
export PATH="\$PATH:$BIN_DIR:$SCRIPT_DIR/bin"
EOF
    chmod +x "$PROFILE_FILE"
fi

# Disable HA banner (HA OS only)
if [ -f "/etc/profile.d/homeassistant.sh" ]; then
    sed -i 's/^ha banner/# ha banner/' /etc/profile.d/homeassistant.sh 2>/dev/null || true
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Installed:"
echo "  ha-api, ha-ws, lovelace-sync  → $BIN_DIR/"
echo "  SKILL.md                      → $HA_CONFIG/CLAUDE.md"
echo "  .env template                 → $HA_CONFIG/.env"
echo ""
echo "Python tools (run with python3):"
echo "  $SCRIPT_DIR/tools/yaml_validator.py"
echo "  $SCRIPT_DIR/tools/reference_validator.py"
echo "  $SCRIPT_DIR/tools/entity_explorer.py"
echo ""

if grep -q "your_long_lived_access_token_here" "$HA_CONFIG/.env" 2>/dev/null; then
    echo "Next: edit $HA_CONFIG/.env and set HA_URL + HA_TOKEN, then run 'claude'"
else
    echo "Next: run 'claude' to start Claude Code"
fi

echo ""
echo "Run 'source /etc/profile.d/ha-ultimate.sh' or open a new shell to use the tools."
