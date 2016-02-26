From compile02.idc1.ux:5000/centos7

ENV LANG en_US.UTF-8
RUN rm -rf /etc/yum.repos.d/* 
COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum clean all \
 && yum update -y \
 && yum install haproxy -y \
 && rm -rf /etc/haproxy/haproxy.cfg

EXPOSE 80
EXPOSE 443

VOLUME ["/docker/haproxy"]
CMD haproxy -f /etc/haproxy/haproxy.cfg
