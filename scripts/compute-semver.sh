#!/usr/bin/env bash
# ==============================================================================
# compute-semver.sh — Versionado Semántico Automático (SCRUM-33)
#
# Calcula la siguiente versión SemVer (vMAJOR.MINOR.PATCH) de un microservicio
# a partir de los Conventional Commits acumulados desde el último tag de release,
# sin intervención manual.
#
# Reglas de bump (ver 01-metodologia-agil-branching.md §2.9):
#   feat! / refactor! / BREAKING CHANGE   → MAJOR  (v1.2.3 → v2.0.0)
#   feat:                                 → MINOR  (v1.2.3 → v1.3.0)
#   fix: / perf: / chore: / otros         → PATCH  (v1.2.3 → v1.2.4)
#
# Los tags viven en el repo de la aplicación (dev), una serie por servicio:
#   <service-name>/vMAJOR.MINOR.PATCH    ej. circleguard-auth-service/v1.4.0
#
# Uso (desde la raíz del repo ops, con el repo dev clonado en ./app):
#   SERVICE_NAME=circleguard-auth-service APP_DIR=app ./scripts/compute-semver.sh
#
# Salida:
#   - stdout: la versión calculada (ej. 1.4.0)
#   - si GITHUB_OUTPUT está definido (GitHub Actions): escribe version=<X.Y.Z>
# ==============================================================================
set -euo pipefail

SERVICE="${SERVICE_NAME:?SERVICE_NAME es requerido}"
APP_DIR="${APP_DIR:-app}"

cd "$APP_DIR"
git fetch --tags --quiet 2>/dev/null || true

# Último tag de la serie del servicio: <service>/vX.Y.Z
LAST_TAG="$(git tag -l "${SERVICE}/v*" | sort -V | tail -1 || true)"

bump_and_emit() {
    local version="$1"
    echo "$version"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "version=${version}" >> "$GITHUB_OUTPUT"
    fi
}

# Primera release del servicio: arranca en 1.0.0
if [ -z "$LAST_TAG" ]; then
    echo "No existe tag previo para ${SERVICE}; primera release." >&2
    bump_and_emit "1.0.0"
    exit 0
fi

# Parsear MAJOR.MINOR.PATCH del último tag
CURRENT="${LAST_TAG#${SERVICE}/v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
MAJOR="${MAJOR:-0}"; MINOR="${MINOR:-0}"; PATCH="${PATCH:-0}"

# Commits que afectan a este servicio desde el último tag
RANGE="${LAST_TAG}..HEAD"
MESSAGES="$(git log "$RANGE" --pretty=format:'%s%x1f%b%x1e' -- "services/${SERVICE}/" 2>/dev/null || true)"

# Determinar nivel de bump
LEVEL="patch"
if printf '%s' "$MESSAGES" | grep -qE '^[a-z]+(\([^)]+\))?!:' \
   || printf '%s' "$MESSAGES" | grep -q 'BREAKING CHANGE'; then
    LEVEL="major"
elif printf '%s' "$MESSAGES" | grep -qE '^feat(\([^)]+\))?:'; then
    LEVEL="minor"
fi

echo "Último tag: ${LAST_TAG} | bump: ${LEVEL}" >&2

case "$LEVEL" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
esac

bump_and_emit "${MAJOR}.${MINOR}.${PATCH}"
