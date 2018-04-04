# ELK cluster on CentOS
This is a tutorial on how to deploy an autoscaling ELK cluster on CentOS in AWS using CloudFormation.

![ELK Cluster Architect](https://raw.githubusercontent.com/changli3/elk-prod-cluster/master/elk-stack-architect.JPG "ELK Cluster Architect")

The CloudFormation template and explanation is based on the [NETBEARS](https://netbears.com/blog/elasticsearch-cluster-ubuntu/) company blog. You might want to check the website out for more tutorials like this.

## Prior to deployment notes

This CloudFormation stack assumes that you already have an ElasticSearch cluster deployed in your infrastructure in which Zen discovery via security group is already in place.

If you don't have one already, then all you have to do is deploy it using our previous tutorial -> [Deploy ElasticSearch Cluster on Ubuntu using AWS CloudFormation](https://netbears.com/blog/elasticsearch-cluster-ubuntu/).

Reason for this is that this template uses the security group of the auto-discovery ElasticSearch cluster to create a proxy node (with no-data) that the Kibana service uses in order to limit the load on the actual ElasticSearch cluster.

This method ensures that your Kibana service is able to talk properly with all master and non-master nodes in your ElasticSearch cluster and can hence scale easily if your user adoption for this service is high (aka high traffic).

## Run the CloudFormation template with AWS CLI

```
git clone https://github.com/changli3/elk-prod-cluster.git

aws cloudformation deploy --stack-name elasticsearch-cluster-01 --parameter-overrides Ami=ami-26ebbc5c AsgMaxSize=8 AsgMinSize=2 EmailAlerts=chang.li3@treasury.gov InstanceType=m3.medium KeyName=TreaEBSLab VpcId=vpc-b3870dd6 SubnetID1=subnet-09f8ca52 SubnetID2=subnet-e0eb9685 --capabilities CAPABILITY_IAM --template-file cf.yaml 

```

## Run the CloudFormation template in the AWS Console
* Login to the AWS console and browse to the CloudFormation section
* Select the "cloudformation-template.yaml” file
* Before clicking "Create", make sure that you scroll down and tick the “I acknowledge that AWS CloudFormation might create IAM resources” checkbox
* ...drink coffee...
* Go to the URL in the output section for the environment that you want to access

## Resources created
* 1 AutoScaling Group
* 1 Elastic Load Balancer
* 1 S3 bucket (for data backup)
* 1 SNS topic (send monitoring alerts)

## Autoscaling
The autoscaling groups uses the CpuUtilization alarm to autoscale automatically.

Because of this, you wouldn't have to bother making sure that your hosts can sustain the load.

## Alarms
In order to be sure that you have set up the proper limits for your containers, the following alerts have been but into place:
* NetworkInAlarm
* RAMAlarmHigh
* NetworkOutAlarm
* IOWaitAlarmHigh
* StatusAlarm
  
These CloudWatch alarms will send an email each time the limits are hit so that you will always be in control of what happens with your stack.

## Monitoring
The stack launches [NodeExporter](https://github.com/prometheus/node_exporter) <> `Prometheus exporter for hardware and OS metrics exposed by *NIX kernels, written in Go with pluggable metric collectors`, on each host inside the cluster.

To view the monitoring data, all you need to setup is a Prometheus host and a Grafana dashboard and you're all set.

## Data persistency
Due to the mechanics behind Kibana, you don't need to set up any sort of data persistency, as the application queries continously the ElasticSearch cluster in order to acquire the data that is being displayed. Hence, the data persistency that we're currently handling is the actual configuration of Kibana, which is stored for backup and reference purposes on an attached EBS volume.
      
## Backup

A cronjob has been set up to run every 3 days on the ASG hosts that dump the data in an S3 bucket that is created inside the template.
        
## Final notes
Need help implementing this?

Feel free to contact us using [this form](https://netbears.com/#contact-form).