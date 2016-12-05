#!/bin/bash
# Script to run the docker container in diffenent ways
# using this as ENTRYPOINT
# Default is to start the server and psql console for tty

# show all PG ENVs
set | grep PG
#set -x

start_postgres() {
	echo "starting postgresql"
	${PG_HOME}/bin/pg_ctl start -w -l ${PG_LOG_FILE} \
	&& echo "postgresql is ready" \
	&& trap "${PG_HOME}/bin/pg_ctl stop" EXIT
}
#if this script stops, that stop also postgresql

ARG1=$1;

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
	&& echo "entering psql mode" \
	&& type ${PG_HOME}/bin/psql \
	&& ${PG_HOME}/bin/psql
	;;
	"bash")
	start_postgres \
	&& echo "entering bash mode" \
	&& /bin/bash
	;;
esac
