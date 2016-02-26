From compile02.idc1.ux:5000/centos7
MAINTAINER wiker.zhou@uitox.com

ENV PIDFile=/var/run/varnish.pid \
    VARNISH_VCL_CONF=/etc/varnish/default.vcl \
    VARNISH_LISTEN_PORT=80 \
    VARNISH_ADMIN_LISTEN_ADDRESS=127.0.0.1 \
    VARNISH_ADMIN_LISTEN_PORT=6082 \
    VARNISH_SECRET_FILE=/etc/varnish/secret \
    VARNISH_STORAGE="file,/mnt/varnish_storage.bin,200G" \
    VARNISH_TTL=120 \
    DAEMON_OPTS="-p thread_pool_min=50 -p thread_pool_max=1000 -p thread_pool_timeout=1200"

ENV VARNISH_BACKEND_PORT=80 \
    VARNISH_BACKEND_IP="img.idc1.ux"

COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum clean all \ 
 && yum update -y \
 && yum install varnish -y \
 && rm -rf /etc/varnish/default.vcl

COPY default.vcl /etc/varnish/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 80/tcp
VOLUME ["/mnt/","/etc/varnish"]
CMD ["/sbin/entrypoint.sh"]
