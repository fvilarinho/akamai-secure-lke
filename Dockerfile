FROM alpine:latest

RUN apk update && \
    apk add --no-cache bash \
                       net-tools \
                       bind-tools \
                       python3 \
                       py3-pip

RUN pip3 install --upgrade pip

RUN pip3 install linode-cli --upgrade

CMD ["linode-cli", "--help"]