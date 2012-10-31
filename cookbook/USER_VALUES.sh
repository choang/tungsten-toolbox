#!/bin/bash
# (C) Copyright 2012 Continuent, Inc - Released under the New BDS License
# Version 1.0.2 - 2012-10-31

NODES=$1
if [ -z "$NODES" ]
then
    echo "We need a NODES file to work with"
    exit 1
fi

SIMPLE_SERVICES=`simple_services --help`
if [ -z "$SIMPLE_SERVICES" ]
then
    echo "simple_services is not installed. "
    echo "While not strictly necessary for the recipes installation, it is needed to run the auxuliary scripts."
    echo "Please get it from http://code.google.com/p/tungsten-toolbox/ and put it in the \$PATH"
    exit 1
fi

if [ ! -f ./cookbook/$NODES ]
then
    echo "./cookbook/$NODES not found"
    exit 1
fi

. ./cookbook/$NODES

if [ -z "${ALL_NODES[0]}" ]
then
    echo "Nodes variables not set"
    echo "Please edit cookbook/COMMON_NODES.sh or cookbook/NODES*.sh"
    echo "Make sure that NODE1, NODE2, etc are filled"
    exit 1
fi

HOSTS_LIST=""
MASTERS_LIST=""
SLAVES_LIST=""

for NODE in ${ALL_NODES[*]}
do
   [ -n "$HOSTS_LIST" ] && HOSTS_LIST="$HOSTS_LIST,"
   HOSTS_LIST="$HOSTS_LIST$NODE"
done

for NODE in ${SLAVES[*]}
do
   [ -n "$SLAVES_LIST" ] && SLAVES_LIST="$SLAVES_LIST,"
   SLAVES_LIST="$SLAVES_LIST$NODE"
done

for NODE in ${MASTERS[*]}
do
   [ -n "$MASTERS_LIST" ] && MASTERS_LIST="$MASTERS_LIST,"
   MASTERS_LIST="$MASTERS_LIST$NODE"
done

export MASTERS_LIST
export SLAVES_LIST
export HOSTS_LIST

export TUNGSTEN_BASE=$HOME/installs/cookbook
export REPLICATOR=$TUNGSTEN_BASE/tungsten/tungsten-replicator/bin/replicator
export TREPCTL=$TUNGSTEN_BASE/tungsten/tungsten-replicator/bin/trepctl
export DATABASE_USER=tungsten
export DATABASE_PASSWORD=secret
export DATABASE_PORT=3306
export TUNGSTEN_SERVICE=cookbook
[ -z "$START_OPTION" ] && export START_OPTION=start
export INSTALL_LOG=./cookbook/current_install.log