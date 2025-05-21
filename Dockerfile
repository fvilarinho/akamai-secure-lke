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

ENV USER_ID=akamai-secure-lke
ENV HOME_DIR=/home/${USER_ID}
ENV BIN_DIR=${HOME_DIR}/bin
ENV PATH="/opt/venv/bin:$PATH"

RUN adduser -D ${USER_ID}

USER USER_ID

RUN mkdir -p ${BIN_DIR}

WORKDIR ${HOME_DIR}

CMD [ "linode-cli", "--help" ]