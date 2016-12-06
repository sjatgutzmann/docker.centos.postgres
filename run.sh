#!/bin/bash
# Script to run the docker container in diffenent ways
# using this as ENTRYPOINT
# Default is to start the server and psql console for tty

# show all PG ENVs
set | grep PG
#set -x

start_postgres() {
	echo "starting postgresql"
	# start postgres  -w waitung for start with -t 20 seconds, logging start in -l logfile with postgresql options -o -> -i listen on tcp interfaces with -h ip
	${PG_HOME}/bin/pg_ctl start -w -t 20 -l ${PG_LOG_FILE} -o "-i -h 0.0.0.0" \
	&& echo "postgresql is ready" \
	&& trap "${PG_HOME}/bin/pg_ctl stop" EXIT
}

create_docker_db_user() {
	#create a docker database user with password to access from outside this container
	echo "creating db user and database ${PG_CREATE_USER}:${PG_CREATE_PASSWORD} ${PG_CREATE_DB}"
	psql --command "CREATE USER ${PG_CREATE_USER} WITH SUPERUSER PASSWORD '${PG_CREATE_PASSWORD}';" 
    	createdb --encoding=UTF-8 --owner=${PG_CREATE_USER} --template=template0 ${PG_CREATE_DB}
	# allwasy return ok, if user and/or database exists
	return 0
}
#if this script stops, that stop also postgresql

ARG1=$1;

# change to postgres user home path
cd ${PG_USER_HOME}

#change access with http://augeas.net/
# print /files//var/lib/pgsql/9.3/data/pg_hba.conf 
 
echo "change pg_hba.conf"
augtool <<AUG_COMMANDS_EOF
set /files//var/lib/pgsql/9.3/data/pg_hba.conf/4/type host 
set /files//var/lib/pgsql/9.3/data/pg_hba.conf/4/database all
set /files//var/lib/pgsql/9.3/data/pg_hba.conf/4/user all  
set /files//var/lib/pgsql/9.3/data/pg_hba.conf/4/address 0.0.0.0/0
set /files//var/lib/pgsql/9.3/data/pg_hba.conf/4/method md5
save 
AUG_COMMANDS_EOF

# setting default, simulation of CMD ["psql"] in Dockerfile
if [ -z ${ARG1} ]; then
	echo -n "setting default start arg to "
	ARG1="psql"		
	echo $ARG1
fi

echo "starting this container with ${ARG1}"

case "$ARG1" in
 	"psql")
		start_postgres \
		&& create_docker_db_user \
		&& echo "entering psql mode" \
		&& type ${PG_HOME}/bin/psql \
		&& ${PG_HOME}/bin/psql
	;;
	"bash")
		start_postgres \
		&& create_docker_db_user \
		&& echo "entering bash mode" \
		&& /bin/bash
	;;
	"logtail")
                start_postgres \
                && create_docker_db_user \
		&& /bin/bash -c "tail -f ${PG_LOG_FILE}" 
	;;
esac
