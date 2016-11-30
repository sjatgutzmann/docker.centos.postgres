#Author:PG - Demo/Training/Testing

FROM centos:centos7
MAINTAINER Sven Jörns <sj.at.gutzmann@gmail.com>

RUN yum -y update; yum clean all
RUN yum -y install sudo epel-release sed
RUN yum -y install postgresql-server postgresql postgresql-contrib postgresql-plperl
RUN yum clean all
RUN postgresql-setup initdb
RUN cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak
RUN sed -i 's/ident/md5' /var/lib/pgsql/data/pg_hba.conf

ENTRYPOINT ["/etc/init.d/postgres", "start"]
EXPOSE 5432
