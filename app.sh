#!/bin/bash

CMD=$1
APP_NAME=`ls /app/src |grep jar`
PROFILE=prd
srcfolder=/app/src
workfodler=`pwd`
JAVAHOME=/app/jdk1.8.0_191/jre/bin/
TIPS="eg: $0 {start|stop|restart|check|publish}"

count=0
pid=0
JVM_OPTS="-server -Xms512m -Xmx1024m"
echo ""

if [ "${CMD}" = "" ];
then
    echo "Param {CMD} not found!"
	echo "${TIPS}"
	echo ""
	exit 1
fi


if [ "${APP_NAME}" = "" ];
then
    echo "Param {APP_NAME} not found!"
	echo "${TIPS}"
	echo ""
    exit 1
else
    if [ ! -e "${srcfolder}/${APP_NAME}" ];then
        echo "File(${APP_NAME}) not found!"
		echo ""
        exit 1
    fi
fi

if [ "${PROFILE}" != "" ];
then
    PROFILE="--spring.profiles.active=${PROFILE}"
fi

function start()
{
    countapp
    if [ ${count} -ne 0 ];
	then
        getpid
        echo "${APP_NAME} is running! Pid=${pid}."
    else
        echo -n "Start ${APP_NAME}..."
        nohup $JAVAHOME/java -jar ${JVM_OPTS} ${APP_NAME} ${PROFILE} > /dev/null 2>&1 &
		
        sleep 50
		
		getpid
		tail -n 30 ./log/aiway*.log
        echo "Success! Pid=${pid}."
    fi
}

function stop()
{
    
	
    countapp
    if [ ${count} -ne 0 ];
	then
	    getpid
		echo -n "Stop ${APP_NAME}, pid=${pid}..."
		
		sleep 3
        
        getpid
        kill ${pid}
		sleep 1
        
        countapp
        if [ ${count} -ne 0 ];
		then
            getpid
            kill -9 ${pid}
			sleep 1
			
			countapp
            if [ ${count} -ne 0 ];
			then
			    echo "Failed!"
            else
                 echo "Success!"
			fi
	    else
		    echo "Success!"
        fi
    else
        echo "${APP_NAME} is not running."
    fi
}

function restart()
{
    stop
    sleep 3
    start
}

function check()
{
    
	countapp
    if [[ ${count} -ne 0 ]];
    then
	    getpid
        echo "${APP_NAME} is running, pid=${pid} ."        
    else
        echo "${APP_NAME} is not running."
    fi
}

function getpid()
{
    pid=`ps -ef |grep java|grep ${APP_NAME}|grep -v grep|awk '{print $2}'`
}

function countapp()
{
    count=`ps -ef |grep java|grep ${APP_NAME}|grep -v grep|wc -l`
}

function backup()
{
	backupfolder=/app/bak
	today=`date +%Y%m%d`
	cp -f ./$APP_NAME $backupfolder
        mv $backupfolder/$APP_NAME $backupfolder/$APP_NAME-$today
	
}

function renew()
{
	backupfolder=/app/backup
	srcfolder=/app/src
	cp -f $srcfolder/$APP_NAME .
	
}
case $1 in
    start)
        start
    	echo ""
    	;;
    stop)
        stop
		echo ""
		;;
    restart)
        restart
		echo ""
		;;
    check)
        check
		echo ""
		;;
    renew)
        renew
		echo ""
		;;
	backup)
        backup
		echo ""
		;;	
    publish)
	backup
	renew
        restart
		echo ""
		;;
	*)
        echo "${TIPS}"
		echo ""
		;;
esac
