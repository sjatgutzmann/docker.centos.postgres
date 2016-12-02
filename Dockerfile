#Author:PG - Demo/Training/Testing

FROM centos:centos7
MAINTAINER Sven Jörns <sj.at.gutzmann@gmail.com>


ENV PG_VERSION=9.3
ENV PG_VERSION_SMALL=93
ENV PGDATA=/var/lib/pgsql/${PG_VERSION}/data 
ENV PG_HOME=/usr/pgsql-${PG_VERSION}
ENV PG_USER_HOME=/var/lib/pgsql
ENV PG_LOG_PATH=/var/log/postgres
ENV PG_LOG_FILE=${PG_LOG_PATH}/postgres.log

# https://www.liquidweb.com/kb/how-to-install-and-connect-to-postgresql-on-centos-7/


RUN yum -y update; yum clean all
RUN yum -y install sudo epel-release sed
# lanugae support
# reinstall glib to get all lanuages
RUN yum -y reinstall glibc-common

#init repo from postgresql.org
RUN rpm -iUvh https://download.postgresql.org/pub/repos/yum/$PG_VERSION/redhat/rhel-7-x86_64/pgdg-centos${PG_VERSION_SMALL}-${PG_VERSION}-3.noarch.rpm
RUN yum -y install postgresql${PG_VERSION_SMALL}-server postgresql${PG_VERSION_SMALL} postgresql${PG_VERSION_SMALL}-contrib \
postgresql${PG_VERSION_SMALL}-plperl postgresql${PG_VERSION_SMALL}-libs
RUN yum clean all
# create custom postgres user config
RUN echo "export PATH=\$PATH:${PG_HOME}/bin" > ${PG_USER_HOME}/.pgsql_profile
RUN chown postgres:postgres ${PG_USER_HOME}/.pgsql_profile
# logging
RUN mkdir ${PG_LOG_PATH}
RUN chown postgres:postgres ${PG_LOG_PATH}

RUN systemctl enable postgresql-${PG_VERSION}
RUN /usr/pgsql-${PG_VERSION}/bin/postgresql${PG_VERSION_SMALL}-setup initdb
#RUN cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak
#RUN sed -i 's/ident/md5' /var/lib/pgsql/data/pg_hba.conf
USER postgres
RUN ${PG_HOME}/bin/pg_ctl start -l ${PG_LOG_FILE}
#psql sql console 
ENTRYPOINT ["/bin/bash"]
EXPOSE 5432
VOLUME ${PGDATA} ${PG_LOG_PATH}
