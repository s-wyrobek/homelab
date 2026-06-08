#!/bin/bash
# =============================================================================
# Ninkear Workstation Setup Script
# Ubuntu 26.04 LTS — DevOps Environment
# =============================================================================
set -euo pipefail

echo "🚀 Starting Ninkear workstation setup..."

# =============================================================================
# 1. System update
# =============================================================================
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# =============================================================================
# 2. Core DevOps tools
# =============================================================================
echo "🔧 Installing core tools..."
sudo apt install -y \
  git \
  curl \
  wget \
  zsh \
  tmux \
  htop \
  btop \
  bat \
  fd-find \
  ripgrep \
  fzf \
  zoxide \
  tree \
  jq \
  unzip \
  build-essential \
  pciutils \
  lshw \
  openssh-client \
  awscli

# =============================================================================
# 3. Docker
# =============================================================================
echo "🐳 Installing Docker..."
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker "$USER"

# =============================================================================
# 4. Kubernetes tools
# =============================================================================
echo "☸️  Installing kubectl..."
snap list kubectl &>/dev/null || sudo snap install kubectl --classic

# =============================================================================
# 5. Terraform
# =============================================================================
echo "🏗️  Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# =============================================================================
# 6. Ansible
# =============================================================================
echo "📋 Installing Ansible..."
sudo apt install -y ansible

# =============================================================================
# 7. VS Code
# =============================================================================
echo "💻 Installing VS Code..."
snap list code &>/dev/null || sudo snap install code --classic

# =============================================================================
# 8. Oh My Zsh
# =============================================================================
echo "🐚 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended
fi

# =============================================================================
# 9. Starship prompt
# =============================================================================
echo "⭐ Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# =============================================================================
# 10. awscli-local (LocalStack wrapper)
# =============================================================================
echo "☁️  Installing awscli-local..."
pip install awscli-local --break-system-packages

# =============================================================================
# 11. Shell aliases and config
# =============================================================================
echo "⚙️  Configuring shell..."

ZSHRC="$HOME/.zshrc"

# Aliases — idempotent: only append if marker not already present
if ! grep -q '# BEGIN HOMELAB CONFIG' "$ZSHRC"; then
  cat >> "$ZSHRC" << 'EOF'

# BEGIN HOMELAB CONFIG

# ---- DevOps aliases ----
alias bat='batcat'
alias k='sudo kubectl'
alias tf='terraform'
alias dc='docker compose'
alias ll='ls -la'
alias gs='git status'
alias gp='git push'
alias gl='git log --oneline -10'

# ---- PATH ----
export PATH=$PATH:~/.local/bin

# ---- LocalStack endpoint ----
export AWS_ENDPOINT_URL=http://192.168.1.23:4566

# ---- SSH agent ----
if [ -f ~/.ssh/id_ed25519 ]; then
  eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
fi

# ---- Starship prompt ----
eval "$(starship init zsh)"

# ---- Zoxide (smart cd) ----
eval "$(zoxide init zsh)"

# END HOMELAB CONFIG
EOF
fi

# =============================================================================
# 12. DNS config (AdGuard as primary)
# =============================================================================
echo "🔒 Configuring DNS..."
sudo tee /etc/systemd/resolved.conf > /dev/null << 'EOF'
[Resolve]
DNS=192.168.1.110
FallbackDNS=1.1.1.1
DNSStubListener=yes
EOF
sudo systemctl restart systemd-resolved

# =============================================================================
# Done
# =============================================================================
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (Docker group + zsh default shell)"
echo "  2. Copy SSH keys to ~/.ssh/"
echo "  3. Run: ssh-add ~/.ssh/id_ed25519"
echo "  4. Clone homelab repo: git clone git@github.com:s-wyrobek/homelab.git ~/Project/homelab"
echo "  5. Import CA cert to Firefox: ~/homelab-ca/ca.crt"
