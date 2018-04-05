yum -y update
yum -y install ntp wget java-1.8.0-openjdk

cd /home/ec2-user

wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
printf 'y' | yum install -y epel-release
printf 'y' | yum install -y python-pip

pip install --upgrade pip
pip install awscli

yum install -y ansible

wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.py
wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.ini
mv -y ec2.ini /etc/ansible/ec2.ini

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
