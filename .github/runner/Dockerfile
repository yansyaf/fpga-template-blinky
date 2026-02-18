FROM ubuntu:22.04

ARG RUNNER_VERSION=2.322.0
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    sudo \
    tini \
    locales \
    libicu70 \
    libtinfo5 \
    libtinfo6 \
    libncurses6 \
    libncursesw6 \
    libudev0 \
    libpixman-1-0 \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libjpeg8 \
    libpng16-16 \
    libtcl8.6 \
    libtk8.6 \
    libgomp1 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxft2 \
    libfontconfig1 \
    libfreetype6 \
    libglib2.0-0 \
    libsm6 \
    libstdc++6 \
    libudev1 \
    libudev-dev \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8

RUN useradd -m -d /home/runner runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create fake USB device tree to prevent Vivado license manager crashes
RUN mkdir -p /dev/bus/usb/001 && \
    chmod -R 755 /dev/bus

WORKDIR /home/runner

RUN curl -fsSL -o actions-runner.tar.gz \
      https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    mkdir -p actions-runner && \
    tar xzf actions-runner.tar.gz -C actions-runner && \
        /home/runner/actions-runner/bin/installdependencies.sh && \
    rm actions-runner.tar.gz && \
    chown -R runner:runner /home/runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/runner/actions-runner

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
