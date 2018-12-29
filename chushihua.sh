#!/bin/bash

reset_hostname(){

	ip=`ip a|grep -A 2 eth0|grep 'inet'|awk '{print $2}'|awk '{print $1}'|awk -F "/" '{print $1}'|awk -F "." '{print $4}'`

	iplen=$(echo "$ip"|awk -F "" '{print NF}')

	print $iplen;

	if [ $iplen = 3 ];
		then
			hostnamectl set-hostname alivl0$ip;
	elif [ $iplen = 2];
		then
			hostnamectl set-hostname alivl00$ip;
	elif [ $iplen = 1];
		then
			hostnamectl set-hostname alivl000$ip;
	fi		
}

install_zabbix(){
cat /etc/redhat-release|grep 7
if [ $? -eq 0 ]
then 
	rpm -i https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
	yum -y install zabbix-agent;
fi

cat /etc/redhat-release|grep 6
if [ $? -eq 0 ]
then
	#yum -y remove zabbix-release;
        yum clean all;
        rpm -i https://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm;
        yum list|grep zabbix-agent;
        yum -y install zabbix-agent;
fi

cat /etc/debian_version
if [ $? -eq 0 ]
then
	dpkg -i https://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-2+trusty_all.deb；
        apt-get install zabbix-agent -y
fi
ls /var/log/zabbix;
if [ $? -ne 0 ]
    then 
    mkdir /var/log/zabbix/;
fi
chown zabbix:zabbix -R /var/log/zabbix/
mkdir -p /etc/zabbix/zabbix_agentd.d/
touch /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.d/disk.conf /etc/zabbix/zabbix_agentd.d/tcp.conf  /etc/zabbix/zabbix_agentd.d/disk.sh
cat << EOF > /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=10.100.8.178
ServerActive=10.100.8.178
HostnameItem=system.hostname
HostMetadata=aliyun
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

cat << 'EOF' > /etc/zabbix/zabbix_agentd.d/disk.conf
UserParameter=saic.disk[*],bash /etc/zabbix/zabbix_agentd.d/disk.sh $1 $2
EOF

cat << 'EOF' > /etc/zabbix/zabbix_agentd.d/tcp.conf
UserParameter=tcp[*],/etc/zabbix/zabbix_agentd.d/tcp_status.sh $1
EOF

cat << 'EOF' > /etc/zabbix/zabbix_agentd.d/disk.sh
#!/bin/bash

DEVICE=$1
ACTION=$2

saic_disk_discovery() {
  printf '{\n'
  printf '\t"data":[\n'
  /bin/lsblk | awk '/^[hvs]d[a-z]+/ {printf("\t\t{\"{#DEV_NAME}\":\"%s\"},\n",$1)}' | sed '$s/,$//'
  printf '\t]\n'
  printf '}\n'
}

case ${ACTION} in
  read)
    cat /proc/diskstats | awk '$3=="'${DEVICE}'" {print $6}'
    ;;
  write)
    cat /proc/diskstats | awk '$3=="'${DEVICE}'" {print $10}'
    ;;
  read_iops)
    cat /proc/diskstats | awk '$3=="'${DEVICE}'" {print $4}'
    ;;
  write_iops)
    cat /proc/diskstats | awk '$3=="'${DEVICE}'" {print $8}'
    ;;
  util)
    [ -e /usr/bin/iostat ] && /usr/bin/iostat -xy ${DEVICE} 1 1 | awk '$1=="'${DEVICE}'" {print $NF}' || echo 0
    ;;
  discovery)
    saic_disk_discovery
    ;;
  *)
    echo -1
    ;;
esac  
EOF

cat << 'EOF' > /etc/zabbix/zabbix_agentd.d/tcp_status.sh
#!/bin/bash 
#scripts for tcp status 
function SYNRECV { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'SYN-RECV' | awk '{print $2}'
} 
function ESTAB { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'ESTAB' | awk '{print $2}'
} 
function FINWAIT1 { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'FIN-WAIT-1' | awk '{print $2}'
} 
function FINWAIT2 { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'FIN-WAIT-2' | awk '{print $2}'
} 
function TIMEWAIT { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'TIME-WAIT' | awk '{print $2}'
} 
function LASTACK { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'LAST-ACK' | awk '{print $2}'
} 
function LISTEN { 
/usr/sbin/ss -ant | awk '{++s[$1]} END {for(k in s) print k,s[k]}' | grep 'LISTEN' | awk '{print $2}'
} 
$1
EOF

chmod 777 /etc/zabbix/zabbix_agentd.d/*.sh

service zabbix-agent restart;

chkconfig zabbix-agent on;

service zabbix-agent status || echo "zabbix-agent failed"

}
install_software(){

yum -y install wget telnet net-tools sysstat java

}

add_user(){
cat /etc/passwd|grep ops 
if [ $? -eq 0 ]
    then 
	echo ops:kWmFpTKm1M |/usr/sbin/chpasswd;
else
	useradd ops && echo ops:kWmFpTKm1M |/usr/sbin/chpasswd;
fi

if [ $? -eq 0 ]
    then 
	echo "运维账户添加完成"
else
    	echo "运维账户添加失败"
fi
cat << EOF >> /etc/sudoers

ops ALL=(ALL) NOPASSWD:ALL
EOF

if [ $? -eq 0 ]
    then 
        echo "运维账户权限修改完成"
else
        echo "运维账户权限修改失败"
fi
}

prepare_fs(){
mkfs.xfs /dev/vdb;
mkdir /app && mount /dev/vdb /app;
chown coi:coi /app;
uuid=`blkid |grep vdb|awk '{print $2}'`;
echo "$uuid  /app xfs defaults 1 1" >> /etc/fstab
mount -a ;

}

security(){

sed -i 's/\#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config;
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config;

systemctl restart sshd;
}
#reset_hostname;
install_zabbix;
#install_software;
add_user;
#prepare_fs;
#security
#curl -L https://alibaba.github.io/arthas/install.sh | sh

