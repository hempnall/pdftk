FROM centos:6
RUN yum -y update && yum -y install libgcj
COPY pdftk-2.02-1.el6.x86_64.rpm /
RUN rpm -i pdftk-2.02-1.el6.x86_64.rpm
COPY main.sh /
RUN mkdir -p /var/pdftk
WORKDIR /var/pdftk 
ENTRYPOINT [ "/main.sh" ]