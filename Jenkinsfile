#!/usr/bin/env groovy

def IMAGE_VERSION
def IMAGE_NAME
def BR_NAME
def SIT_DOCKER_REPO = "uat.repo.garm.co.ir:80/repository/garm-docker-group"
def UAT_DOCKER_REPO = "uat.repo.garm.co.ir:80/repository/garm-docker-group"
def PROD_DOCKER_REPO = "repo.garm.co.ir/repository/garm-docker-group"
def APP_NAME = "captcha-app"
def KUBE_MASTER = "103"

pipeline {

    agent {
        docker {
            image '172.30.43.99:80/repository/garm-docker-group/java-pipline-agent:j8-m3.6-d17-1'
            args ' -it -u 0 --group-add 994 ' + // stat -c '%g' /var/run/docker.sock = 994
                    '-v /etc/docker/daemon.json:/etc/docker/daemon.json ' +
                    '-v /root/.docker/config.json:/root/.docker/config.json ' +
                    '-v /var/run/docker.sock:/var/run/docker.sock ' +
                    '-v /root/.kube:/root/.kube ' +
                    '-v /etc/hosts:/etc/hosts ' +
                    '-v /root/.m2/repository:/root/.m2/repository'
        }
    }


    parameters {
        booleanParam(name: 'UPDATE_VERSION_WITHOUT_INITIALIZE', defaultValue: true, description: 'This is a update version without initialize kubernetes resources')
    }

    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
    }

    triggers {
        bitbucketPush()
    }

    stages {

        stage('checkout') {
            steps {
                checkout scm
            }
        }

        stage('process resources') {
            environment {
                IMG = readMavenPom().getArtifactId()
                VER = readMavenPom().getVersion()
            }
            steps {
                script {
                    BR_NAME = "${env.BRANCH_NAME}"
                    if (env.CHANGE_BRANCH) {
                        BR_NAME = "${env.CHANGE_BRANCH}"
                    }
                    IMAGE_NAME = "${IMG}"
                    IMAGE_VERSION = "${VER}"
                }
                stash includes: 'Jenkinsfile,.kube/uat/*', name: 'stage-resources-stash'
                stash includes: 'Jenkinsfile,.kube/prod/*', name: 'prod-resources-stash'
            }
        }

        stage('clean') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('package') {
            steps {
                sh 'mvn clean package -Pprod -DskipTests'
            }
        }

        /* stage('quality analysis') {
            environment {
                SONAR_LOGIN = 'ec8bc094c7bbfc39e514ceef0da9923af84c8d51'
                PROJECT_KEY_NAME = 'p100-open-api-captcha-app'
            }
            steps {
                sh "mvn sonar:sonar -Dsonar.branch.name='${BR_NAME}' -Dsonar.host.url=http://sonar.garm.local -Dsonar.projectName='${PROJECT_KEY_NAME}' -Dsonar.projectKey='${PROJECT_KEY_NAME}' -Dsonar.login=${SONAR_LOGIN}"
            }
        } */

        stage("build & push image to sit repo ") {
            when {
                branch 'develop'
            }
            steps {
                script {
                    myapp = docker.build("${SIT_DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER}", "-f ./src/main/docker/Dockerfile .")
                    myapp.push("${IMAGE_VERSION}-${env.BUILD_NUMBER}")
                }
            }
        }


        stage("build & push image to uat repo ") {
            when {
                branch 'stage'
            }
            steps {
                script {
                    myapp = docker.build("${UAT_DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER}", "-f ./src/main/docker/Dockerfile .")
                    myapp.push("${IMAGE_VERSION}-${env.BUILD_NUMBER}")
                }
            }
        }

        stage("build & push image to prod repo ") {
            when {
                branch 'master'
            }
            steps {
                script {
                    myapp = docker.build("${PROD_DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER}", "-f ./src/main/docker/Dockerfile .")
                    myapp.push("${IMAGE_VERSION}-${env.BUILD_NUMBER}")
                    myapp.push("latest")
                }
            }
        }

        stage('init kubernetes sit') {
            when {
                allOf {
                    branch 'develop'
                    expression { params.UPDATE_VERSION_WITHOUT_INITIALIZE == false }
                }
            }
            steps {
                sh '''#!/bin/sh
                   kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.sit delete deploy/${APP_NAME} --namespace=garm
                   kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.sit apply -f .kube/namespace.yml
                   kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.sit apply -f .kube/sit/ --namespace=garm
                   '''
            }
        }

        stage('update kubernetes sit') {
            when {
                branch 'develop'
            }
            steps {
                sh "kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.sit set image deployment/${APP_NAME} ${APP_NAME}=${UAT_DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER} --namespace=garm"
            }
        }

        stage('init kubernetes uat') {
            when {
                allOf {
                    branch 'stage'
                    expression { params.UPDATE_VERSION_WITHOUT_INITIALIZE == false }
                }
            }
            steps {
                input "Do you approve to deploy ${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER} image to stage environment?"
                echo 'deploy to stage ...'
                sh '''#!/bin/sh
                    kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.uat delete  deploy/${APP_NAME} --namespace=garm
                    kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.uat apply -f .kube/namespace.yml
                    kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.uat apply -f .kube/uat/ --namespace=garm
                   '''
            }
        }

        stage('update kubernetes uat') {
            when {
                branch 'stage'
            }
            steps {
                sh 'rm -rf ./*'
                input "Do you approve to deploy ${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER} image to stage environment?"
                sh "kubectl --kubeconfig ~/.kube/${KUBE_MASTER}/config.uat set image deployment/${APP_NAME} ${APP_NAME}=${UAT_DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_VERSION}-${env.BUILD_NUMBER} --namespace=garm"
            }
        }

        stage('clean target') {
            steps {
             sh '''#!/bin/sh
                 chmod 777 -R *
                 rm -rf target
                '''
            }
        }
    }
}