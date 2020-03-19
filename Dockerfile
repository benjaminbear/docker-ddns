FROM golang:latest as builder

ENV GO111MODULE=on
ENV GOPATH=/root/go
RUN mkdir -p /root/go/src
COPY rest-api /root/go/src/rest-api
RUN cd /root/go/src/rest-api && go mod download && GOOS=linux GOARCH=amd64 go build -o /root/go/bin/rest-api
#&& go test -v

FROM debian:buster-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
	apt-get install -q -y bind9 dnsutils curl && \
	apt-get clean

RUN chmod 770 /var/cache/bind
COPY setup.sh /root/setup.sh
RUN chmod +x /root/setup.sh
COPY named.conf.options /etc/bind/named.conf.options

WORKDIR /root
COPY --from=builder /root/go/bin/rest-api /root/dyndns
COPY rest-api/views /root/views
COPY rest-api/static /root/static

EXPOSE 53 8080
CMD ["sh", "-c", "/root/setup.sh ; service bind9 start ; /root/dyndns"]
