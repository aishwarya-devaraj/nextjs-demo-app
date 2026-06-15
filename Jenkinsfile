// ============================================================
// Jenkinsfile — Declarative Pipeline (Simplified)
// CI/CD: GitHub → Jenkins → Docker Hub → AWS EC2 (Docker)
// No ECR | No ASG | Single EC2 Instance
// ============================================================

pipeline {

    agent { label 'docker-agent' }



    // ──────────────────────────────────────────────
    // Environment Variables
    // ──────────────────────────────────────────────
    environment {
        // ── Docker Hub ──
        DOCKERHUB_USERNAME   = 'aishwaryadevaraj'                  // Docker Hub username
        DOCKERHUB_REPO       = "${DOCKERHUB_USERNAME}/nextjs-demo-app"

        // ── AWS EC2 ──
        EC2_HOST             = '54.175.95.105'                      // EC2 Public IP (EC2 public IP)
        EC2_USER             = 'ubuntu'
        SSH_KEY_ID           = 'ec2-ssh-key'                       // Jenkins SSH private key credential
        APP_PORT_CONTAINER   = '3000'
        APP_PORT_HOST        = '3000'  // Nginx owns :80, container binds to :3000
        CONTAINER_NAME       = 'nextjs-app'

        // ── Image Tag ──
        IMAGE_TAG            = ''                                   // Set in Checkout stage
        IMAGE_LATEST         = "${DOCKERHUB_REPO}:latest"
        IMAGE_VERSIONED      = ''                                   // Set in Checkout stage

        // ── Slack (optional) ──
        SLACK_CHANNEL        = '#deployments'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '15'))
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    // Auto-trigger: poll GitHub every minute + webhook when available
    triggers {
        pollSCM('* * * * *')
        githubPush()
    }

    parameters {
        booleanParam(name: 'SKIP_TESTS',   defaultValue: false, description: 'Skip lint & unit tests')
        booleanParam(name: 'FORCE_DEPLOY', defaultValue: false, description: 'Deploy on any branch')
    }

    // ╔══════════════════════════════════════════════╗
    // ║                  S T A G E S                ║
    // ╚══════════════════════════════════════════════╝
    stages {

        // ─────────────────────────────────────────
        // 1. CHECKOUT
        // ─────────────────────────────────────────
        stage('📥 Checkout') {
            steps {
                echo "🔄 Checking out source code from GitHub..."
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_BRANCH_NAME  = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG        = "${env.GIT_COMMIT_SHORT}-${BUILD_NUMBER}"
                    env.IMAGE_VERSIONED  = "${DOCKERHUB_REPO}:${env.IMAGE_TAG}"
                    env.COMMIT_MESSAGE   = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                }
                echo "📌 Branch: ${env.GIT_BRANCH_NAME} | Commit: ${env.GIT_COMMIT_SHORT}"
                echo "💬 ${env.COMMIT_MESSAGE}"
                echo "🏷️  Image will be tagged: ${env.IMAGE_VERSIONED}"
            }
        }

        // ─────────────────────────────────────────
        // 2. INSTALL DEPENDENCIES
        // ─────────────────────────────────────────
        stage('📦 Install Dependencies') {
            steps {
                echo "📦 Running npm install..."
                sh '''
                    node --version
                    npm  --version
                    NODE_OPTIONS="--max-old-space-size=512" npm install --no-audit --no-fund --prefer-offline
                '''
            }
        }

        // ─────────────────────────────────────────
        // 3. LINT & TYPE CHECK
        // ─────────────────────────────────────────
        stage('🔍 Lint') {
            when { expression { !params.SKIP_TESTS } }
            parallel {
                stage('ESLint') {
                    steps { sh 'npm run lint' }
                }
                stage('TypeScript') {
                    steps { sh 'npx tsc --noEmit || true' }
                }
            }
        }

        // ─────────────────────────────────────────
        // 4. UNIT TESTS
        // ─────────────────────────────────────────
        stage('🧪 Tests') {
            when { expression { !params.SKIP_TESTS } }
            steps {
                sh 'npm test -- --ci --watchAll=false'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/junit.xml'
                }
            }
        }

        // ─────────────────────────────────────────
        // 5. BUILD NEXT.JS
        // ─────────────────────────────────────────
        stage('🔨 Build Next.js') {
            steps {
                echo "🔨 Building Next.js application..."
                sh 'npm run build'
                echo "✅ Build complete!"
            }
        }

        // ─────────────────────────────────────────
        // 6. BUILD DOCKER IMAGE
        // ─────────────────────────────────────────
        stage('🐳 Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE_LATEST}"
                sh """
                    docker build \
                      --build-arg GIT_COMMIT=${env.GIT_COMMIT_SHORT} \
                      --build-arg BUILD_DATE=\$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
                      --tag ${IMAGE_LATEST} \
                      .
                """
                echo "✅ Docker image built!"
            }
        }

        // ─────────────────────────────────────────
        // 7. PUSH TO DOCKER HUB
        // ─────────────────────────────────────────
        stage('📤 Push to Docker Hub') {
            when {
                anyOf {
                    expression { env.GIT_BRANCH ==~ /.*main.*/ }
                    expression { env.GIT_BRANCH_NAME ==~ /.*main.*|HEAD/ }
                    expression { params.FORCE_DEPLOY }
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    echo "🔐 Logging in to Docker Hub..."
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'

                    echo "📤 Pushing: ${IMAGE_LATEST}"
                    sh "docker push ${IMAGE_LATEST}"

                    echo "✅ Image pushed to Docker Hub!"
                    sh "docker logout"
                }
            }
        }

        // ─────────────────────────────────────────
        // 8. DEPLOY TO EC2 VIA SSH
        // ─────────────────────────────────────────
        stage('🚀 Deploy to EC2') {
            when {
                anyOf {
                    expression { env.GIT_BRANCH ==~ /.*main.*/ }
                    expression { env.GIT_BRANCH_NAME ==~ /.*main.*|HEAD/ }
                    expression { params.FORCE_DEPLOY }
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    echo "🚀 Deploying ${IMAGE_LATEST} directly on this server..."
                    sh """
                        echo "🔐 Logging into Docker Hub..."
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin

                        echo "📦 Pulling latest image..."
                        docker pull ${IMAGE_LATEST}

                        echo "🛑 Stopping existing container (if any)..."
                        docker stop ${CONTAINER_NAME} 2>/dev/null || true
                        docker rm   ${CONTAINER_NAME} 2>/dev/null || true

                        echo "▶️  Starting new container..."
                        docker run -d \\
                          --name ${CONTAINER_NAME} \\
                          --restart unless-stopped \\
                          -p ${APP_PORT_HOST}:${APP_PORT_CONTAINER} \\
                          -e NODE_ENV=production \\
                          -e PORT=${APP_PORT_CONTAINER} \\
                          ${IMAGE_LATEST}

                        echo "🧹 Removing dangling images..."
                        docker image prune -f

                        docker logout
                        echo "✅ Container is running!"
                        docker ps --filter name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                    """
                }
            }
        }

        // ─────────────────────────────────────────
        // 9. HEALTH CHECK (post-deploy)
        // ─────────────────────────────────────────
        stage('💨 Health Check') {
            when {
                anyOf {
                    expression { env.GIT_BRANCH ==~ /.*main.*/ }
                    expression { env.GIT_BRANCH_NAME ==~ /.*main.*|HEAD/ }
                    expression { params.FORCE_DEPLOY }
                }
            }
            steps {
                echo "💨 Running health check against EC2..."
                sh """
                    sleep 20   # allow container to boot

                    HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" \
                        http://${EC2_HOST}/api/health --max-time 10)

                    echo "  HTTP Status: \${HTTP_STATUS}"

                    if [ "\${HTTP_STATUS}" = "200" ]; then
                        echo "✅ Health check PASSED!"
                    else
                        echo "❌ Health check FAILED (HTTP \${HTTP_STATUS})"
                        exit 1
                    fi
                """
            }
        }

    } // end stages

    // ──────────────────────────────────────────────
    // POST-PIPELINE
    // ──────────────────────────────────────────────
    post {
        always {
            echo "🧹 Cleaning up local Docker images..."
            sh """
                docker rmi ${env.IMAGE_VERSIONED} ${IMAGE_LATEST} 2>/dev/null || true
                docker system prune -f --filter "until=24h"
            """
            cleanWs()
        }
        success {
            echo "🎉 Pipeline PASSED for build #${BUILD_NUMBER}"
        }
        failure {
            echo "💥 Pipeline FAILED for build #${BUILD_NUMBER}"
        }
    }

} // end pipeline
