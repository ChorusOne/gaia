# Simple usage with a mounted data directory:
# > docker build -t gaia .
# > docker run -it -p 46657:46657 -p 46656:46656 -v ~/.gaiad:/root/.gaiad -v ~/.gaiacli:/root/.gaiacli gaia gaiad init
# > docker run -it -p 46657:46657 -p 46656:46656 -v ~/.gaiad:/root/.gaiad -v ~/.gaiacli:/root/.gaiacli gaia gaiad start
FROM golang:1.14-buster AS build-env

# Set up dependencies
ENV PACKAGES curl make git libc-dev bash gcc linux-kernel-headers libudev1 python -y

# Set working directory for the build
WORKDIR /go/src/github.com/cosmos/gaia

# Add source files
COPY . .

# Install minimum necessary dependencies, build Cosmos SDK, remove packages
RUN apt install $PACKAGES && \
    make tools && \
    make install

# Final image
FROM debian:buster-slim

# Install ca-certificates
RUN apt update && apt install ca-certificates -y
WORKDIR /root

# Copy over binaries from the build-env
COPY --from=build-env /go/bin/gaiad /usr/bin/gaiad
COPY --from=build-env /go/bin/gaiacli /usr/bin/gaiacli
COPY --from=build-env /go/pkg/mod/github.com/!cosm!wasm/go-cosmwasm@v0.8.1/api/libgo_cosmwasm.so /lib/libgo_cosmwasm.so

# Run gaiad by default, omit entrypoint to ease using container with gaiacli
CMD ["gaiad"]
