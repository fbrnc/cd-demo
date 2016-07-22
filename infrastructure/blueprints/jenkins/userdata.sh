#!/usr/bin/env bash

CFN_SIGNAL_PARAMETERS='--stack {Ref:AWS::StackName} --resource AutoScalingGroup --region {Ref:AWS::Region}'

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

BACKUP="{Ref:Backup}"
if [ -z "${BACKUP}" ] ; then error_exit "No BACKUP set"; fi
# Force trailing slash
BACKUP="${BACKUP%/}/"

yum update -y || error_exit "Failed to update OS packages"
yum -y install jq || error_exit "Failed installing tools"

# Install PHP
yum -y install git php56-cli php56-pdo php56-mysqlnd || error_exit "Failed to install git and php"
sed -i "s/.*date.timezone.*/date.timezone = \"America\/Los_Angeles\"/" /etc/php.ini
sed -i "s/.*phar.readonly.*/phar.readonly = Off/" /etc/php.ini

# Install box (for creating phars)
curl -LSs https://box-project.github.io/box2/installer.php | php || error_exit "Failed installing box"
mv box.phar /usr/local/bin/box || error_exit "Failed moving box file"
chmod +x /usr/local/bin/box || error_exit "Failed setting permissions for box"

# Install composer
export HOME=/root
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer || error_exit "Failed installing composer"

# Install PHPUnit
wget https://phar.phpunit.de/phpunit-4.8.9.phar -O /usr/local/bin/phpunit || error_exit "Failed installing phpunit"
chmod +x /usr/local/bin/phpunit || error_exit "Failed setting permissions for phpunit"

# Install StackFormation
#wget $(curl -s https://api.github.com/repos/AOEpeople/StackFormation/releases/latest | jq -r '.assets[0].browser_download_url') -O /usr/local/bin/stackformation || error_exit "Failed installing stackformation"
#chmod +x /usr/local/bin/stackformation || error_exit "Failed setting permissions for stackformation"
# ... comes via Composer

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo || error_exit "Failed to download Jenkins repo information"
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key || error_exit "Failed to import the Jenkins repo key"
yum -y install jenkins || error_exit "Failed to install Jenkins"

# Install apache benchmark
yum -y install httpd-tools

# Setup backup script
cat > /usr/local/bin/jenkins_backup <<'EOL'
#!/usr/bin/env bash
tar -C /var/lib/jenkins -zcf /tmp/backup.tar.gz . \
    --exclude "config-history/" \
    --exclude "config-history/*" \
    --exclude "jobs/*/workspace*" \
    --exclude "jobs/*/builds/*/archive" \
    --exclude "war" \
    --exclude "cache"

aws s3 cp /tmp/backup.tar.gz "{Ref:Backup}`date +\%Y\%m\%d\%H\%M\%s.tar.gz`"
rm -f /tmp/backup.tar.gz
EOL
chmod +x /usr/local/bin/jenkins_backup
line="@daily /usr/local/bin/jenkins_backup"
(crontab -u root -l; echo "$line" ) | crontab -u root -

# Restore backup
BACKUP_ARCHIVE=$(aws s3 ls ${BACKUP} | tail -1 | awk '{print $NF}')
if [ -z "${BACKUP_ARCHIVE}" ] ; then
    echo "No backup found"
else
    echo "Downloading backup file: ${BACKUP}${BACKUP_ARCHIVE}"
    aws s3 cp "${BACKUP}${BACKUP_ARCHIVE}" "/tmp/restore.tar.gz" || error_exit "Failed to download the backup file"

    JENKINS_HOME="/var/lib/jenkins"

    echo "Deleting current Jenkins home directory (${JENKINS_HOME})"
    if [[ -d "${JENKINS_HOME}" ]]; then
        rm -rf "${JENKINS_HOME}" || error_exit "Failed to remove an existing Jenkins home"
    fi
    mkdir -p "${JENKINS_HOME}" || error_exit "Failed to create Jenkins home"

    echo "Extracting /tmp/restore.tar.gz to ${JENKINS_HOME}"
    tar zxf "/tmp/restore.tar.gz" -C "${JENKINS_HOME}" || error_exit "Failed to extract the jenkins backup"
    rm "/tmp/restore.tar.gz"
fi

# Installing docker
yum -y install docker || error_exit "Failed to install docker"
service docker start  || error_exit "Failed to start docker"
chkconfig docker on  || error_exit "Failed to enable auto-start for docker"
sudo usermod -a -G docker jenkins || error_exit "Failed adding jenkins to docker group"

# Configuring service
service jenkins start || error_exit "Failed to start Jenkins"
chkconfig jenkins on || error_exit "Failed to enable auto-start for Jenkins"