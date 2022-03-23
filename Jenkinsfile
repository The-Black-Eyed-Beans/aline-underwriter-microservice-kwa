pipeline {
    agent any

    tools {
        maven "Maven 3.8.4"
    }

    environment {
        REGION = "us-east-1"
        AWS_USER_ID = credentials("jenkins-aws-user-id")
        MICROSERVICE = "underwriter_microservice"
        COMMIT_HASH = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
    }
    parameters {
        string(name: "BRANCH_NAME", description: "The branch to checkout.")
    }
    
    stages {
        stage("Checkout") {
            steps {
                sh "git submodule init && git submodule update"
            }
        }

        stage("Compiling") {
            steps {
                sh "mvn clean compile"
            }
        }

        stage("Sonar Scan") {
            steps {
                withSonarQubeEnv(installationName: "SonarQube-Server") {
                    sh "mvn verify sonar:sonar -Dsonar.projectName=kwa-${MICROSERVICE}"
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 3, unit: "MINUTES") {
                    waitForQualityGate abortPipeline: true
                }  
            }
        }

        stage("Packaging") {
            steps {
                sh "mvn clean package -Dmaven.test.skip=true"
            }
        }

        stage("Building Image") {
            steps {
                sh "docker build -t kwa-${MICROSERVICE} ."

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'aws-key', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
    
                    sh "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_USER_ID}.dkr.ecr.${REGION}.amazonaws.com"
                    sh "docker tag kwa-${MICROSERVICE}:latest ${AWS_USER_ID}.dkr.ecr.${REGION}.amazonaws.com/kwa-${MICROSERVICE}:latest"
                    sh "docker push ${AWS_USER_ID}.dkr.ecr.${REGION}.amazonaws.com/kwa-${MICROSERVICE}:latest"
                
                }
            }
        }

        stage("Deploying") {
            steps {
                echo "Deploying ${MICROSERVICE}-kwa"
                sh "aws cloudformation create-stack --stack-name underwriter-kwa-stack --profile kevin --template-body file://ecs.yml"
            }
        }
    }

    post {
        always {
            echo "pipeline done"
        }

        cleanup {
            sh "docker rmi ${AWS_USER_ID}.dkr.ecr.${REGION}.amazonaws.com/kwa-${MICROSERVICE}:latest"
        }
    }
}

