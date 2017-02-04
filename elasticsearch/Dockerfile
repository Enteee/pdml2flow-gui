FROM elasticsearch:5

ENV ES_JAVA_OPTS="-Des.path.conf=/etc/elasticsearch"

# environment
RUN set -ex \
  && ( \
    cd /usr/share/elasticsearch ;\
    bin/elasticsearch-plugin install x-pack \
  )

CMD [ \
  "-E", "xpack.security.enabled=false",  \
  "-E", "network.host=0.0.0.0",  \
  "-E", "discovery.zen.minimum_master_nodes=1" \
]
