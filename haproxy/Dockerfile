From centos7:7.2.1511

ENV LANG en_US.UTF-8
RUN rm -rf /etc/yum.repos.d/* 
COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum clean all \
 && yum update -y \
 && yum install haproxy -y \
 && rm -rf /etc/haproxy/haproxy.cfg

#COPY entrypoint.sh /sbin/entrypoint.sh
#RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 80
EXPOSE 443

VOLUME ["/docker/haproxy"]
CMD haproxy -f /etc/haproxy/haproxy.cfg
