# Connect IQ toolchain image for CI: Linux SDK + device files + simulator fonts.
#
# Built and pushed by tools/toolchain/Publish-CiqToolchainImage.ps1 on the maintainer's machine,
# where the device files were downloaded interactively with the SDK Manager (Garmin login with 2FA).
# The image is published as a PRIVATE package on ghcr.io and never contains credentials or keys.
#
# Build context (prepared by the script):
#   ConnectIQ/Devices/  device files of every manifest product
#   ConnectIQ/Fonts/    simulator fonts
#
# The SDK itself is downloaded here from Garmin's public SDK download location (no login needed).
FROM eclipse-temurin:17-jdk-jammy

ARG SDK_VERSION
ARG SDK_FILENAME
ARG SDK_SHA256

LABEL org.opencontainers.image.source="https://github.com/mvaneijken/Garmin-Detailed-Distance-Field" \
      org.opencontainers.image.description="Connect IQ SDK ${SDK_VERSION} toolchain for CI (private)" \
      nl.vaneijken.ciq.sdk-version="${SDK_VERSION}"

# Simulator runtime libraries and Xvfb for headless unit tests.
# NOTE: the exact library set the SDK 9.x Linux simulator needs is not verified yet; adjust after
# the first local test run (see docs/CI-CD.md).
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl unzip xvfb xauth \
      libusb-1.0-0 libwebkit2gtk-4.0-37 libgtk-3-0 libsecret-1-0 libjpeg-turbo8 \
 && rm -rf /var/lib/apt/lists/*

RUN test -n "$SDK_FILENAME" && test -n "$SDK_SHA256" \
 && curl -sSfL -o /tmp/sdk.zip "https://developer.garmin.com/downloads/connect-iq/sdks/${SDK_FILENAME}" \
 && echo "${SDK_SHA256}  /tmp/sdk.zip" | sha256sum --check --strict \
 && mkdir -p /opt/ciq/sdk \
 && unzip -q /tmp/sdk.zip -d /opt/ciq/sdk \
 && rm /tmp/sdk.zip \
 && test -x /opt/ciq/sdk/bin/monkeyc

ENV HOME=/home/ciq
COPY ConnectIQ/ /home/ciq/.Garmin/ConnectIQ/
RUN printf '/opt/ciq/sdk/\n' > /home/ciq/.Garmin/ConnectIQ/current-sdk.cfg \
 && chmod -R a+rwX /home/ciq

ENV PATH="/opt/ciq/sdk/bin:${PATH}"
WORKDIR /work
