FROM python:3

# runtime dependencies
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
RUN (echo wireshark-common wireshark-common/install-setuid boolean true | debconf-set-selections) \
  && apt-get update \
  && apt-get install -y --force-yes --no-install-recommends \
    tshark \
  && rm -rf /var/lib/apt/lists/*

# environment
RUN set -ex \
  && useradd -m -G wireshark -s /bin/bash pdml2flow \
  && pip3 install pdml2flow pdml2flow-elasticsearch

USER pdml2flow
CMD while [ 1 ]; do tshark -i "${SNIFF_IFACE}" -T pdml | pdml2flow -p elasticsearch && break; done
