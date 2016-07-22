node {

    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {

        stage "Checkout"
        checkout scm
        // delete old artifacts
        sh "rm -rf artifacts ; mkdir artifacts"

        dir('nano-app') {
            stage "Static Code Analysis"
            sh '../tests/static/phplint.sh . > /dev/null'

            stage "Build"
            sh '/usr/local/bin/box build'

            stage "Publish Artifact"
            sh 'aws s3 cp ../artifacts/hitcounter.phar s3://meetup-artifacts/hitcounter/${BUILD_NUMBER}/hitcounter.phar'
        }
        step([$class: 'ArtifactArchiver', artifacts: 'artifacts/hitcounter.phar', fingerprint: true])

        stage 'Unit Tests'
        dir('tests/unit') {
            sh "/usr/local/bin/phpunit --debug --colors --log-junit ../../artifacts/junit.xml"
        }
        step([$class: 'JUnitResultArchiver', testResults: 'artifacts/junit.xml'])

        dir('infrastructure') {
            sh '/usr/local/bin/composer --ansi --no-dev --no-progress --no-interaction install'
        }

        withEnv(["Environment=tst", "DEPLOY_ID=${env.BUILD_NUMBER}", "AWS_DEFAULT_REGION=us-west-2", "USE_INSTANCE_PROFILE=1"]) {
            dir('infrastructure') {
                stage name: "Deploy to ${env.Environment}", concurrency: 1
                echo "Deploying to ${env.Environment}"
                sh "vendor/bin/stackformation.php blueprint:deploy --ansi --deleteOnTerminate 'env-{env:Environment}-deploy{env:DEPLOY_ID}'"
                sh "vendor/bin/stackformation.php stack:timeline 'env-${env.Environment}-deploy${env.DEPLOY_ID}' > ../artifacts/timeline_${env.Environment}.html"
            }
            publishHTML(target: [reportDir: 'artifacts', reportFiles: "timeline_${env.Environment}.html", reportName: "Deploy Timeline for ${env.Environment}"])

            stage name: "Integration test ${env.Environment}", concurrency: 1
            sh "bash -x tests/integration/integration_test.sh http://api-${env.Environment}.aoeplay.net/"

            stage name: "Stress testing ${env.Environment}", concurrency: 1
            sh "bash tests/stress/stress_test.sh http://api-${env.Environment}.aoeplay.net/"
        }

        /*
        withEnv(["Environment=prd", "DEPLOY_ID=${env.BUILD_NUMBER}", "AWS_DEFAULT_REGION=us-west-2", "USE_INSTANCE_PROFILE=1"]) {
            dir('infrastructure') {
                stage name: "Deploy to ${env.Environment}", concurrency: 1
                timeout(time: 10, unit: 'MINUTES') {
                     input "Proceed deploying to ${env.Environment}?"
                }
                echo "Deploying to ${env.Environment}"
                sh "vendor/bin/stackformation.php blueprint:deploy --ansi --deleteOnTerminate 'env-{env:Environment}-deploy{env:DEPLOY_ID}'"
                sh "vendor/bin/stackformation.php stack:timeline 'env-${env.Environment}-deploy${env.DEPLOY_ID}' > ../artifacts/timeline_${env.Environment}.html"
            }
            publishHTML(target: [reportDir: 'artifacts', reportFiles: "timeline_${env.Environment}.html", reportName: "Deploy Timeline for ${env.Environment}"])
        }
        */

        echo "Done"
    }

}
