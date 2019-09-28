FROM busybox:latest

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh