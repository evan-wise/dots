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
# install. ~/.gitconfig-common is mounted read-only too, and the host's git
# identity is passed in as environment variables. Note: a container can read
# the Claude credentials.

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

# Shared git settings from this dots repo (the host's ~/.gitconfig, which holds
# the identity and includes this file, is not mounted; see env_args below).
gitconfig_mounts=()
if [ -f "$HOME/.gitconfig-common" ]; then
    gitconfig_mounts+=(--mount "type=bind,source=$HOME/.gitconfig-common,target=$HOME/.gitconfig-common,readonly")
fi
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

# Pass the host's git identity into the container so commits made there are
# attributed correctly (the host's ~/.gitconfig is not mounted).
env_args=()
if name=$(git config user.name 2>/dev/null) && [ -n "$name" ]; then
    env_args+=(--remote-env "GIT_AUTHOR_NAME=$name" --remote-env "GIT_COMMITTER_NAME=$name")
fi
if email=$(git config user.email 2>/dev/null) && [ -n "$email" ]; then
    env_args+=(--remote-env "GIT_AUTHOR_EMAIL=$email" --remote-env "GIT_COMMITTER_EMAIL=$email")
fi

dc_exec() {
    devcontainer exec --workspace-folder "$workspace" ${config_args[@]+"${config_args[@]}"} "$@"
}

# Project containers may use a different user/home than the host. The mounts
# sit at the host paths, so link them into the container user's home.
dc_exec sh -c '
    for f in .claude .claude.json; do
        if [ ! -e "$HOME/$f" ] && [ "$HOME" != "$1" ]; then
            ln -s "$1/$f" "$HOME/$f" || echo "warning: could not link ~/$f" >&2
        fi
    done
    # Include the shared git config (mounted at the host path) if present.
    if [ -f "$1/.gitconfig-common" ] && [ ! -e "$HOME/.gitconfig" ]; then
        printf "[include]\n\tpath = %s/.gitconfig-common\n" "$1" > "$HOME/.gitconfig"
    fi' sh "$HOME"

# Project dev containers may not ship Claude Code; install the native build.
if ! dc_exec sh -c 'PATH="$HOME/.local/bin:$PATH"; command -v claude' &> /dev/null; then
    echoerr "claude not found in the dev container, installing..."
    dc_exec sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

# Run from the directory we were launched in (mounted at the same path).
exec devcontainer exec --workspace-folder "$workspace" ${config_args[@]+"${config_args[@]}"} \
    ${env_args[@]+"${env_args[@]}"} \
    sh -c 'cd "$1" && shift && PATH="$HOME/.local/bin:$PATH" && exec claude "$@"' sh "$PWD" "$@"
