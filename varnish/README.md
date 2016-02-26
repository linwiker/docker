簡介：用於cache圖片，使用的是file，放在/mnt下面，使用大小200G，可以自己根據需要進行更改
用法：
  # docker run --name varnish -d --restart=always --publish 80:80 --volume /mnt:/mnt centos7/varnish 
