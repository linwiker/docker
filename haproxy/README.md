配置文件需要放在host上面，而且要放到挂载的卷的conf文件下面，名称为haproxy.cfg

实例：
   
    # mkdir -p /docker/haproxy
    拷贝haproxy.cfg到上面创建的目录下
    # cp haproxy.cfg /docker/haproxy
    启动docker
    # docker run --name haproxy -d --restart=always --publish 80:80 --publish 443:443 --volume /docker/haproxy:/etc/haproxy  centos7/haproxy
