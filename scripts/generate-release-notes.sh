#!/bin/bash
# Generates release-notes.md from git log using Conventional Commits.
# Required env vars: SERVICE_NAME, IMAGE_TAG. Optional: DEV_COMMIT.
# Expects the DEV repo checked out in app/.

SERVICE="${SERVICE_NAME}"
VERSION="v${IMAGE_TAG}"
BUILD="${IMAGE_TAG}"
COMMIT="${DEV_COMMIT:-unknown}"
DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')

# Collect commits from the DEV repo checked out in app/
# Tags are per-service: <service-name>/vX.Y.Z (see deploy-prod tag step).
cd app
PREV_TAG=$(git tag -l "${SERVICE}/v*" 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$PREV_TAG" ]; then
    LOG=$(git log --pretty=format:"%h|%s|%an|%ad" --date=short --no-merges | head -30)
else
    LOG=$(git log "${PREV_TAG}..HEAD" --pretty=format:"%h|%s|%an|%ad" --date=short --no-merges)
fi
cd ..

# Conventional Commits permite scope: "feat(api): ..." — el patrón acepta
# ambas formas (con y sin scope).
cc() { echo "$LOG" | grep -E "\|$1(\([^)]*\))?(!)?:" || true; }

# ── Header ────────────────────────────────────────────────────────────────────
{
    echo "# Release Notes: ${SERVICE} ${VERSION}"
    echo ""
    echo "| Campo         | Valor                           |"
    echo "|---------------|---------------------------------|"
    echo "| Servicio      | ${SERVICE}                      |"
    echo "| Version       | ${VERSION}                      |"
    echo "| Build         | ${BUILD}                        |"
    echo "| Commit DEV    | ${COMMIT}                       |"
    echo "| Fecha         | ${DATE}                         |"
    echo "| Ambiente      | PRODUCCION                      |"
    echo ""
} > release-notes.md

# ── Nuevas funcionalidades (feat:) ────────────────────────────────────────────
FEATS=$(cc feat)
if [ -n "$FEATS" ]; then
    echo "## Nuevas Funcionalidades" >> release-notes.md
    echo "$FEATS" | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Correcciones de bugs (fix:) ───────────────────────────────────────────────
FIXES=$(cc fix)
if [ -n "$FIXES" ]; then
    echo "## Correcciones de Bugs" >> release-notes.md
    echo "$FIXES" | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Mejoras de rendimiento (perf:) ────────────────────────────────────────────
PERFS=$(cc perf)
if [ -n "$PERFS" ]; then
    echo "## Mejoras de Rendimiento" >> release-notes.md
    echo "$PERFS" | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Mantenimiento (chore|refactor|docs|ci|build|style|test:) ─────────────────
MAINT=$(cc '(chore|refactor|docs|ci|build|style|test)')
if [ -n "$MAINT" ]; then
    echo "## Mantenimiento y Refactorizacion" >> release-notes.md
    echo "$MAINT" | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Todos los cambios ─────────────────────────────────────────────────────────
echo "## Todos los Cambios" >> release-notes.md
echo "$LOG" | while IFS='|' read -r hash msg author date; do
    echo "- [${hash}] ${msg} -- ${author} (${date})" >> release-notes.md
done

echo ""
echo "=== RELEASE NOTES GENERADAS ==="
cat release-notes.md
