mkfs -t ext4 /dev/xvdcy
mkdir /mnt/elasticsearch
mount /dev/xvdcy /mnt/elasticsearch
echo "/dev/xvdcy       /mnt/elasticsearch   ext4    defaults,nofail        0       2" | tee -a /etc/fstab

cd /tmp
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
printf 'y' | yum install -y epel-release
printf 'y' | yum install -y python-pip

pip install --upgrade pip
pip install awscli
pip install –upgrade awscli

echo "[elasticsearch-6.x]
name=elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" | tee /etc/yum.repos.d/elasticsearch.repo
yum -y install elasticsearch
systemctl enable elasticsearch.service

cd /tmp
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.16.0-rc.0/node_exporter-0.16.0-rc.0.linux-amd64.tar.gz
tar xvf node_exporter-0.16.0-rc.0.linux-amd64.tar.gz
cp node_exporter-0.16.0-rc.0.linux-amd64/node_exporter /usr/local/bin
chown -R elasticsearch:elasticsearch /mnt/elasticsearch
chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml
printf 'yes' | /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2
service elasticsearch start
/usr/local/bin/node_exporter &
