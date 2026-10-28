FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    coreutils \
    iputils \
    procps \
    util-linux

WORKDIR /workspace
COPY app/ /workspace/app/

RUN chmod +x /workspace/app/app.sh

ENTRYPOINT ["/workspace/app/app.sh"]
CMD ["help"]
