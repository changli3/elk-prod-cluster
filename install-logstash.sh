mkfs -t ext4 /dev/xvdcy
mkdir -p /mnt/elasticsearch
mount /dev/xvdcy /mnt/elasticsearch
echo "/dev/xvdcy       /mnt/elasticsearch   ext4    defaults,nofail        0       2" | tee -a /etc/fstab

cd /tmp
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
printf 'y' | yum install -y epel-release
printf 'y' | yum install -y python-pip

pip install --upgrade pip
pip install awscli

echo "[elasticsearch-6.x]
name=elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" | tee /etc/yum.repos.d/elasticsearch.repo
yum -y install elasticsearch

echo "
elasticsearch soft nofile 65536
elasticsearch hard nofile 65536
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited" | tee -a /etc/security/limits.conf

sed -i 's/path.data:/#path.data:/g' /etc/elasticsearch/elasticsearch.yml
echo "
cluster.name: $1
path.data: /mnt/elasticsearch
network.bind_host: 0.0.0.0
discovery.zen.minimum_master_nodes: 2
discovery.zen.hosts_provider: ec2
discovery.ec2.groups: $2
discovery.ec2.host_type: private_ip
network.publish_host: _eth0:ipv4_
node.master: false
node.data: false
node.ingest: true
" | tee -a /etc/elasticsearch/elasticsearch.yml

chown -R elasticsearch:elasticsearch /mnt/elasticsearch
chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml
printf 'yes' | /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2
systemctl enable elasticsearch.service
sudo service elasticsearch restart

#setup logStash.repo
echo "[logstash-6.x]
name=Elastic repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" | tee /etc/yum.repos.d/logStash.repo

#install logStash
sudo yum install -y logstash
sudo /sbin/chkconfig logstash on

#setup logStash to handle syslog
echo 'input {
  beats {
    port => 5044
    ssl => false
  }
}
' | tee /etc/logstash/conf.d/02-beats-input.conf

echo 'filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
' | tee /etc/logstash/conf.d/10-syslog-filter.conf

echo 'output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
' | tee /etc/logstash/conf.d/30-elasticsearch-output.conf


echo "
logstash soft nofile 65536
logstash hard nofile 65536
logstash soft memlock unlimited
logstash hard memlock unlimited" | tee -a /etc/security/limits.conf

service logstash restart

cd /home/ec2-user
wget https://github.com/prometheus/prometheus/releases/download/v2.0.0/prometheus-2.0.0.linux-amd64.tar.gz
tar -xzf prometheus-2.0.0.linux-amd64.tar.gz
cd prometheus-*
echo "
global:
 scrape_interval: 10s
 evaluation_interval: 10s
scrape_configs:
 - job_name: 'prometheus'
   static_configs:
    - targets:
      - localhost:9090
" > prometheus.yml

echo "@reboot root /home/ec2-user/prometheus-2.0.0.linux-amd64/prometheus
" > /etc/cron.d/prometheus

nohup ./prometheus &
