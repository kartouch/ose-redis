FROM debian:jessie
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g 64 -r redis && useradd -u 64 -r -g redis redis

RUN apt-get update && apt-get install -y --no-install-recommends \
                ca-certificates \
                curl \
        && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
        && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture).asc" \
        && gpg --verify /usr/local/bin/gosu.asc \
        && rm /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu

ENV REDIS_VERSION 2.8.23
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-2.8.23.tar.gz
ENV REDIS_DOWNLOAD_SHA1 828fc5d4011e6141fabb2ad6ebc193e8f0d08cfa

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN buildDeps='gcc libc6-dev make' \
        && set -x \
        && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* \
        && mkdir -p /usr/src/redis \
        && curl -sSL "$REDIS_DOWNLOAD_URL" -o redis.tar.gz \
        && echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
        && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
        && rm redis.tar.gz \
        && make -C /usr/src/redis \
        && make -C /usr/src/redis install \
        && rm -r /usr/src/redis \
        && apt-get purge -y --auto-remove $buildDeps

RUN mkdir /data && chown redis.0 /data
VOLUME /data
WORKDIR /data
USER 64
EXPOSE 6379
CMD [ "redis-server" ]

