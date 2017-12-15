FROM busybox

MAINTAINER Erin Swenson-Healey <l@s3r.me>

ADD index.html /www/index.html
ADD docker-entrypoint.sh /opt/docker-entrypoint.sh

ENTRYPOINT ["/opt/docker-entrypoint.sh"]
CMD []
