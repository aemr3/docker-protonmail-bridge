FROM golang:1.22 AS build

ARG VERSION=3.7.1

WORKDIR /build

RUN apt-get update && \
  apt-get install -y --no-install-recommends git build-essential libsecret-1-dev && \
  git clone https://github.com/ProtonMail/proton-bridge.git && \
  cd proton-bridge && \
  git checkout v$VERSION && \
  sed -i 's/Host = "127.0.0.1"/Host = "0.0.0.0"/' internal/constants/constants.go && \
  make build-nogui

FROM debian:12

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends pass libsecret-1-0 ca-certificates && \
  rm -rf /var/lib/apt/lists/* && \
  addgroup --system --gid 1001 proton && \
  adduser --home /home/proton --system --uid 1001 --gid 1001 proton && \
  chown proton:proton /home/proton

WORKDIR /home/proton

COPY --from=build /build/proton-bridge/bridge /usr/bin/
COPY --from=build /build/proton-bridge/proton-bridge /usr/bin/

EXPOSE 1025 1143

USER proton

ENTRYPOINT ["proton-bridge"]
