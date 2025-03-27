using cloud-init

1 - create an activation key
https://console.redhat.com/insights/connector/activation-keys

activation key: demo
find org id : click on user profile icon, fins org id
org id : 10899047
# https://access.redhat.com/solutions/3341191
subscription-manager register --org=10899047 --activationkey=demo

2 - create VM template with below could-init

# cloud-init


userData: |-
  #cloud-config
  user: cloud-user
  password: ${CLOUD_USER_PASSWORD}
  chpasswd: { expire: False }
  rh_subscription:
    activation-key: demo
    org: 10899047
    auto-attach: true
  runcmd:
    - sudo subscription-manager repos --list-enabled
    - sudo dnf module install -y mariadb/galera
    - |
        cat <<EOF | sudo tee /etc/my.cnf
        #
        # This group is read both both by the client and the server
        # use it for options that affect everything
        #
        [client-server]

        [galera]
        wsrep_on=ON
        wsrep_cluster_name=rws
        binlog_format=ROW
        bind-address=0.0.0.0

        default-storage-engine=InnoDB
        innodb_autoinc_lock_mode=2
        innodb_doublewrite=1
        query_cache_size=0
        wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so

        wsrep_cluster_address=gcomm://

        wsrep_sst_method=rsync
        wsrep_dirty_reads=ON
        wsrep-sync-wait=0

        wsrep_node_address=${NAME}.demo.svc.cluster.local

        #
        # include all files from the config directory
        #
        !includedir /etc/my.cnf.d
        EOF
  final_message: wael-Cloud-init has completed successfully!


3 - check cloud-init logs
tail -n 50 /var/log/cloud-init.log


4 - enable mariadb
sudo systemctl start mariadb
sudo systemctl status mariadb

mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"


mysql -u root -e "create database sampledb;"
mysql -u root -e "create user 'userOSR' identified by 'WmyArnyFmiyKrt7n';"
mysql -u root -e "grant all privileges on sampledb.* to 'userOSR'@'%' identified by 'WmyArnyFmiyKrt7n';"
mysql -u root -e "flush privileges;"


database-password: WmyArnyFmiyKrt7n
database-user: userOSR
database-root-password: kLjfBdiJcocd4f5X



https://www.itzgeek.com/how-tos/linux/centos-how-tos/how-to-install-mysql-8-0-on-rhel-8.html

== install mysql ==
subscription-manager register
subscription-manager repos --list-enabled
dnf install -y @mysql
systemctl start mysqld
systemctl enable mysqld
systemctl status mysqld

== db ==
CREATE USER 'userOSR'@'%' IDENTIFIED BY 'WmyArnyFmiyKrt7n';
-- Grant all privileges on the sampledb database to the user
GRANT ALL PRIVILEGES ON sampledb.* TO 'userOSR'@'%';
-- Apply changes
FLUSH PRIVILEGES;


--- Galira
subscription-manager register
subscription-manager repos --list-enabled
sudo dnf module install mariadb/galera


sudo vi /etc/my.cnf

== First intance 


#
# This group is read both both by the client and the server
# use it for options that affect everything
#
[client-server]

[galera]
wsrep_on=ON
wsrep_cluster_name=rws
binlog_format=ROW
bind-address=0.0.0.0

default-storage-engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_doublewrite=1
query_cache_size=0
wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so

wsrep_cluster_address=gcomm://

wsrep_sst_method=rsync
wsrep_dirty_reads=ON
wsrep-sync-wait=0

wsrep_node_address=galera-01.demo.svc.cluster.local

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d



=== start 
sudo systemctl start mariadb
sudo systemctl status mariadb

mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

== scond instance


[galera]
wsrep_on=ON
wsrep_cluster_name=rws
binlog_format=ROW
bind-address=0.0.0.0

default-storage-engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_doublewrite=1
query_cache_size=0
wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so

wsrep_cluster_address=gcomm://galera-01.demo.svc.cluster.local,galera-02.demo.svc.cluster.local

wsrep_provider_options="ist.recv_bind=10.0.2.2" 


wsrep_sst_method=rsync
wsrep_dirty_reads=ON
wsrep-sync-wait=0

wsrep_node_address=galera-02.demo.svc.cluster.local















== Authorization callback URL ==
https://oauth-openshift.apps.cluster-b6dlv.dynamic.redhatworkshops.io/oauth2callback/github


https://oauth-openshift.apps.cluster-b6dlv.dynamic.redhatworkshops.io/oauth2callback/githubidp

Github oauth token : 8808c88437f4ae24998517644bc3d29e1457d585



# wait until all oauth-openshift pods in openshift-authentication namespace restart 




ab -v 4 -n 1000 -c 50 https://ksvc-php-crud-dev.apps.cluster-ghw99.ghw99.sandbox2941.opentlc.com/ 