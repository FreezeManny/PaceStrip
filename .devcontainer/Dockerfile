FROM mcr.microsoft.com/devcontainers/base:bookworm

# Single version knob: the Android SDK/NDK versions are derived from the
# Flutter SDK below. Bump this, rebuild, done.
ARG FLUTTER_VERSION=3.44.1
# https://developer.android.com/studio#command-line-tools-only (any recent build works)
ARG CMDLINE_TOOLS_BUILD=13114758

# ── System deps (Flutter Linux prerequisites; Android-only, no desktop) ──────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl git unzip xz-utils zip wget file libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# ── Temurin JDK 21 (Adoptium apt repo, Debian bookworm) ──────────────────────
RUN wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" \
        > /etc/apt/sources.list.d/adoptium.list \
    && apt-get update && apt-get install -y --no-install-recommends temurin-21-jdk \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/lib/jvm/temurin-21-jdk-* /usr/lib/jvm/default-jdk

ENV JAVA_HOME=/usr/lib/jvm/default-jdk \
    ANDROID_HOME=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$FLUTTER_HOME/bin

# ── Android cmdline-tools ─────────────────────────────────────────────────────
RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_BUILD}_latest.zip \
            -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-tmp \
    && mv /tmp/cmdline-tools-tmp/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-tmp

# ── Flutter ───────────────────────────────────────────────────────────────────
RUN git clone --depth 1 --branch $FLUTTER_VERSION \
        https://github.com/flutter/flutter.git $FLUTTER_HOME

# ── Android SDK, versions derived from the Flutter SDK ───────────────────────
# FlutterExtension.kt is where Flutter pins compileSdk/NDK; build-tools follows
# the platform version by convention (AGP downloads a different one if needed).
# The NDK gets its own layer: it is the largest download and the most likely to
# stall, so a retry reuses the cached layer with everything else.
RUN set -e; \
    EXT=$FLUTTER_HOME/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt; \
    SDK=$(grep -oP 'compileSdkVersion: Int = \K\d+' $EXT); \
    yes | sdkmanager --licenses > /dev/null 2>&1; \
    sdkmanager \
        "platform-tools" \
        "platforms;android-$SDK" \
        "build-tools;$SDK.0.0" \
        "cmake;3.22.1"
RUN set -e; \
    NDK=$(grep -oP 'ndkVersion: String = "\K[^"]+' \
        $FLUTTER_HOME/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt); \
    sdkmanager "ndk;$NDK"

# ── Flutter setup as the devcontainer user ────────────────────────────────────
RUN chown -R vscode:vscode $FLUTTER_HOME $ANDROID_HOME

USER vscode
RUN flutter config --no-analytics \
    && flutter precache --android \
    && yes | flutter doctor --android-licenses > /dev/null 2>&1 || true
USER root

# Login shells (e.g. via the sshd feature) reset PATH in /etc/profile —
# re-export the toolchain there as well
RUN printf '%s\n' \
        'export JAVA_HOME=/usr/lib/jvm/default-jdk' \
        'export ANDROID_HOME=/opt/android-sdk' \
        'export FLUTTER_HOME=/opt/flutter' \
        'export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$FLUTTER_HOME/bin' \
        > /etc/profile.d/90-flutter-android.sh
