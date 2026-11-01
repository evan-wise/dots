FROM ubuntu:24.04

ARG TZ
ARG USERNAME=dev
ARG USER_HOME=/home/dev
ENV TZ="$TZ"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential pkg-config libssl-dev libffi-dev \
    curl ca-certificates git gh openssh-client sudo unzip gnupg2 less procps jq ripgrep nano vim \
    iptables ipset iproute2 dnsutils aggregate \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Non-root user named and homed like the host user, so ~/.claude and
# ~/.claude.json mount at their normal paths. The dev container CLI remaps the
# uid to your host uid.
RUN userdel -r ubuntu 2>/dev/null || true && \
    useradd -m -d "$USER_HOME" -u 1000 -s /bin/bash "$USERNAME"

ENV DEVCONTAINER=true
ENV EDITOR=nano
ENV PATH=${USER_HOME}/.local/share/mise/shims:${USER_HOME}/.cargo/bin:${USER_HOME}/.local/bin:$PATH

USER ${USERNAME}
WORKDIR ${USER_HOME}

# Toolchains: node (current LTS), python + uv via mise; rust via rustup.
RUN curl -fsSL https://mise.run | sh && \
    ~/.local/bin/mise use -g node@lts python@3 uv@latest && \
    ~/.local/bin/mise reshim
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal \
    --default-toolchain stable -c clippy -c rustfmt

# Claude Code, native build.
RUN curl -fsSL https://claude.ai/install.sh | bash

COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "${USERNAME} ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/gloves-firewall && \
    chmod 0440 /etc/sudoers.d/gloves-firewall
USER ${USERNAME}
