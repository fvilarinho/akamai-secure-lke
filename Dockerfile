FROM alpine:latest

RUN apk update && \
    apk add --no-cache bash \
                       net-tools \
                       bind-tools \
                       python3 \
                       py3-pip

RUN python3 -m venv /opt/venv && \
            . /opt/venv/bin/activate && \
            pip3 install --upgrade pip && \
            pip3 install --upgrade linode-cli

ENV PATH="/opt/venv/bin:$PATH"

CMD ["linode-cli", "--help"]