
pipeline {
    agent { docker { image 'node:6.3' } }
    parameters {
      string(name: 'runNumber', defaultValue: '0', description: 'JFrog Pipelines Run Number')
    }
    stages {
        stage('build') {
            steps {
                sh 'npm --version'
                echo "RunNumber sent from pipelines is: ${params.runNumber}"
                sh 'printenv'
                sh 'sleep 30'
            }
        }
        stage('report') {
            steps {
                jfPipelines(
                    outputResources: """[
                        {
                          "name": "johns_jenkins_output",
                          "content": {
                            "runNumber": "${params.runNumber}",
                            "jobName": "${JOB_NAME}"
                          }
                        }
                    ]"""
                )
            }
        }
    }
}
