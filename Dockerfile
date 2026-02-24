FROM zmkfirmware/zmk-build-arm:stable

WORKDIR /workspace

COPY west.yml config/west.yml

RUN west init -l config \
    && west update \
    && west zephyr-export
