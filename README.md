# ELK cluster on CentOS
This is a tutorial on how to deploy an autoscaling ELK cluster on CentOS in AWS using CloudFormation.

![ELK Cluster Architect](https://raw.githubusercontent.com/changli3/elk-prod-cluster/master/elk-stack-architect.JPG "ELK Cluster Architect")

The CloudFormation template and explanation is based on the [NETBEARS](https://netbears.com/blog/elasticsearch-cluster-ubuntu/) company blog. You might want to check the website out for more tutorials like this.

## Notes

This CloudFormation creates follows artifacts:
* ElasticSearch cluster, with an internal loadbalancer (port 9200)
* Kibana cluster, using the same internal loadbalancer (port 80)
* Logstash injestion service cluster, using the same internal loadbalancer (port 5504)
* 3 AutoScaling Group
* 1 Elastic Load Balancer
* 1 S3 bucket (for data backup)
* 1 SNS topic (send monitoring alerts)
* 1 Bastion with mangement utilities/scripts installed
* 1 Grafana mornitor instance

## Run the CloudFormation template with AWS CLI

```
git clone https://github.com/changli3/elk-prod-cluster.git

aws cloudformation deploy --stack-name elasticsearch02 --parameter-overrides Ami=ami-26ebbc5c AsgMaxSize=8 AsgMinSize=2 EmailAlerts=chang.li3@treasury.gov InstanceType=m4.large KeyName=TreaEBSLab VpcId=vpc-b3870dd6 SubnetID1=subnet-09f8ca52 SubnetID2=subnet-e0eb9685 AllowIPs='172.31.0.0/16' --capabilities CAPABILITY_IAM --template-file cf.yaml 
```

This will take about 45 minutes to get the instances started.

## Run the CloudFormation template in the AWS Console
* Login to the AWS console and browse to the CloudFormation section
* Select the "cf.yaml” file
* Before clicking "Create", make sure that you scroll down and tick the “I acknowledge that AWS CloudFormation might create IAM resources” checkbox
* ...drink coffee and wait 45 minutes...
* Go to the URL in the output section for the environment that you want to access


## Autoscaling
The autoscaling groups uses the CpuUtilization alarm to autoscale automatically. Because of this, you wouldn't have to bother making sure that your hosts can sustain the load.

## Alarms
In order to be sure that you have set up the proper limits for your containers, the following alerts have been but into place:
* NetworkInAlarm
* RAMAlarmHigh
* NetworkOutAlarm
* IOWaitAlarmHigh
* StatusAlarm
  
These CloudWatch alarms will send an email each time the limits are hit so that you will always be in control of what happens with your stack.
      
## Backup
A cronjob has been set up to run every 3 days on the ASG hosts that dump the data in an S3 bucket that is created inside the template.
        