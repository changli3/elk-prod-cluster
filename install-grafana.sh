cd /tmp
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
printf 'y' | yum install -y epel-release
printf 'y' | yum install -y python-pip

pip install --upgrade pip
pip install awscli

yum install -y https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.0.4-1.x86_64.rpm

systemctl daemon-reload
systemctl start grafana-server

cd /tmp
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.16.0-rc.0/node_exporter-0.16.0-rc.0.linux-amd64.tar.gz
tar xvf node_exporter-0.16.0-rc.0.linux-amd64.tar.gz
cp -f node_exporter-0.16.0-rc.0.linux-amd64/node_exporter /usr/local/bin

/usr/local/bin/node_exporter &
