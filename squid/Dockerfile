From compile02.idc1.ux:5000/centos7
MAINTAINER wiker.zhou@uitox.com

ENV SQUID_VERSION=3.5.14 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=squid

RUN rm -rf /etc/yum.repos.d/* 
COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
COPY squid.repo /etc/yum.repos.d/squid.repo
RUN yum clean all \ 
 && yum update -y \
 && yum install squid -y \
 && rm -rf /etc/squid/squid.conf

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 80/tcp
VOLUME ["${SQUID_CACHE_DIR}"]
ENTRYPOINT ["/sbin/entrypoint.sh"]
