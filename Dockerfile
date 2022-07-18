FROM bullseye-slim

RUN \
  apt-get update && \
  apt-get install -y -q --no-install-recommends wget ca-certificates
RUN \
  wget -P /etc/apt/sources.list.d https://sslmate.com/apt/bullseye/sslmate1.list && \
  wget -P /etc/apt/trusted.gpg.d https://sslmate.com/apt/bullseye/sslmate.gpg
RUN \
  apt-get update && \
  apt-get install -y -q --no-install-recommends sslmate && \
  apt-get clean && \
  rm -r /var/lib/apt/lists/*

COPY sync.sh /sync.sh
CMD bash sync.sh
