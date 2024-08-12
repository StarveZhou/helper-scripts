#!/bin/bash

BASE_DIR=`pwd`
MARIADB_DIR="${BASE_DIR}/server"
MARIADB_RUN_DIR="${BASE_DIR}/run"
MARIADB_DATA_DIR="${MARIADB_RUN_DIR}/data"
MARIADB_LOG_DIR="${MARIADB_RUN_DIR}/log"
MY_CNF="$MARIADB_RUN_DIR/my.cnf"

function __init_build_type()
{
  if [ "$1" != "debug" ] && [ "$1" != "release" ]; then
		echo "Invalid build type: $1"
	fi

	BUILD_TYPE="$1"
	MARIADB_BUILD_DIR="$MARIADB_DIR/build_${BUILD_TYPE}"
	MARIADB_INSTALL_DIR="$MARIADB_BUILD_DIR/install"
	MARIADB_BIN_DIR="$MARIADB_INSTALL_DIR/bin"
	mkdir -p ${MARIADB_DATA_DIR}
	mkdir -p ${MARIADB_LOG_DIR}
	echo "Finish init build type"
}

# Always initialize with debug mode, never remove this, otherwise
# __init_db could remove the root directory.
__init_build_type debug

function __do_build()
{
	mkdir -p $MARIADB_BUILD_DIR

	pushd $MARIADB_BUILD_DIR
	cmake ../ -DCMAKE_INSTALL_PREFIX=${MARIADB_INSTALL_DIR} \
	  -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 \
		-DBUILD_TYPE=$BUILD_TYPE
	make -j8
	make install
	popd
}

function __start_db()
{
	${MARIADB_BIN_DIR}/mysqld --defaults-file=${MY_CNF} &
}

function __init_db()
{
	mkdir -p $MARIADB_DATA_DIR
	rm -rf $MARIADB_DATA_DIR/*
  ${MARIADB_BUILD_DIR}/scripts/mariadb-install-db \
	  --user=zhoujy \
		--basedir=${MARIADB_INSTALL_DIR} \
    --defaults-file=${MY_CNF}
}

function __kill_db()
{
  killall mysqld
	killall mariadb
}

function __conn_db()
{
	${MARIADB_BIN_DIR}/mysql --defaults-file=${MY_CNF}
}

function __ps_db()
{
	ps -ef | grep -E "mysqld|mariadb" | grep -v "grep"
}

function mhelper()
{
	command="$1"
	if [ "$command" = "build_type" ]; then
		__init_build_type $2
	elif [ "$command" = "build" ]; then
		__do_build
	elif [ "$command" = "init" ]; then
		__init_db
	elif [ "$command" = "start" ]; then
		__start_db
	elif [ "$command" = "kill" ]; then
	  __kill_db
	elif [ "$command" = "conn" ]; then
		__conn_db
	elif [ "$command" = "ps" ]; then
		__ps_db
	else
		echo "Unsupported comand: $command"
		exit 1
	fi
}
