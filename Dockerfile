#
# Codex Development Environment
#
# This image intentionally uses Ubuntu 24.04 because the official Swift
# Linux toolchain targets Ubuntu 24.04. Newer Ubuntu releases may provide
# incompatible system libraries for Swift binaries.
#
# This Dockerfile builds a multi-language Codex development environment with:
# - Node.js, npm, Yarn
# - Go
# - Java / OpenJDK
# - Python
# - PHP / Composer
# - Swift
# - Rust
# - Ruby
# - OpenAI Codex CLI installed/updated at container startup
#

FROM buildpack-deps:24.04

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV CODEX_CONTAINER=1
ENV CODEX_WORKSPACE=/workspace

WORKDIR /workspace

ENV NPM_CONFIG_PREFIX=/usr/local
ENV PATH=/usr/local/bin:$PATH
ENV CURL_OPTS="--progress-bar --retry 5 --retry-delay 2 --connect-timeout 30"

### SYSTEM DEPS ###

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    mkdir -p /var/lib/apt/lists/partial; \
    chmod 755 /var/lib/apt/lists /var/lib/apt/lists/partial; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      autoconf \
      binutils \
      bison \
      bzip2 \
      dpkg-dev \
      file \
      fontconfig \
      g++ \
      gcc \
      libargon2-dev \
      libbluetooth-dev \
      libbz2-dev \
      libc-dev \
      libc6-dev \
      libcurl4-openssl-dev \
      libedit2 \
      libexpat1-dev \
      libffi-dev \
      libfreetype6 \
      libgdbm-dev \
      libgmp-dev \
      libicu-dev \
      liblzma-dev \
      libncurses-dev \
      libncursesw5-dev \
      libnsl-dev \
      libonig-dev \
      libpython3-dev \
      libreadline-dev \
      libsodium-dev \
      libsqlite3-0 \
      libsqlite3-dev \
      libssl-dev \
      libtk8.6 \
      libuuid1 \
      libxml2-dev \
      libyaml-dev \
      libz3-dev \
      libzip-dev \
      libzstd-dev \
      make \
      p11-kit \
      pkg-config \
      re2c \
      tk-dev \
      tzdata \
      uuid-dev \
      zlib1g-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

### NODE ###

ENV NODE_VERSION=25.9.0
ENV YARN_VERSION=1.22.22

RUN set -eux; \
    ARCH=""; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
      amd64) ARCH="x64" ;; \
      arm64) ARCH="arm64" ;; \
      armhf) ARCH="armv7l" ;; \
      i386) ARCH="x86" ;; \
      *) echo "unsupported architecture: $dpkgArch"; exit 1 ;; \
    esac; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in \
      5BE8A3F6C8A5C01D106C0AD820B1A390B168D356 \
      DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
      CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
      C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
      108F52B48DB57BB0CC439B2997B01419BD92F80A \
      A363A499291CBBC940DD62E41F10027AF002F8B0 \
    ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    done; \
    curl -fLO $CURL_OPTS --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz"; \
    curl -fLO $CURL_OPTS --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"; \
    gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc; \
    grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner; \
    ln -sf /usr/local/bin/node /usr/local/bin/nodejs; \
    rm -rf "$GNUPGHOME" \
      "node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
      SHASUMS256.txt.asc \
      SHASUMS256.txt; \
    node --version; \
    npm --version

RUN set -eux; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in \
      6A010C5166006599AA17F08146C2130DFD2497F5 \
      72ECF46A56B4AD39C907BBB71646B01B86E50310 \
    ; do \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key"; \
    done; \
    curl -fLO $CURL_OPTS --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz"; \
    curl -fLO $CURL_OPTS --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc"; \
    gpg --batch --verify "yarn-v$YARN_VERSION.tar.gz.asc" "yarn-v$YARN_VERSION.tar.gz"; \
    mkdir -p /opt; \
    tar -xzf "yarn-v$YARN_VERSION.tar.gz" -C /opt; \
    ln -sf "/opt/yarn-v$YARN_VERSION/bin/yarn" /usr/local/bin/yarn; \
    ln -sf "/opt/yarn-v$YARN_VERSION/bin/yarnpkg" /usr/local/bin/yarnpkg; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" \
      "yarn-v$YARN_VERSION.tar.gz" \
      "yarn-v$YARN_VERSION.tar.gz.asc"; \
    yarn --version

### GO ###

ENV GOLANG_VERSION=1.26.2
ENV GOTOOLCHAIN=local
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    arch="${arch##*-}"; \
    case "$arch" in \
      amd64) \
        url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz"; \
        sha256="990e6b4bbba816dc3ee129eaeaf4b42f17c2800b88a2166c265ac1a200262282"; \
        ;; \
      arm64) \
        url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-arm64.tar.gz"; \
        sha256="c958a1fe1b361391db163a485e21f5f228142d6f8b584f6bef89b26f66dc5b23"; \
        ;; \
      armhf) \
        url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-armv6l.tar.gz"; \
        sha256="0000e45577827b0a8868588c543cbe4232853def1d3d7a344ad6e60ce2b015c8"; \
        ;; \
      i386) \
        url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-386.tar.gz"; \
        sha256="89835cdc4dfebde7fe28c9c6dc080bb3753f6b0354301966ff9f62d14991bd7d"; \
        ;; \
      *) \
        echo >&2 "unsupported architecture: $arch"; \
        exit 1; \
        ;; \
    esac; \
    curl -fL $CURL_OPTS -o go.tgz "$url"; \
    curl -fL $CURL_OPTS -o go.tgz.asc "$url.asc"; \
    echo "$sha256 *go.tgz" | sha256sum -c -; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "2F528D36D67B69EDF998D85778BD65473CB3BD13"; \
    gpg --batch --verify go.tgz.asc go.tgz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" go.tgz.asc; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    mkdir -p "$GOPATH/src" "$GOPATH/bin"; \
    chmod -R 1777 "$GOPATH"; \
    go version

### JAVA ###

ENV JAVA_HOME=/usr/local/openjdk-27
ENV JAVA_VERSION=27-ea+20
ENV PATH=$JAVA_HOME/bin:$PATH
ENV LANG=C.UTF-8

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) \
        downloadUrl="https://download.java.net/java/early_access/jdk27/20/GPL/openjdk-27-ea+20_linux-x64_bin.tar.gz"; \
        downloadSha256="a7c288898b71578ab424b0234102cb576ac5cf71c31bbdacc5d610a36be3d9cb"; \
        ;; \
      arm64) \
        downloadUrl="https://download.java.net/java/early_access/jdk27/20/GPL/openjdk-27-ea+20_linux-aarch64_bin.tar.gz"; \
        downloadSha256="47a8c6fedd9b292e5b5a5ad9e4cd238eecfc4d1cf098f052d48e7b6f19a0b025"; \
        ;; \
      *) \
        echo >&2 "unsupported architecture: $arch"; \
        exit 1; \
        ;; \
    esac; \
    curl -fL $CURL_OPTS -o openjdk.tgz "$downloadUrl"; \
    echo "$downloadSha256 *openjdk.tgz" | sha256sum --strict --check -; \
    mkdir -p "$JAVA_HOME"; \
    tar --extract \
      --file openjdk.tgz \
      --directory "$JAVA_HOME" \
      --strip-components=1 \
      --no-same-owner; \
    rm openjdk.tgz; \
    { \
      echo '#!/usr/bin/env bash'; \
      echo 'set -Eeuo pipefail'; \
      echo 'trust extract --overwrite --format=java-cacerts --filter=ca-anchors --purpose=server-auth "$JAVA_HOME/lib/security/cacerts"'; \
    } > /etc/ca-certificates/update.d/docker-openjdk; \
    chmod +x /etc/ca-certificates/update.d/docker-openjdk; \
    /etc/ca-certificates/update.d/docker-openjdk; \
    find "$JAVA_HOME/lib" -name "*.so" -exec dirname "{}" ";" | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf; \
    ldconfig; \
    java -Xshare:dump; \
    javac --version; \
    java --version

### PYTHON ###

ENV PYTHON_VERSION=3.14.4
ENV PYTHON_SHA256=d923c51303e38e249136fc1bdf3568d56ecb03214efdef48516176d3d7faaef8

RUN set -eux; \
    curl -fL $CURL_OPTS -o python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
    echo "$PYTHON_SHA256 *python.tar.xz" | sha256sum -c -; \
    mkdir -p /usr/src/python; \
    tar -xJf python.tar.xz -C /usr/src/python --strip-components=1; \
    rm python.tar.xz; \
    cd /usr/src/python; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
      --build="$gnuArch" \
      --enable-loadable-sqlite-extensions \
      --enable-optimizations \
      --enable-option-checking=fatal \
      --enable-shared \
      --with-ensurepip; \
    make -j"$(nproc)"; \
    make install; \
    ldconfig; \
    cd /; \
    rm -rf /usr/src/python; \
    python3 --version; \
    pip3 --version

RUN set -eux; \
    for src in idle3 pip3 pydoc3 python3 python3-config; do \
      dst="$(echo "$src" | tr -d 3)"; \
      [ -s "/usr/local/bin/$src" ]; \
      [ ! -e "/usr/local/bin/$dst" ]; \
      ln -svT "$src" "/usr/local/bin/$dst"; \
    done; \
    python --version; \
    pip --version

### PHP ###

# Prevent Debian/Ubuntu PHP packages from being installed accidentally.
RUN set -eux; \
    { \
      echo 'Package: php*'; \
      echo 'Pin: release *'; \
      echo 'Pin-Priority: -1'; \
    } > /etc/apt/preferences.d/no-debian-php

ENV PHP_INI_DIR=/usr/local/etc/php

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV GPG_KEYS="1198C0117593497A5EC5C199286AF1F9897469DC 49D9AF6BC72A80D6691719C8AA23F5BE9C7097D4 D95C03BC702BE9515344AE3374E44BC9067701A5"

ENV PHP_VERSION=8.5.5
ENV PHP_URL="https://www.php.net/distributions/php-8.5.5.tar.xz"
ENV PHP_ASC_URL="https://www.php.net/distributions/php-8.5.5.tar.xz.asc"
ENV PHP_SHA256="95bec382f4bd00570a8ef52a58ec04d8d9b9a90494781f1c106d1b274a3902f2"

RUN set -eux; \
    mkdir -p "$PHP_INI_DIR/conf.d" /usr/src/php

RUN set -eux; \
    cd /usr/src; \
    curl -fL $CURL_OPTS -o php.tar.xz "$PHP_URL"; \
    echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
    curl -fL $CURL_OPTS -o php.tar.xz.asc "$PHP_ASC_URL"; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in $GPG_KEYS; do \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    done; \
    gpg --batch --verify php.tar.xz.asc php.tar.xz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME"; \
    tar -xJf php.tar.xz -C /usr/src/php --strip-components=1; \
    rm php.tar.xz php.tar.xz.asc

RUN set -eux; \
    cd /usr/src/php; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    export \
      CFLAGS="$PHP_CFLAGS" \
      CPPFLAGS="$PHP_CPPFLAGS" \
      LDFLAGS="$PHP_LDFLAGS" \
      PHP_BUILD_PROVIDER="codex-development-environment" \
      PHP_UNAME="Linux - Docker"; \
    ./configure \
      --build="$gnuArch" \
      --sysconfdir="${PHP_INI_DIR%/php}" \
      --with-config-file-path="$PHP_INI_DIR" \
      --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
      --enable-option-checking=fatal \
      --with-mhash \
      --with-pic \
      --enable-mbstring \
      --enable-mysqlnd \
      --with-mysqli=mysqlnd \
      --with-pdo-mysql=mysqlnd \
      --with-pdo-sqlite=/usr \
      --with-sqlite3=/usr \
      --with-password-argon2 \
      --with-sodium=shared \
      --with-curl \
      --with-iconv \
      --with-openssl \
      --with-readline \
      --with-zlib \
      --with-zip \
      --enable-bcmath \
      --enable-exif \
      --enable-intl \
      --enable-pcntl \
      --enable-phpdbg \
      --enable-phpdbg-readline \
      --with-pear \
      --with-libdir="lib/$debMultiarch" \
      --enable-embed; \
    make -j"$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    cp -v php.ini-development "$PHP_INI_DIR/php.ini"; \
    cp -v php.ini-* "$PHP_INI_DIR/"; \
    make clean; \
    cd /; \
    rm -rf /usr/src/php; \
    pecl update-channels; \
    rm -rf /tmp/pear ~/.pearrc; \
    php --version

RUN set -eux; \
    { \
      echo "opcache.enable=1"; \
      echo "opcache.enable_cli=0"; \
    } > "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini"; \
    echo "extension=sodium" > "$PHP_INI_DIR/conf.d/docker-php-ext-sodium.ini"; \
    php -m; \
    php --ri Zend\ OPcache; \
    php --ri sodium

# Composer for PHP development.
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

### SWIFT ###

ARG SWIFT_SIGNING_KEY=52BB7E3DE28A71BE22EC05FFEF80A866B47A981F
ARG SWIFT_PLATFORM=ubuntu24.04
ARG SWIFT_BRANCH=swift-6.3.1-release
ARG SWIFT_VERSION=swift-6.3.1-RELEASE
ARG SWIFT_WEBROOT=https://download.swift.org

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY
ENV SWIFT_PLATFORM=$SWIFT_PLATFORM
ENV SWIFT_BRANCH=$SWIFT_BRANCH
ENV SWIFT_VERSION=$SWIFT_VERSION
ENV SWIFT_WEBROOT=$SWIFT_WEBROOT

RUN set -eux; \
    ARCH_NAME="$(dpkg --print-architecture)"; \
    case "${ARCH_NAME##*-}" in \
      amd64) OS_ARCH_SUFFIX='' ;; \
      arm64) OS_ARCH_SUFFIX='-aarch64' ;; \
      *) echo >&2 "unsupported architecture: $ARCH_NAME"; exit 1 ;; \
    esac; \
    SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)$OS_ARCH_SUFFIX"; \
    SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz"; \
    SWIFT_SIG_URL="$SWIFT_BIN_URL.sig"; \
    export GNUPGHOME="$(mktemp -d)"; \
    curl -fL $CURL_OPTS "$SWIFT_BIN_URL" -o swift.tar.gz; \
    curl -fL $CURL_OPTS "$SWIFT_SIG_URL" -o swift.tar.gz.sig; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY"; \
    gpg --batch --verify swift.tar.gz.sig swift.tar.gz; \
    tar -xzf swift.tar.gz --directory / --strip-components=1; \
    chmod -R o+r /usr/lib/swift; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" swift.tar.gz swift.tar.gz.sig; \
    swift --version; \
    swift package --version

### RUST ###

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH
ENV RUST_VERSION=1.95.0

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) \
        rustArch="x86_64-unknown-linux-gnu"; \
        rustupSha256="4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10"; \
        ;; \
      arm64) \
        rustArch="aarch64-unknown-linux-gnu"; \
        rustupSha256="9732d6c5e2a098d3521fca8145d826ae0aaa067ef2385ead08e6feac88fa5792"; \
        ;; \
      *) \
        echo >&2 "unsupported architecture: $arch"; \
        exit 1; \
        ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.29.0/${rustArch}/rustup-init"; \
    curl -fL $CURL_OPTS -o rustup-init "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init \
      -y \
      --no-modify-path \
      --profile minimal \
      --default-toolchain "$RUST_VERSION" \
      --default-host "$rustArch"; \
    rm rustup-init; \
    chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME"; \
    rustup --version; \
    cargo --version; \
    rustc --version

### RUBY ###

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ruby; \
    rm -rf /var/lib/apt/lists/*

# Skip installing gem documentation.
RUN set -eux; \
    mkdir -p /usr/local/etc; \
    echo 'gem: --no-document' >> /usr/local/etc/gemrc

ENV LANG=C.UTF-8

ENV RUBY_VERSION=4.0.3
ENV RUBY_DOWNLOAD_URL=https://cache.ruby-lang.org/pub/ruby/4.0/ruby-4.0.3.tar.xz
ENV RUBY_DOWNLOAD_SHA256=22cf6005d25bbe496b5ebe9224d63a1aaabfbfe02591bb5d612517c5a7836f29

RUN set -eux; \
    curl -fL $CURL_OPTS -o ruby.tar.xz "$RUBY_DOWNLOAD_URL"; \
    echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; \
    mkdir -p /usr/src/ruby; \
    tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1; \
    rm ruby.tar.xz; \
    cd /usr/src/ruby; \
    autoconf; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
      --build="$gnuArch" \
      --disable-install-doc \
      --enable-shared \
      --enable-yjit \
      --enable-zjit; \
    make -j"$(nproc)"; \
    make install; \
    cd /; \
    rm -rf /usr/src/ruby; \
    apt-get purge -y --auto-remove ruby || true; \
    command -v ruby; \
    ruby --version; \
    gem --version; \
    bundle --version

ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH="$GEM_HOME/bin:$PATH"

RUN set -eux; \
    mkdir -p "$GEM_HOME"; \
    chmod 1777 "$GEM_HOME"

### SMOKE TEST ###

RUN set -eux; \
    node --version; \
    npm --version; \
    yarn --version; \
    go version; \
    java --version; \
    javac --version; \
    python --version; \
    pip --version; \
    php --version; \
    composer --version; \
    swift --version; \
    swift package --version; \
    rustc --version; \
    cargo --version; \
    ruby --version; \
    gem --version; \
    bundle --version

# Shell helpers
COPY --chmod=0644 scripts/codex-shell.sh /etc/profile.d/codex-shell.sh
RUN printf '%s\n' 'source /etc/profile.d/codex-shell.sh' >> /root/.bashrc

# Entrypoint
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "-l"]
