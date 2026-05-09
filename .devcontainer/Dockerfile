# Docker image for the infra operations environment.
# Contains Terraform CLI (OpenTofu), 1Password CLI, and jq for infrastructure management.

FROM debian:bookworm-slim

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG TOFU_VERSION=1.10.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    git \
    gnupg \
    jq \
    bash \
    sudo \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

# Terraform CLI (OpenTofu)
RUN curl -fsSL -o /tmp/tofu.zip \
    "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_amd64.zip" \
  && unzip /tmp/tofu.zip -d /usr/local/bin \
  && chmod +x /usr/local/bin/tofu \
  && rm /tmp/tofu.zip

# 1Password CLI
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc \
    | gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg \
  && echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' \
    > /etc/apt/sources.list.d/1password.list \
  && apt-get update \
  && apt-get install -y 1password-cli \
  && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
WORKDIR /workspace/infra
