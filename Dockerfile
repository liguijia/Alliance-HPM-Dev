FROM ubuntu:24.04

ARG TARGETARCH
ARG TARGETARCH_UNAME=${TARGETARCH/amd64/x86_64}
ARG TARGETARCH_UNAME=${TARGETARCH_UNAME/arm64/aarch64}

SHELL ["/bin/bash", "-c"]

# ---- 0) Timezone / locale ----
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

# ---- 0.1) APT robustness ----
RUN printf '%s\n' \
  'Acquire::Retries "5";' \
  'Acquire::http::Timeout "30";' \
  'Acquire::https::Timeout "30";' \
  'Acquire::ForceIPv4 "true";' \
  > /etc/apt/apt.conf.d/99retries

# ---- 1) Base tools & deps ----
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    tzdata \
    vim wget curl aria2 \
    gnupg2 ca-certificates \
    zsh usbutils \
    zip unzip xz-utils \
    openssh-client \
    direnv \
    cmake make ninja-build \
    git sudo \
    pkg-config \
    libc6-dev gcc-14 g++-14 \
    gdb \
    libusb-1.0-0-dev \
    libftdi1-2 \
    libhidapi-hidraw0 \
    libhidapi-libusb0 \
    libmpc3 libmpfr6 libgmp10 \
    libexpat1 zlib1g \
    python3 python3-pip python3-venv \
    python3-yaml python3-jinja2 \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/*

# ---- 2) Make GCC-14 the default ----
RUN dpkg-divert --divert /usr/bin/gcc.distrib --rename /usr/bin/gcc \
 && dpkg-divert --divert /usr/bin/g++.distrib --rename /usr/bin/g++ \
 && dpkg-divert --divert /usr/bin/cc.distrib --rename /usr/bin/cc \
 && dpkg-divert --divert /usr/bin/c++.distrib --rename /usr/bin/c++ \
 && dpkg-divert --divert /usr/bin/${TARGETARCH_UNAME}-linux-gnu-gcc.distrib --rename /usr/bin/${TARGETARCH_UNAME}-linux-gnu-gcc \
 && dpkg-divert --divert /usr/bin/${TARGETARCH_UNAME}-linux-gnu-g++.distrib --rename /usr/bin/${TARGETARCH_UNAME}-linux-gnu-g++ \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 50 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 50 \
 && update-alternatives --install /usr/bin/cc  cc  /usr/bin/gcc 50 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 50 \
 && ln -sf /usr/bin/gcc-14 /usr/bin/${TARGETARCH_UNAME}-linux-gnu-gcc \
 && ln -sf /usr/bin/g++-14 /usr/bin/${TARGETARCH_UNAME}-linux-gnu-g++

# ---- 3) Install latest LLVM tools (clangd/clang-format/clang-tidy) ----
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null \
 && echo "deb https://apt.llvm.org/noble/ llvm-toolchain-noble main" > /etc/apt/sources.list.d/llvm.list \
 && apt-get update \
 && version=$(apt-cache search clangd- | awk '{print $1}' | grep '^clangd-[0-9]\+$' | sort -V | tail -1 | cut -d- -f2) \
 && apt-get install -y --no-install-recommends \
    clangd-$version clang-tidy-$version clang-format-$version \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* \
 && update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-$version 50 \
 && update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-$version 50 \
 && update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-$version 50

# ---- 4) Node.js 24 ----
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/*

# ---- 5) Prebuilt RISC-V GNU Toolchain download ----
ARG RISCV_GNU_TOOLCHAIN_TAG=2026.02.13
ARG RISCV_GNU_TOOLCHAIN_ASSET=riscv32-elf-ubuntu-24.04-gcc.tar.xz
ARG RISCV_GNU_TOOLCHAIN_SHA256=d59bdb85ece0933570cb0885c97f08a8937a83c83ac9d54975d16ccc7af533fa

RUN set -eux; \
    mkdir -p /opt; cd /opt; \
    aria2c -x 16 -s 16 -k 1M \
      "https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/${RISCV_GNU_TOOLCHAIN_TAG}/${RISCV_GNU_TOOLCHAIN_ASSET}" \
      -o "${RISCV_GNU_TOOLCHAIN_ASSET}"; \
    echo "${RISCV_GNU_TOOLCHAIN_SHA256}  ${RISCV_GNU_TOOLCHAIN_ASSET}" | sha256sum -c -; \
    mkdir -p /opt/riscv32-gnu-toolchain-elf-bin; \
    tar -xJf "${RISCV_GNU_TOOLCHAIN_ASSET}" -C /opt/riscv32-gnu-toolchain-elf-bin --strip-components=1; \
    rm -f "${RISCV_GNU_TOOLCHAIN_ASSET}"

ENV GNURISCV_TOOLCHAIN_PATH=/opt/riscv32-gnu-toolchain-elf-bin
ENV PATH="${GNURISCV_TOOLCHAIN_PATH}/bin:${PATH}"
ENV HPM_SDK_BASE=/workspace/hpm_sdk
ENV HPM_OCD_SCRIPTS=/workspace/hpm_sdk/boards/openocd
ENV HPM_OPENOCD_PREFIX=/workspace/tools/openocd-hpm/install

# ---- 5.1) Install HPM OpenOCD via project installer script ----
COPY tools/scripts/install-hpm-openocd.sh /tmp/install-hpm-openocd.sh
RUN chmod +x /tmp/install-hpm-openocd.sh \
 && mkdir -p /workspace/tools \
 && /tmp/install-hpm-openocd.sh \
 && rm -f /tmp/install-hpm-openocd.sh

# ---- 5.2) OpenOCD helper for HPM SDK scripts + upstream scripts ----
RUN cat > /usr/local/bin/openocd-hpm <<'EOF' \
 && chmod +x /usr/local/bin/openocd-hpm
#!/usr/bin/env bash
set -euo pipefail

sdk_base="${HPM_SDK_BASE:-/workspace/hpm_sdk}"
hpm_ocd_scripts="${HPM_OCD_SCRIPTS:-${sdk_base}/boards/openocd}"
hpm_openocd_prefix="${HPM_OPENOCD_PREFIX:-/workspace/tools/openocd-hpm/install}"
hpm_openocd_bin="${hpm_openocd_prefix}/bin/openocd"
upstream_scripts="${hpm_openocd_prefix}/share/openocd/scripts"

if [[ -x "${hpm_openocd_bin}" ]]; then
  exec "${hpm_openocd_bin}" -s "${upstream_scripts}" -s "${hpm_ocd_scripts}" "$@"
fi

exec openocd -s "${upstream_scripts}" -s "${hpm_ocd_scripts}" "$@"
EOF

# ---- 6) User: alliance fixed to 1000:1000 ----
ARG USERNAME=alliance
ARG USER_UID=1000
ARG USER_GID=1000

RUN set -eux; \
    \
    # 0) Make sure /home exists
    mkdir -p "/home/${USERNAME}"; \
    \
    # 1) If UID 1000 is already taken by some other user, move it away
    if getent passwd "${USER_UID}" >/dev/null; then \
      old_user="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
      if [ "${old_user}" != "${USERNAME}" ]; then \
        echo "[fix] uid ${USER_UID} is used by ${old_user}, moving it to 1999"; \
        usermod -u 1999 "${old_user}"; \
      fi; \
    fi; \
    \
    # 2) Ensure group with GID 1000 exists (keep its existing name if any)
    if ! getent group "${USER_GID}" >/dev/null; then \
      groupadd -g "${USER_GID}" "${USERNAME}"; \
    fi; \
    \
    # 3) Ensure a group *named* alliance exists (may NOT be gid 1000; name used by tools/scripts)
    if ! getent group "${USERNAME}" >/dev/null; then \
      groupadd "${USERNAME}"; \
    fi; \
    \
    # 4) Create or fix user alliance: uid=1000, primary gid=1000, also in group "alliance"
    if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
      useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/zsh "${USERNAME}"; \
    else \
      usermod -u "${USER_UID}" -g "${USER_GID}" -s /bin/zsh "${USERNAME}"; \
    fi; \
    usermod -aG "${USERNAME}" "${USERNAME}"; \
    \
    # 5) Fix home ownership using numeric ids (avoid name mismatch)
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"; \
    \
    # 6) sudo no password
    echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# ---- 6.1) Install Oh-My-Zsh for user and set theme: jonathan ----
RUN set -eux; \
    # 1) Install oh-my-zsh for the target user (non-interactive)
    su - "${USERNAME}" -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'; \
    \
    # 2) Set theme
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="jonathan"/' "/home/${USERNAME}/.zshrc"; \
    \
    # 3) Prepare workspace history file + link to ~/.zsh_history (FOR THE USER, not root)
    mkdir -p /workspace/.devcontainer; \
    touch /workspace/.devcontainer/.zsh_history; \
    chown -R "${USER_UID}:${USER_GID}" /workspace/.devcontainer; \
    su - "${USERNAME}" -c 'ln -sfn /workspace/.devcontainer/.zsh_history ~/.zsh_history'; \
    \
    # 4) Append env & direnv hook into user's .zshrc
    { \
      echo ""; \
      echo 'eval "$(direnv hook zsh)"'; \
      echo 'export HPM_SDK_BASE=/workspace/hpm_sdk'; \
      echo 'export GNURISCV_TOOLCHAIN_PATH=/opt/riscv32-gnu-toolchain-elf-bin'; \
      echo 'export PATH="$GNURISCV_TOOLCHAIN_PATH/bin:$PATH"'; \
      echo 'export HISTFILE=/workspace/.devcontainer/.zsh_history'; \
    } >> "/home/${USERNAME}/.zshrc"; \
    \
    # 5) direnv whitelist
    mkdir -p "/home/${USERNAME}/.config/direnv"; \
    printf "[whitelist]\nprefix = [ \"/workspace\" ]\n" > "/home/${USERNAME}/.config/direnv/direnv.toml"; \
    \
    # 6) ownership
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"
    
# ---- 7) Default to alliance (recommended) ----
RUN mkdir -p /workspace && chown -R ${USER_UID}:${USER_GID} /workspace
USER alliance
WORKDIR /workspace
ENV USER=alliance
ENV HOME=/home/alliance

CMD ["/bin/zsh"]
