#!/bin/bash
# Script to run the docker container in diffenent ways
# using this as ENTRYPOINT
# Default is to start the server and psql console for tty

# show all PG ENVs
set | grep PG
#set -x
is_array() {
    local variable_name=$1
    [[ "$(declare -p $variable_name 2>/dev/null)" =~ "declare -a" ]]
}
start_postgres() {
	echo "starting postgresql"
	# start postgres  -w waitung for start with -t 20 seconds, logging start in -l logfile with postgresql options -o -> -i listen on tcp interfaces with -h ip
	${PG_HOME}/bin/pg_ctl start -w -t 20 -l ${PG_LOG_PATH}/${PG_LOG_FILE} -o "-i -h 0.0.0.0" \
	&& echo "postgresql is ready" \
	&& trap "${PG_HOME}/bin/pg_ctl stop" EXIT
}

create_one_db() {
	local userName=$1
	local userPasswd=$2
	local dbName=$3

	if [ -n "$userName" ] 
	then
		if [ -z $userPasswd ]
		then
			userPasswd=$userName
		fi
		if [ -z $dbName ]
		then
			dbName=$userName
		fi
                echo "creating db user and database ${userName}:${userPasswd} ${dbName}"
                psql --command "CREATE USER ${userName} WITH SUPERUSER PASSWORD '${userPasswd}';"
                createdb --encoding=UTF-8 --owner=${userName} --template=template0 ${dbName}		
	fi
}

#create a docker database user with password to access from outside this container
create_docker_db_user() {
    echo "trying to create db-user and database with: ${PG_CREATE_USER}:${PG_CREATE_PASSWORD} ${PG_CREATE_DB}"

# docker dosn't support arrays https://github.com/docker/docker/issues/20169
# so, use a commy separated String and convert to an array
	declare -a arrayCreateUser=(${PG_CREATE_USER//\,/ })
	declare -a arrayCreatePasswd=(${PG_CREATE_PASSWORD//\,/ })
	declare -a arrayCreateDB=(${PG_CREATE_DB//\,/ })
	
	if is_array arrayCreateUser
	then
		count_db_users=${#arrayCreateUser[@]}
		
		
		for (( i=0; i<count_db_users; i++ ));
		do
			create_one_db ${arrayCreateUser[i]} ${arrayCreatePasswd[i]} ${arrayCreateDB[i]}
		done
	
	else
		create_one_db ${PG_CREATE_USER} ${PG_CREATE_PASSWORD} ${PG_CREATE_DB}
	fi
	# allways return ok, if user and/or database exists
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
set /files/var/lib/pgsql/9.3/data/postgresql.conf/log_directory ${PG_LOG_PATH}
set /files/var/lib/pgsql/9.3/data/postgresql.conf/log_filename ${PG_LOG_FILE}
set /files/var/lib/pgsql/9.3/data/postgresql.conf/log_truncate_on_rotation off
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
		&& /bin/bash -c "tail -f ${PG_LOG_PATH}/${PG_LOG_FILE}" 
	;;
esac
