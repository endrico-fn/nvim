#!/usr/bin/env bash
# Bootstrap development environment for this Neovim configuration (Arch Linux).
# Run this BEFORE launching nvim for the first time on a fresh machine:
#   ~/.config/nvim/bootstrap.sh          # Core tools + Rust + Go
#   ~/.config/nvim/bootstrap.sh --all    # + Optional tools (Zig, Protobuf, SQLite)
#
# Packages match lua/util/sysdeps.lua. This script is idempotent.
set -u

ALL=0
[ "${1:-}" = "--all" ] && ALL=1

PKGS=(base-devel git curl tar unzip wl-clipboard clang tree-sitter-cli fnm pnpm uv ruff mold python ripgrep fd rustup go)
[ "$ALL" = 1 ] && PKGS+=(lazygit github-cli zig protobuf sqlite)

FAILED=0
step() { echo; echo "==> $*"; }

command -v pacman >/dev/null 2>&1 || { echo "pacman not found (non-Arch system?)."; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "sudo not found. Run as root or install sudo."; exit 1; }

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃                                                                  ┃"
echo "┃   NEOVIM SYSTEM DEPENDENCY BOOTSTRAPPER                          ┃"
echo "┃   Target: Arch Linux (pacman) + Toolchains                       ┃"
echo "┃                                                                  ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

step "Installing system packages via pacman: ${PKGS[*]}"
if ! sudo pacman -Syu --needed "${PKGS[@]}"; then
    echo "pacman failed. Check network or lockfile (/var/lib/pacman/db.lck) and retry." >&2
    exit 1
fi

if command -v fnm >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
    step "Setting up Node.js LTS via fnm"
    fnm install --lts && fnm default lts || FAILED=1
fi

if ! rustc --version >/dev/null 2>&1; then
    step "Setting up Rust stable toolchain"
    rustup default stable || FAILED=1
fi

if ! { rust-analyzer --version && test -d "$(rustc --print sysroot)/lib/rustlib/src"; } >/dev/null 2>&1; then
    step "Adding rust-analyzer, rust-src, clippy, rustfmt components"
    rustup component add rust-analyzer rust-src clippy rustfmt || FAILED=1
fi

if command -v nvim >/dev/null 2>&1; then
    step "Synchronizing Neovim plugins (Lazy! sync)"
    nvim --headless "+Lazy! sync" +qa || FAILED=1
fi

echo
if [ "$FAILED" = 0 ]; then
    echo "Bootstrap completed successfully! ✓"
else
    echo "Bootstrap completed with errors (see log above)."
fi
exit "$FAILED"
