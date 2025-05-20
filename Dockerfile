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

RUN adduser -D akamai-secure-lke

USER linodeuser

ENV HOME_DIR=/home/akamai-secure-lke
ENV BIN_DIR=${HOME_DIR}/bin
ENV PATH="/opt/venv/bin:$PATH"

RUN mkdir -p ${BIN_DUR}

CMD [ "linode-cli", "--help" ]