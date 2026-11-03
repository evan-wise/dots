#!/usr/bin/env bash
# Author: Evan Wise
# Purpose: Run Claude Code inside a dev container ("gloves") with the current
#          directory mounted. Aliased to `claude`. A .devcontainer in the
#          current project (or a parent, up to $HOME) takes priority over the
#          default sandbox in ~/.config/gloves.
#
# Set GLOVES_OFF=1 to run the host's claude binary instead.
# All arguments are passed through to claude, e.g.:
#   claude --permission-mode auto
#
# Your real ~/.claude and ~/.claude.json are bind-mounted into the container at
# the same paths, so the login, settings and plugins are shared with any local
# install. ~/.gitconfig and ~/.gitconfig-common are mounted too (the devcontainer CLI has no read-only mount option).
# Note: a container can read the Claude credentials.
#
# If ~/.config/gloves/token exists (mode 600, not tracked) its contents are
# passed in as GH_TOKEN for the gh CLI and HTTPS git pushes.

set -o errexit
set -o nounset
set -o pipefail

echoerr() {
    echo "$@" 1>&2
}

if [ -n "${GLOVES_OFF:-}" ] || [ -n "${DEVCONTAINER:-}" ]; then
    if ! command -v claude &> /dev/null; then
        echoerr "No local claude installed."
        exit 1
    fi
    exec claude "$@"
fi

for cmd in docker devcontainer; do
    if ! command -v "$cmd" &> /dev/null; then
        echoerr "'$cmd' not found. Install docker and run: npm install -g @devcontainers/cli"
        echoerr "(or set GLOVES_OFF=1 to run claude on the host)"
        exit 1
    fi
done

mkdir -p "$HOME/.claude"
[ -e "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"

# Look for an existing dev container config in this directory or a parent.
dir="$PWD"
project=""
while [ "$dir" != "/" ] && [ "$dir" != "$HOME" ]; do
    if [ -f "$dir/.devcontainer/devcontainer.json" ] || [ -f "$dir/.devcontainer.json" ]; then
        project="$dir"
        break
    fi
    dir=$(dirname "$dir")
done

extra_mounts=()

# Git config (identity plus the shared settings it includes).
gitconfig_mounts=()
for f in .gitconfig .gitconfig-common; do
    if [ -f "$HOME/$f" ]; then
        gitconfig_mounts+=(--mount "type=bind,source=$HOME/$f,target=$HOME/$f")
    fi
done
if [ -n "$project" ]; then
    workspace="$project"
    config_args=()
    echoerr "Using dev container from $project"
else
    workspace="$PWD"
    if top=$(git rev-parse --show-toplevel 2>/dev/null); then
        workspace="$top"
    fi
    config_args=(--config "$HOME/.config/gloves/devcontainer.json")
fi

# For a linked git worktree the shared git dir lives in the main repo, outside
# the workspace; mount it too so git works inside the container.
if common=$(cd "$workspace" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    case "$common" in
        "$workspace"/*) ;;
        *) extra_mounts+=(--mount "type=bind,source=$common,target=$common") ;;
    esac
fi

devcontainer up --workspace-folder "$workspace" ${config_args[@]+"${config_args[@]}"} \
    --mount "type=bind,source=$HOME/.claude,target=$HOME/.claude" \
    --mount "type=bind,source=$HOME/.claude.json,target=$HOME/.claude.json" \
    ${gitconfig_mounts[@]+"${gitconfig_mounts[@]}"} \
    ${extra_mounts[@]+"${extra_mounts[@]}"} > /dev/null

dc_exec() {
    devcontainer exec --workspace-folder "$workspace" ${config_args[@]+"${config_args[@]}"} "$@"
}

# Project containers may use a different user/home than the host. The mounts
# sit at the host paths, so link them into the container user's home.
dc_exec sh -c '
    for f in .claude .claude.json .gitconfig .gitconfig-common; do
        if [ -e "$1/$f" ] && [ ! -e "$HOME/$f" ] && [ "$HOME" != "$1" ]; then
            ln -s "$1/$f" "$HOME/$f" || echo "warning: could not link ~/$f" >&2
        fi
    done' sh "$HOME"

# Project dev containers may not ship Claude Code; install the native build.
if ! dc_exec sh -c 'PATH="$HOME/.local/bin:$PATH"; command -v claude' &> /dev/null; then
    echoerr "claude not found in the dev container, installing..."
    dc_exec sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

# Optional GitHub access: a fine-grained personal access token scoped to the
# repos you want Claude to touch (Contents + Pull requests read/write). It
# powers the gh CLI and HTTPS git pushes; SSH keys are never exposed.
token_file="$HOME/.config/gloves/token"
env_args=()
if [ -s "$token_file" ]; then
    env_args+=(
        --remote-env "GH_TOKEN=$(tr -d '[:space:]' < "$token_file")"
        --remote-env "GIT_CONFIG_COUNT=2"
        --remote-env "GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf"
        --remote-env "GIT_CONFIG_VALUE_0=git@github.com:"
        --remote-env "GIT_CONFIG_KEY_1=credential.https://github.com.helper"
        --remote-env "GIT_CONFIG_VALUE_1=!gh auth git-credential"
    )
fi

# Run from the directory we were launched in (mounted at the same path).
exec devcontainer exec --workspace-folder "$workspace" ${config_args[@]+"${config_args[@]}"} \
    ${env_args[@]+"${env_args[@]}"} \
    sh -c 'cd "$1" && shift && PATH="$HOME/.local/bin:$PATH" && exec claude "$@"' sh "$PWD" "$@"
