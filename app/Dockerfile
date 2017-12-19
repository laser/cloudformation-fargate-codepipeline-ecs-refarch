FROM python:3.6.3-alpine3.6

MAINTAINER Erin Swenson-Healey <l@s3r.me>

RUN apk add --update postgresql-dev \
    gcc \
    musl-dev

COPY requirements.txt /opt/
RUN pip install -r /opt/requirements.txt

COPY . /opt/

WORKDIR /opt/
ENTRYPOINT ["/opt/docker-entrypoint.sh"]
CMD ["server"]
