pipeline {
  agent {
    docker {
      image 'abhishekf5/maven-abhishek-docker-agent:v1'
      args '--user root -v /var/run/docker.sock:/var/run/docker.sock' // mount Docker socket
    }
  }
  environment {
    S3_BUCKET = 'bucketversion'
    VERSION = "${env.BUILD_NUMBER}"  // Use Jenkins build number for versioning
    ARTIFACT_NAME = "student-${VERSION}.war"  // Artifact name with version
  }
  stages {
    // stage('Checkout') {
    //   steps {
    //     script {
    //       withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
    //         sh "git clone https://${GITHUB_TOKEN}@github.com/Aamantamboli/Studentapp.git"
    //       }
    //     }
    //   }
    // }
    stage('Build') {
      steps {
        echo "Building the application..."
        sh 'mvn clean package'
      }
    }
    // stage('Upload to S3') {
    //   steps {
    //     echo "Uploading WAR file to S3..."
    //     withCredentials([string(credentialsId: 'aws-access-id', variable: 'AWS_ACCESS_KEY_ID'),
    //                      string(credentialsId: 'aws-secret-id', variable: 'AWS_SECRET_ACCESS_KEY')]) {
    //       sh 'aws s3 cp target/*.war s3://$S3_BUCKET/$ARTIFACT_NAME'
    //     }
    //   }
    // }
    stage('Static Code Analysis') {
      environment {
        SONAR_URL = "http://13.127.83.149:9000"
      }
      steps {
        withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_AUTH_TOKEN')]) {
          sh 'mvn sonar:sonar -Dsonar.login=$SONAR_AUTH_TOKEN -Dsonar.host.url=${SONAR_URL}'
        }
      }
    }
    stage('Build and Push Docker Image') {
      environment {
        DOCKER_IMAGE = "aamantamboli/mynewstudentapp:${BUILD_NUMBER}"
        REGISTRY_CREDENTIALS = credentials('docker-cred')
      }
      steps {
        script {
          sh 'docker build -t ${DOCKER_IMAGE} .'
          def dockerImage = docker.image("${DOCKER_IMAGE}")
          docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
            dockerImage.push()
          }
        }
      }
    }
  stage('Update Deployment File') {
  environment {
    GIT_REPO_NAME = "Studentapp"
    GIT_USER_NAME = "Aamantamboli"
  }
  steps {
    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
      sh '''
        git config user.email "amantamboli671@gmail.com"
        git config user.name "Aaman Tamboli"
        
        # Make sure the environment variable BUILD_NUMBER is interpolated correctly in the shell
        BUILD_NUMBER=${BUILD_NUMBER}
        
        # Modify the deployment.yml file with the build number
        sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" deployment.yml
        
        # Add, commit, and push the updated file to GitHub using the GitHub token for authentication
        git add deployment.yml
        git commit -m "Update deployment image to version ${BUILD_NUMBER}"
        
        # Explicitly use double-quotes for proper interpolation
        git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
      '''
      }
     }
    }
  }
}
