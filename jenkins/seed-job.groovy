// ==============================================================================
// CircleGuard — Jenkins Seed Job
//
// Crea automáticamente los 8 pipeline jobs (uno por microservicio).
// Ejecuta este script una sola vez desde un job de tipo "Freestyle Project"
// con el plugin Job DSL instalado. Jenkins creará todos los pipelines solo.
// ==============================================================================

def OPS_REPO_URL = 'https://github.com/ThomasBrueck/finalproject-ingesoftv-ops'
def OPS_REPO_BRANCH = '*/master'

def SERVICES = [
    'circleguard-auth-service',
    'circleguard-dashboard-service',
    'circleguard-form-service',
    'circleguard-gateway-service',
    'circleguard-identity-service',
    'circleguard-notification-service',
    'circleguard-promotion-service',
    'circleguard-file-service'
]

SERVICES.each { serviceName ->
    pipelineJob(serviceName) {
        description("""\
            Pipeline CI/CD completo para <b>${serviceName}</b>.
            <br><br>
            <b>Flujo:</b>
            Checkout → Build → Unit Tests → SonarQube → Trivy →
            Push ACR → Deploy DEV (auto) → Deploy STAGE (auto) →
            <b>Approve → PROD</b> (manual)
            <br><br>
            Jenkinsfile: <code>pipelines/Jenkinsfile.${serviceName}</code>
        """.stripIndent())

        parameters {
            stringParam(
                'DEV_REPO_BRANCH',
                'master',
                'Branch o commit SHA del repo de desarrollo a construir'
            )
        }

        properties {
            disableConcurrentBuilds()
            buildDiscarder {
                strategy {
                    logRotator {
                        numToKeepStr('10')
                        daysToKeepStr('')
                        artifactNumToKeepStr('5')
                        artifactDaysToKeepStr('')
                    }
                }
            }
        }

        definition {
            cpsScm {
                scm {
                    git {
                        remote {
                            url(OPS_REPO_URL)
                            // Credencial de GitHub configurada en Jenkins
                            // con ID 'github-credentials'
                            credentials('github-credentials')
                        }
                        branch(OPS_REPO_BRANCH)
                        extensions {
                            cloneOptions {
                                shallow(true)
                                depth(1)
                            }
                        }
                    }
                }
                scriptPath("pipelines/Jenkinsfile.${serviceName}")
                lightweight(true)
            }
        }

        triggers {
            // Se dispara automáticamente cuando GitHub envía un webhook
            githubPush()
        }
    }

    println "✓ Job creado: ${serviceName}"
}

println ""
println "========================================"
println "Seed job completado. Jobs creados: ${SERVICES.size()}"
println "Verifica en: Jenkins → Dashboard"
println "========================================"
