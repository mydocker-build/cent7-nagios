## Modified by Sam KUON - 28/05/17
FROM centos:latest
MAINTAINER Sam KUON "sam.kuonssp@gmail.com"

# System timezone
ENV TZ=Asia/Phnom_Penh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install repository, packages and update as needed
RUN yum -y install epel-release && \
    yum clean all
RUN yum -y update && \
    yum -y install gd gd-devel wget httpd php gcc make glibc glibc-common perl tar sendmail supervisor net-snmp openssl-devel xinetd unzip libtool-ltdl file

# Create nagios users and groups
RUN adduser nagios && \
    groupadd nagcmd && \
    usermod -a -G nagcmd nagios && \
    usermod -a -G nagios apache

# Get nagios 4.x and nagios plugin source
COPY ./nagios-4.3.2 /tmp/nagios-4.3.2
COPY ./nagios-plugins-2.2.1 /tmp/nagios-plugins-2.2.1
RUN chmod -R +x /tmp/nagios*

# Install nagios 4.x
RUN cd /tmp/nagios-4.3.2 && ./configure --with-command-group=nagcmd
RUN cd /tmp/nagios-4.3.2 && make all && make install && make install-commandmode && make install-init && make install-config && make install-webconf

# Nagios login user/password: nagiosadmin/nagiosadmin
RUN echo "nagiosadmin:M.t9dyxR3OZ3E" > /usr/local/nagios/etc/htpasswd.users
RUN chown nagios:nagios /usr/local/nagios/etc/htpasswd.users

# Install nagios plugin
RUN cd /tmp/nagios-plugins-2.2.1 && ./configure --with-nagios-user=nagios --with-nagios-group=nagios
RUN cd /tmp/nagios-plugins-2.2.1 && make && make install

# create initial config
RUN /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# some bug fixes
RUN touch /var/www/html/index.html
RUN chown nagios.nagcmd /usr/local/nagios/var/rw
RUN chmod g+rwx /usr/local/nagios/var/rw
RUN chmod g+s /usr/local/nagios/var/rw

# remove gcc
RUN yum -y remove gcc && rm -rf /tmp/nagios*

# port 80
EXPOSE 25 80

# supervisor configuration
ADD supervisord.conf /etc/supervisord.conf

# start up nagios, sendmail, apache
CMD ["/usr/bin/supervisord"]
