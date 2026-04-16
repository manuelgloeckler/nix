#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
default_install_script="$script_dir/neovim_install.sh"

version=""
remote_nvim_dir=""
install_method=""
arch_type=""
declare -a passthrough_args=()

while getopts ":v:d:m:a:foh" opt; do
  case "$opt" in
    v)
      version="$OPTARG"
      passthrough_args+=("-v" "$OPTARG")
      ;;
    d)
      remote_nvim_dir="$OPTARG"
      passthrough_args+=("-d" "$OPTARG")
      ;;
    m)
      install_method="$OPTARG"
      ;;
    a)
      arch_type="$OPTARG"
      passthrough_args+=("-a" "$OPTARG")
      ;;
    f)
      passthrough_args+=("-f")
      ;;
    o)
      passthrough_args+=("-o")
      ;;
    h)
      exec bash "$default_install_script" -h
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$version" || -z "$remote_nvim_dir" || -z "$install_method" || -z "$arch_type" ]]; then
  echo "Missing required install options." >&2
  exit 1
fi

run_install() {
  local method="$1"
  shift
  bash "$default_install_script" "$@" -m "$method"
}

ensure_tree_sitter_cli() {
  local remote_bin_dir="$remote_nvim_dir/bin"
  local remote_tree_sitter="$remote_bin_dir/tree-sitter"
  local cargo_home="$remote_nvim_dir/cargo-home"
  local cargo_target_dir="$remote_nvim_dir/cargo-target/tree-sitter-cli"
  local rustup_home="$remote_nvim_dir/rustup-home"
  local tree_sitter_cli_binary_version="0.26.8"
  local tree_sitter_cli_source_version="0.26.1"
  local cargo_bin=""

  install_tree_sitter_release_binary() {
    local os_name="$(uname -s)"
    local asset_os=""
    local asset_arch=""
    local temp_dir=""
    local archive_path=""
    local extracted_bin=""

    case "$os_name" in
      Linux)
        asset_os="linux"
        ;;
      Darwin)
        asset_os="macos"
        ;;
      *)
        return 1
        ;;
    esac

    case "$arch_type" in
      x86_64)
        asset_arch="x64"
        ;;
      arm64|aarch64)
        asset_arch="arm64"
        ;;
      *)
        return 1
        ;;
    esac

    if ! command -v curl >/dev/null 2>&1; then
      return 1
    fi

    temp_dir="$(mktemp -d)"
    archive_path="$temp_dir/tree-sitter-cli.zip"
    extracted_bin="$temp_dir/tree-sitter"

    if ! curl -fsSL -o "$archive_path" "https://github.com/tree-sitter/tree-sitter/releases/download/v${tree_sitter_cli_binary_version}/tree-sitter-cli-${asset_os}-${asset_arch}.zip"; then
      rm -rf "$temp_dir"
      return 1
    fi

    if command -v unzip >/dev/null 2>&1; then
      if ! unzip -q "$archive_path" -d "$temp_dir"; then
        rm -rf "$temp_dir"
        return 1
      fi
    elif command -v python3 >/dev/null 2>&1; then
      if ! python3 -m zipfile -e "$archive_path" "$temp_dir" >/dev/null 2>&1; then
        rm -rf "$temp_dir"
        return 1
      fi
    else
      rm -rf "$temp_dir"
      return 1
    fi

    if [[ ! -f "$extracted_bin" ]]; then
      rm -rf "$temp_dir"
      return 1
    fi

    chmod +x "$extracted_bin"
    if ! "$extracted_bin" --version >/dev/null 2>&1; then
      rm -rf "$temp_dir"
      return 1
    fi

    cp "$extracted_bin" "$remote_tree_sitter"
    chmod +x "$remote_tree_sitter"
    rm -rf "$temp_dir"
    return 0
  }

  mkdir -p "$remote_bin_dir"

  if "$remote_tree_sitter" --version >/dev/null 2>&1; then
    echo "tree-sitter CLI already available at $remote_tree_sitter"
    return 0
  fi

  if command -v tree-sitter >/dev/null 2>&1 && tree-sitter --version >/dev/null 2>&1; then
    ln -sf "$(command -v tree-sitter)" "$remote_tree_sitter"
    echo "Using system tree-sitter from $(command -v tree-sitter)"
    return 0
  fi

  echo "Trying prebuilt tree-sitter CLI release..."
  if install_tree_sitter_release_binary; then
    echo "Installed prebuilt tree-sitter CLI at $remote_tree_sitter"
    return 0
  fi

  if [[ -x "$cargo_home/bin/cargo" ]]; then
    cargo_bin="$cargo_home/bin/cargo"
  elif command -v cargo >/dev/null 2>&1; then
    cargo_bin="$(command -v cargo)"
  else
    if ! command -v curl >/dev/null 2>&1; then
      echo "cargo not found and curl unavailable; skipping tree-sitter CLI install" >&2
      return 0
    fi

    echo "Installing local Rust toolchain under $remote_nvim_dir..."
    mkdir -p "$cargo_home" "$rustup_home"
    if ! CARGO_HOME="$cargo_home" RUSTUP_HOME="$rustup_home" curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable --no-modify-path; then
      echo "Failed to install local Rust toolchain; skipping tree-sitter CLI install" >&2
      return 0
    fi
    cargo_bin="$cargo_home/bin/cargo"
  fi

  mkdir -p "$cargo_home" "$cargo_target_dir" "$rustup_home"

  echo "Installing tree-sitter-cli v$tree_sitter_cli_source_version with cargo..."
  if CARGO_HOME="$cargo_home" CARGO_TARGET_DIR="$cargo_target_dir" RUSTUP_HOME="$rustup_home" "$cargo_bin" install --root "$remote_nvim_dir" tree-sitter-cli --version "$tree_sitter_cli_source_version"; then
    if "$remote_tree_sitter" --version >/dev/null 2>&1; then
      echo "Installed tree-sitter CLI at $remote_tree_sitter"
      return 0
    fi
  fi

  echo "Crates.io install failed; retrying from the tree-sitter git tag..."
  if CARGO_HOME="$cargo_home" CARGO_TARGET_DIR="$cargo_target_dir" RUSTUP_HOME="$rustup_home" "$cargo_bin" install --locked --root "$remote_nvim_dir" --git https://github.com/tree-sitter/tree-sitter --tag "v$tree_sitter_cli_source_version" tree-sitter-cli; then
    if "$remote_tree_sitter" --version >/dev/null 2>&1; then
      echo "Installed tree-sitter CLI at $remote_tree_sitter from git"
      return 0
    fi
  fi

  echo "Failed to provision a compatible tree-sitter CLI; parser builds may fail on this host" >&2
  return 0
}

if [[ "$install_method" != "binary" ]]; then
  run_install "$install_method" "${passthrough_args[@]}"
  ensure_tree_sitter_cli
  exit 0
fi

run_install binary "${passthrough_args[@]}"

nvim_binary="$remote_nvim_dir/nvim-downloads/$version/bin/nvim"
if "$nvim_binary" -v >/dev/null 2>&1; then
  ensure_tree_sitter_cli
  exit 0
fi

if printf '%s\0' "${passthrough_args[@]}" | grep -Fzxq -- "-o"; then
  echo "Downloaded Neovim binary is unusable, but offline mode prevents source fallback." >&2
  exit 1
fi

echo "Downloaded Neovim binary is unusable on this host; retrying with source build..." >&2
run_install source "${passthrough_args[@]}" -f
ensure_tree_sitter_cli
