
FROM ruby:2.5.0-alpine

RUN apk add --update postgresql-dev alpine-sdk nodejs tzdata

COPY Gemfile* /opt/bundle/
WORKDIR /opt/bundle

RUN bundle update && bundle install

COPY . /opt/app

WORKDIR /opt/app
ENTRYPOINT ["/bin/ash", "-c"]

