#Author:PG - Demo/Training/Testing

FROM centos:centos7
MAINTAINER Sven Jörns <sj.at.gutzmann@gmail.com>


ENV PG_VERSION=9.3
ENV PG_VERSION_SMALL=93
ENV PGDATA=/var/lib/pgsql/${PG_VERSION}/data 
ENV PG_HOME=/usr/pgsql-${PG_VERSION}
ENV PG_USER_HOME=/var/lib/pgsql
ENV PG_LOG_PATH=/var/log/postgres
ENV PG_LOG_FILE=postgres.log
ENV LANG en_US.utf8

# as default creating user, password and db with docker. Overwrite this ENV to use these DB in a composed system
ENV PG_CREATE_USER docker
ENV PG_CREATE_PASSWORD docker
ENV PG_CREATE_DB docker

# https://www.liquidweb.com/kb/how-to-install-and-connect-to-postgresql-on-centos-7/


RUN yum -y update; yum clean all \
 && yum -y install sudo epel-release sed net-tools less augeas\
# lanugae support
# reinstall glib to get all lanuages
 && yum -y reinstall glibc-common

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
#--encoding=ENCODING   set default encoding for new databases
#      --locale=LOCALE       set default locale for new databases
#      --lc-collate=, --lc-ctype=, --lc-messages=LOCALE
#      --lc-monetary=, --lc-numeric=, --lc-time=LOCALE
#       set default locale in the respective category for
#       new databases (default taken from environment)
RUN /usr/pgsql-${PG_VERSION}/bin/postgresql${PG_VERSION_SMALL}-setup  initdb

EXPOSE 5432
VOLUME ${PGDATA} ${PG_LOG_PATH}

COPY run.sh /run.sh
RUN chown postgres:postgres /run.sh
USER postgres
#RUN ${PG_HOME}/bin/pg_ctl start -l ${PG_LOG_FILE}
#RUN trap \"${PG_HOME}/bin/pg_ctl stop\" EXIT
# run.sh is used to use this in deffent ways, defaut way is psql
#COPY run.sh ${PG_USER_HOME}/run.sh
#ENTRYPOINT ["/bin/bash", "-c", "${PG_USER_HOME}/run.sh"]
ENTRYPOINT ["/run.sh"]
#psql sql console 

#ENTRYPOINT ${PG_HOME}/bin/pg_ctl start -l ${PG_LOG_FILE} && /bin/bash 
CMD ["logtail"]

