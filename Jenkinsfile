#!/usr/bin/env bash

CFN_SIGNAL_PARAMETERS='--stack {Ref:AWS::StackName} --resource AppAsg --region {Ref:AWS::Region}'

function error_exit {
    echo ">>> ERROR_EXIT: $1. Signaling error to wait condition..."
    /opt/aws/bin/cfn-signal --exit-code 1 --reason "$1" ${CFN_SIGNAL_PARAMETERS}
    exit 1
}
function done_exit {
    rv=$?
    if [ "$rv" == "0" ] ; then
        echo ">>> Signaling success to CloudFormation"
        /opt/aws/bin/cfn-signal --exit-code 0 ${CFN_SIGNAL_PARAMETERS}
    else
        echo ">>> NOT sending success signal to CloudFormation (return value: ${rv})"
        echo ">>> DONE_EXIT: Signaling error to wait condition..."
        /opt/aws/bin/cfn-signal --exit-code 1 --reason "Trap" ${CFN_SIGNAL_PARAMETERS}
    fi
    exit $rv
}
trap "done_exit" EXIT

yum update -y || error_exit "Failed updating packages"
yum install -y docker || error_exit "Failed installing docker"
service docker start || error_exit "Failed starting docker"

export DB_DSN="mysql:host=db-{Ref:EnvironmentName}.{Ref:InternalDomainName};dbname=app_{Ref:EnvironmentName}"
export DB_USER="app_{Ref:EnvironmentName}"
export DB_PASSWD="{Ref:DbPwd}"
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# Login to ECR
$(aws ecr get-login --region "{Ref:AWS::Region}")

# Run container
docker run -d -t -i -p 80:80 \
    -e DB_DSN=$DB_DSN \
    -e DB_USER=$DB_USER \
    -e DB_PASSWD=$DB_PASSWD \
    -e INSTANCE_ID=$INSTANCE_ID \
    "{Ref:AWS::AccountId}.dkr.ecr.{Ref:AWS::Region}.amazonaws.com/nano:{Ref:Build}"