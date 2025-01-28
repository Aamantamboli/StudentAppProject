pipeline {
    agent {
        docker {
            image 'aamantamboli/javamvn'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock' // Mount Docker socket
        }
    }

    environment {
        VERSION = "${BUILD_NUMBER}"
        ARTIFACT_NAME = "student-${VERSION}.war"
        AWS_REGION = 'ap-south-1'
        SONAR_URL = 'http://3.110.178.155:9000'
        BRANCH = 'main'
        IMAGE_NAME = 'aamantamboli/mynewstudentapp'
        NEW_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Source Repository') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh "git clone https://${GITHUB_TOKEN}@github.com/Aamantamboli/Studentapp1.git"
                    }
                }
            }
        }

        stage('Checkout Deployment Repo') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        dir('deployment-repo') {
                            sh "git clone https://${GITHUB_TOKEN}@github.com/Aamantamboli/deployment-repo.git"
                        }
                    }
                }
            }
        }

        stage('Build with Maven') {
            steps {
                script {
                    echo 'Building Artifact'
                    sh 'mvn clean package'
                }
            }
        }

        stage('Upload to S3') {
            steps {
                withAWS(credentials: 'aws-access-id') {
                    script {
                        echo 'Uploading Artifact to S3'
                        sh "aws s3 cp target/*.war s3://$S3_BUCKET/$ARTIFACT_NAME"
                    }
                }
            }
        }

        stage('Static Code Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_AUTH_TOKEN')]) {
                    script {
                        echo 'Running SonarQube Analysis'
                        sh 'mvn sonar:sonar -Dsonar.login=$SONAR_AUTH_TOKEN -Dsonar.host.url=${SONAR_URL}'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker Image'
                    sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo 'Pushing Docker Image to Docker Hub'
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-cred') {
                        sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Update Deployment Repo with New Image Tag') {
            steps {
                script {
                    echo 'Updating Docker Image Tag in deployment.yml'

                    // Replace the Docker image tag in deployment.yml inside deployment-repo
                    dir('deployment-repo') {
                        sh """
                            sed -i 's|${IMAGE_NAME}:[0-9]*|${IMAGE_NAME}:${NEW_TAG}|' deployment.yml
                        """
                    }
                }
            }
        }

        stage('Commit and Push Changes') {
            steps {
                script {
                    echo 'Committing and Pushing Changes to Deployment Repo'

                    // Ensure consistent git operations
                    dir('deployment-repo') {
                        // Configure Git to avoid permission issues
                        sh '''
                            git config --global user.name "Aamantamboli"
                            git config --global user.email "amantamboli671@gmail.com"
                            git checkout ${BRANCH}
                            git pull origin ${BRANCH}
                            
                            git add deployment.yml
                            git commit -m "Update Docker image tag to ${NEW_TAG}"
                            git push origin ${BRANCH}
                        '''
                    }
                }
            }
        }
    }
}
