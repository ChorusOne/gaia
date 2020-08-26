# Simple usage with a mounted data directory:
# > docker build -t gaia .
# > docker run -it -p 46657:46657 -p 46656:46656 -v ~/.gaiad:/root/.gaiad -v ~/.gaiacli:/root/.gaiacli gaia gaiad init
# > docker run -it -p 46657:46657 -p 46656:46656 -v ~/.gaiad:/root/.gaiad -v ~/.gaiacli:/root/.gaiacli gaia gaiad start
FROM golang:1.14-buster AS build-env

ENV RUST_TOOLCHAIN=nightly-2020-05-31

# Set up dependencies
ENV PACKAGES curl make git libc-dev bash gcc linux-kernel-headers libudev1 python -y

# Set working directory for the build
WORKDIR /go/src/github.com/cosmos/gaia

# Add source files
COPY . .

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
	export PATH="$PATH:$HOME/.cargo/bin" && \
	rustup toolchain install $RUST_TOOLCHAIN && \
	rustup target add wasm32-unknown-unknown --toolchain $RUST_TOOLCHAIN && \
	rustup default stable && \
	rustup default $RUST_TOOLCHAIN

RUN export PATH="$PATH:$HOME/.cargo/bin" && git clone https://github.com/ChorusOne/substrate-light-client.git /wasm/substrate_light_client && \
    cd /wasm/substrate_light_client && \
    make wasm-optimized && \
    cp target/wasm32-unknown-unknown/release/substrate_client.wasm /wasm/substrate_client.wasm

# Install minimum necessary dependencies, build Cosmos SDK, remove packages
RUN apt install $PACKAGES && \
    make tools && \
    make install

# Final image
FROM debian:buster-slim

ARG GROUP_ID
ARG USER_ID

# Install ca-certificates
RUN apt update && apt install ca-certificates -y

RUN groupadd -g ${GROUP_ID} gaia &&\
    useradd -l -u ${USER_ID} -g gaia gaia &&\
    install -d -m 0755 -o gaia -g gaia /home/gaia


WORKDIR /home/gaia

# Copy over binaries from the build-env
COPY --from=build-env /go/bin/gaiad /usr/bin/gaiad
COPY --from=build-env /go/bin/gaiacli /usr/bin/gaiacli
COPY --from=build-env /go/pkg/mod/github.com/!cosm!wasm/go-cosmwasm@v0.8.1/api/libgo_cosmwasm.so /lib/libgo_cosmwasm.so
COPY --from=build-env /wasm/substrate_client.wasm /wasm/substrate_client.wasm

RUN mkdir /home/gaia/.gaiad && chown gaia:gaia /home/gaia -R

USER gaia

# Run gaiad by default, omit entrypoint to ease using container with gaiacli
CMD ["gaiad"]
