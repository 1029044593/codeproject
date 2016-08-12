#!/bin/bash

#server shell>chmod 777 -R /usr/local/tools/zabbix3.tar.gz
#server shell>scp -r -P 52112 /usr/local/tools/zabbix3.tar.gz twodept@10.18.14.3:/usr/local/tools/
#server shell> zabbix_get -s 10.18.11.2 -p 10050 -k system.uptime

#agent root>  mkdir -p /usr/local/tools
#agent root>  chmod 777 -R /usr/local/tools/

gz_file="/usr/local/tools/zabbix3.tar.gz"
tar_path="/usr/local"
ip_file="/usr/local/tools/localip"
ZABBIX_HOME="/usr/local/zabbix"
conf_file="$ZABBIX_HOME/etc/zabbix_agentd.conf"

serverip=10.18.18.2
createlip=`ifconfig -a | grep "inet addr" | awk '{print $2}' | tr -d addr: | grep -v 127.0.0.1>$ip_file`
localip=`awk -F: '{print $1}' $ip_file`
hostname_str=`hostname`


/usr/sbin/groupadd zabbix
/usr/sbin/useradd -g zabbix -m zabbix


if [ -e  $tar_path/zabbix ]
	then
		echo "tar ZABBIX_HOME  is exists"
	else
		tar -xvf $gz_file -C $tar_path/
fi

chmod 777 -R /usr/local/zabbix

ZABBIX_HOME_enviroment=`cat /etc/profile |grep 'ZABBIX_HOME' | wc -l`
if [ $ZABBIX_HOME_enviroment -eq 0  ]
	then
		echo "ZABBIX_HOME_enviroment is not exists"
		echo "export ZABBIX_HOME=/usr/local/zabbix" >> /etc/profile
		echo "export PATH=\$PATH:\$ZABBIX_HOME/bin:\$ZABBIX_HOME/sbin" >> /etc/profile
	else
		echo "ZABBIX_HOME is exsists"
fi


if [ -e $tar_path/zabbix ]
	then		
		chmod 777 -R $tar_path/zabbix
		echo "directory zabbix exists"
	else
		echo "directory zabbix is not exists"
fi	

\cp -rf $tar_path/zabbix/zabbix_agentd  /etc/init.d/zabbix_agentd
chmod 777 /etc/init.d/zabbix_agentd
chkconfig --add zabbix_agentd
chkconfig --level 35 zabbix_agentd on

if [ -e /etc/rc.d/init.d/zabbix_agentd ]
	then		
		echo "/etc/rc.d/init.d/zabbix_agentd exists"
		BASEDIR_cnt=`cat  /etc/rc.d/init.d/zabbix_agentd |grep 'BASEDIR=/usr/local/zabbix' | wc -l`
		if [ $BASEDIR_cnt -eq 0 ]
			then
				sed -i -e 's%BASEDIR=/usr/local%BASEDIR=/usr/local/zabbix%g' /etc/rc.d/init.d/zabbix_agentd
			else
				echo "BASEDIR  set OK!"
		fi		
	else
		echo "/etc/rc.d/init.d/zabbix_agentd is not exists"
fi



zabbix_agent=`cat /etc/services |grep 'zabbix_agent 10050/tcp' | wc -l`
zabbix_trap=`cat /etc/services |grep 'zabbix_trap 10051/tcp' | wc -l`
if [ $zabbix_agent -eq 0 ] && [ $zabbix_trap -eq 0 ]
	then
		echo "zabbix_agent 10050/tcp" >> /etc/services
		echo "zabbix_trap 10051/tcp" >> /etc/services
	else
		echo "/etc/services zabbix_agent and zabbix_trap  is exsists"
fi

source /etc/profile

sed -i -e 's%Server=127.0.0.1%Server='$serverip'%g' $conf_file

Hostname_count=`cat $conf_file |grep 'Hostname='$hostname_str'' | wc -l`
if [ $Hostname_count -eq 0 ]
	then
		sed -i -e 's%Hostname=localhost%Hostname='$hostname_str'%g' $conf_file
	else
		echo "Hostname set OK!"
fi


v_count1=`cat $conf_file |grep 'UnsafeUserParameters=1' | wc -l`
if [ $v_count1 -eq 0  ]
	then		
		echo "UnsafeUserParameters=1" >> $conf_file
		echo "UnsafeUserParameters set OK!"
	else
		echo "UnsafeUserParameters already set OK!"
fi	

ServerActive_count=`cat $conf_file |grep 'ServerActive='$serverip'' | wc -l`
if [ $ServerActive_count -eq 0  ]
	then	
		echo "ServerActive=$serverip" >> $conf_file
		echo "ServerActive set OK!"
	else
		echo "ServerActive already set OK!"
fi	


zabbix_agentd_count=`cat $conf_file |grep 'Include='$ZABBIX_HOME'/etc/zabbix_agentd.conf.d/' | wc -l`
if [ $zabbix_agentd_count -eq 0  ]
	then
		echo "Include=$ZABBIX_HOME/etc/zabbix_agentd.conf.d/" >> $conf_file
	else
		echo "Include zabbix_agentd.conf.d directory set OK!"
fi	

echo "#"`date` >> $conf_file
service zabbix_agentd restart