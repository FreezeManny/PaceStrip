FROM eclipse-temurin:21-jdk-jammy

# ── System deps ──────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl git unzip xz-utils zip wget libglu1-mesa clang cmake ninja-build \
        pkg-config libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Android SDK ───────────────────────────────────────────────────────────────
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
            -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-tmp \
    && mv /tmp/cmdline-tools-tmp/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-tmp

# Accept all licenses then install exactly what Flutter 3.44.1 needs
RUN yes | sdkmanager --licenses > /dev/null 2>&1 && \
    sdkmanager \
        "platform-tools" \
        "platforms;android-36" \
        "build-tools;36.0.0" \
        "ndk;28.2.13676358" \
        "cmake;3.22.1"

# ── Flutter 3.44.1 ───────────────────────────────────────────────────────────
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin

RUN git clone --depth 1 --branch 3.44.1 \
        https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && flutter config --no-analytics \
    && flutter precache --android \
    && yes | flutter doctor --android-licenses > /dev/null 2>&1 || true

# ── Working dir ───────────────────────────────────────────────────────────────
WORKDIR /app

# Pre-warm Gradle on first build (optional but speeds up first run)
# Mount your project at /app and run: docker compose run --rm build
