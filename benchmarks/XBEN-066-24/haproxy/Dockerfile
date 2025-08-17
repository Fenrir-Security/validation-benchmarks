FROM haproxy:2.8

USER root
RUN apt-get update && apt-get install -y curl && apt-get clean

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg