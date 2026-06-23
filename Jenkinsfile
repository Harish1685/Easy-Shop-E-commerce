pipeline{
    agent any
    
    environment{
        DOCKER_IMAGE_NAME = "harishkumar1/easyshop-app"
        DOCKER_MIGRATION_IMAGE_NAME = "harishkumar1/easyshop-migration"
        BUILD_NUMBER = "${BUILD_NUMBER}"
    }
    stages {
        stage("cleanup WorkSpace"){
            steps{
                cleanWs()
            }
        }
        stage("checkout the code"){
            steps{
                git branch: 'main', url: 'https://github.com/Harish1685/Easy-Shop-E-commerce.git'
            }
        }
        stage("Build Docker images"){
            parallel{
                stage("Build Main app image"){
                    steps{
                        sh """
                        docker build \
                        -t ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} \
                        -f Dockerfile .
                        """
                    }
                }
                stage("Build migration image"){
                    steps{
                        sh """
                        docker build \
                        -t ${DOCKER_MIGRATION_IMAGE_NAME}:${BUILD_NUMBER} \
                        -f scripts/Dockerfile.migration .
                        """
                    }
                }
            }
        }
        stage("Run Tests"){
            steps{
                echo "Testing Done .... "
            }
        }
        stage("Trivy Scan"){
            steps{
                sh "trivy fs ."
            }
        }
        stage("Push Docker Images"){
            parallel{
                stage("Push Main App"){
                    steps{
                        withCredentials([ usernamePassword( 
                            credentialsId: 'docker-hub-credentials', 
                            usernameVariable: 'DOCKER_USERNAME', 
                            passwordVariable: 'DOCKER_PASSWORD'
                            )]){
                                sh """
                                echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                                docker push $DOCKER_IMAGE_NAME:$BUILD_NUMBER
                                """
                            }
                            }
                    
                }
                stage("Push Migration Image"){
                    steps{
                        withCredentials([ usernamePassword( 
                            credentialsId: 'docker-hub-credentials', 
                            usernameVariable: 'DOCKER_USERNAME', 
                            passwordVariable: 'DOCKER_PASSWORD'
                            )]){
                                sh """
                                echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                                docker push $DOCKER_MIGRATION_IMAGE_NAME:$BUILD_NUMBER
                                """
                            }
                    }
                }
                
            }
        }
    }
}