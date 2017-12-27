FROM ruby:2.3.0-alpine

MAINTAINER Erin Swenson-Healey <l@s3r.me>

RUN apk add --update postgresql-dev \
    alpine-sdk \
    sqlite-dev \
    nodejs

COPY Gemfile* /tmp/
WORKDIR /tmp

RUN bundle update && bundle install

COPY . /opt/

WORKDIR /opt/
ENTRYPOINT ["/opt/docker-entrypoint.sh"]
CMD ["server"]
