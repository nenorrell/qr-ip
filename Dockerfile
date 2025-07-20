FROM rust:1-alpine AS build
RUN apk add --no-cache musl-dev
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

FROM alpine:3.20
WORKDIR /app
COPY --from=build /app/target/release/qr-ip /app/qr-ip
EXPOSE 80
ENTRYPOINT ["/app/qr-ip"]