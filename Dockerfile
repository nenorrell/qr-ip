FROM rust:1-slim

# install system deps for X11 / GL
RUN apt-get update && \
    apt-get install -y \
      libx11-dev \
      libxkbcommon-dev \
      libgl1-mesa-dev \
      libwayland-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# build in release mode
RUN cargo build --release

ENTRYPOINT ["./target/release/qr-ip"]
