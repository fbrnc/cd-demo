node {

    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {

        stage "Checkout"
        checkout scm
        // delete old artifacts
        sh "rm -rf artifacts ; mkdir artifacts"

        dir('nano-app') {
            stage "Build"
            sh '/usr/local/bin/box build'

            stage "Publish Artifact"
            sh 'aws s3 cp ../artifacts/hitcounter.phar s3://meetup-artifacts/hitcounter/${BUILD_NUMBER}/hitcounter.phar'
        }

        dir('infrastructure') {
            sh '/usr/local/bin/composer --ansi --no-dev --no-progress --no-interaction install'
        }

        withEnv(["Environment=tst", "DEPLOY_ID=${env.BUILD_NUMBER}", "AWS_DEFAULT_REGION=us-west-2", "USE_INSTANCE_PROFILE=1"]) {
            dir('infrastructure') {
                stage name: "Deploy to ${env.Environment}", concurrency: 1
                sh "vendor/bin/stackformation.php blueprint:deploy --ansi --deleteOnTerminate 'env-{env:Environment}-deploy{env:DEPLOY_ID}'"
            }
        }
    }

}
