配置文件需要放在host上面，而且要放到挂载的卷的conf文件下面，名称为squid.user.conf
实例：

    # mkdir -p /docker/squid/conf
    拷贝squid.conf到此目录下，并且命名为squid.user.conf
    # cp squid.conf /docker/squid/conf/squid.user.conf
    启动docker
    # docker run --name squid -d --restart=always --publish 80:80 --volume /docker/squid:/var/spool/squid centos7/squid
