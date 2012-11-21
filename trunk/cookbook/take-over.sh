#!/bin/bash
# (C) Copyright 2012 Continuent, Inc - Released under the New BSD License
# Version 1.0.3 - 2012-11-19
if [ ! -f ./cookbook/USER_VALUES.sh ]
then
    echo "./cookbook/USER_VALUES.sh not found"
    exit 1
fi
. ./cookbook/USER_VALUES.sh NODES_MASTER_SLAVE.sh

check_current_topology 'standard_mysql_replication'

export MASTER=${MASTERS[0]}

echo "installing MASTER/SLAVE" >$INSTALL_LOG
date >> $INSTALL_LOG
MORE_OPTIONS='-a --auto-enable=false'
MYSQL="mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -P $DATABASE_PORT"

for SLAVE in ${SLAVES[*]} 
do
	SLAVE_STATUS=$($MYSQL -h $SLAVE -e 'show slave status\G' |grep Slave_IO_Running |grep Yes)
    if [ -z "$SLAVE_STATUS" ]
    then
        echo "Server $SLAVE does not seem to be running standard MySQL replication."
        echo "This script has the purpose of taking over from existing replication."
        echo "Use the regular install_master_slave.sh if you don't have replication in place"
        exit 1
    fi
	$MYSQL -h $SLAVE -e 'stop slave'
done



INSTALL_COMMAND="./tools/tungsten-installer \
    --master-slave \
    --master-host=$MASTER \
    --datasource-user=$DATABASE_USER \
    --datasource-password=$DATABASE_PASSWORD \
    --datasource-port=$DATABASE_PORT \
    --service-name=$TUNGSTEN_SERVICE \
    --home-directory=$TUNGSTEN_BASE \
    --cluster-hosts=$HOSTS_LIST \
    --datasource-mysql-conf=$MY_CNF \
    $MORE_OPTIONS --$START_OPTION"     

if [ -n "$VERBOSE" ]
then
    echo $INSTALL_COMMAND | perl -pe 's/--/\n\t--/g'
fi

echo $INSTALL_COMMAND >> $INSTALL_LOG

$INSTALL_COMMAND

if [ "$?" != "0"  ]
then
    exit
fi

MASTER_LOG=$($MYSQL -h${SLAVES[1]} -Be 'show slave status;' | tail -1 | cut -f10)
MASTER_POS=$($MYSQL -h${SLAVES[1]} -Be 'show slave status;' | tail -1 | cut -f22 | cut -d '.' -f2) 
EVENT="$MASTER_LOG:$MASTER_POS"

$TREPCTL -host $MASTER online -from-event $EVENT
echo "$TREPCTL -host $MASTER online -from-event $EVENT"


for SLAVE in ${SLAVES[*]} 
do
	$TREPCTL -host $SLAVE online 
	echo "$TREPCTL -host $SLAVE online"
done

echo "master_slave" > $CURRENT_TOPOLOGY
./cookbook/show_cluster.sh NODES_MASTER_SLAVE.sh