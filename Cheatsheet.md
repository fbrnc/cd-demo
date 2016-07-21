### Local requirements
```
sudo su
apt-get update -y && apt-get install -y php5-cli php5-sqlite jq git zip wget curl
wget https://phar.phpunit.de/phpunit-4.8.9.phar -O /usr/local/bin/phpunit && chmod +x /usr/local/bin/phpunit
curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
curl -sSL https://deb.nodesource.com/setup_4.x | sudo -E bash - && apt-get install -y nodejs
curl -sSL https://bootstrap.pypa.io/get-pip.py | python && pip install awscli
```

### Clone repo:
```
git clone git@github.com:fbrnc/cd-demo.git ~/meetup
cd ~/meetup/infrastructure
composer install
alias s='/home/vagrant/meetup/infrastructure/vendor/bin/stackformation.php'
```

### Run built-in server
```
cd ~/meetup/nano-app/
sudo php -S 0.0.0.0:80 index.php
```

### Test app:
```
curl -XGET http://localhost
curl -XPUT http://localhost
curl -XDELETE http://localhost
```

### Run unit tests
```
cd ~/meetup/tests/unit
phpunit --debug
```

### Configuration
```
cp ~/.env.default ~/meetup/infrastructure/.env.default 
cp ~/FabrizioAoePlayOregon.pem ~/meetup/infrastructure/keys/
```

### Deploy stacks
- vpc, s3-jenkinsbackup, s3-artifacts, env-{env:Environment}-website
- vpc-subnets, iam, cfn-lambdahelper
- vpc-bastion
- jenkins, env-{env:Environment}-setup

### Watch stacks
```
watch -d -n 10 ~/meetup/infrastructure/vendor/bin/stackformation.php stack:list
```

### Unlock Jenkins
```
s ssh -t Name:Jenkins --command 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

### Jenkins Plugins
"Install suggested plugins", plus:
- AnsiColor
- GreenBalls
- HTML Publisher

### GitHub Webhook
https://jenkins.aoeplay.net/github-webhook/

### Jenkins Timeline
Go to [https://jenkins.aoeplay.net/script](https://jenkins.aoeplay.net/script)
```
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "")
```

### Jenkins trigger backup (before updating)
```
s ssh -t Name:Jenkins --command 'sudo /usr/local/bin/jenkins_backup’
```

### Urls
- https://jenkins.aoeplay.net/
- https://github.com/fbrnc/cd-demo