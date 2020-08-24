FROM ruby:2.7-alpine

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk add --no-cache \
  git \
  hub \
  bash \
  git-subtree \
  libxml2-dev \
  curl-dev \
  make \
  gcc \
  libc-dev \
  g++ \
  python3-dev \
  imagemagick6-dev \
  mariadb-dev \
  postgresql-dev

RUN apk add yarn && \
  echo $(yarn --version)

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
