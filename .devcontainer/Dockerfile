# Docker image for the infra operations environment.
# Contains OpenTofu, 1Password CLI, talosctl, kubectl, helm, talhelper, sops, age, yq, go-task.

FROM debian:bookworm-slim

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG TOFU_VERSION=1.10.0
ARG TALOSCTL_VERSION=1.9.1
ARG KUBECTL_VERSION=1.32.1
ARG HELM_VERSION=3.17.0
ARG TALHELPER_VERSION=3.1.9
ARG SOPS_VERSION=3.10.2

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

# talosctl
RUN curl -fsSL -o /usr/local/bin/talosctl \
    "https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}/talosctl-linux-amd64" \
  && chmod +x /usr/local/bin/talosctl

# kubectl
RUN curl -fsSL -o /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
  && chmod +x /usr/local/bin/kubectl

# helm
RUN curl -fsSL -o /tmp/helm.tar.gz \
    "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
  && tar -zxvf /tmp/helm.tar.gz -C /tmp \
  && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm \
  && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# go-task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# sops
RUN curl -fsSL -o /usr/local/bin/sops \
    "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
  && chmod +x /usr/local/bin/sops

# age
RUN curl -fsSL -o /tmp/age.tar.gz \
    "https://github.com/FiloSottile/age/releases/download/v1.2.1/age-v1.2.1-linux-amd64.tar.gz" \
  && tar -xzf /tmp/age.tar.gz -C /tmp \
  && mv /tmp/age/age /usr/local/bin/age \
  && mv /tmp/age/age-keygen /usr/local/bin/age-keygen \
  && chmod +x /usr/local/bin/age /usr/local/bin/age-keygen \
  && rm -rf /tmp/age.tar.gz /tmp/age

# talhelper
RUN curl -fsSL -o /tmp/talhelper.tar.gz \
    "https://github.com/budimanjojo/talhelper/releases/download/v${TALHELPER_VERSION}/talhelper_linux_amd64.tar.gz" \
  && tar -xzf /tmp/talhelper.tar.gz -C /tmp \
  && mv /tmp/talhelper /usr/local/bin/talhelper \
  && chmod +x /usr/local/bin/talhelper \
  && rm -f /tmp/talhelper.tar.gz

USER ${USERNAME}
WORKDIR /workspace/infra
