FROM alpine:latest

RUN apk update && \
    apk add --no-cache bash \
                       net-tools \
                       bind-tools \
                       python3 \
                       py3-pip

RUN pip install linode-cli

CMD /bin/bash -c "echo 'Linode CLI is ready!'"