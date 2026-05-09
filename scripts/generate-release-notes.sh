#!/bin/bash
# Generates release-notes.md from git log using Conventional Commits.
# Jenkins exports all environment{} variables to the shell automatically,
# so SERVICE_NAME, IMAGE_TAG and DEV_COMMIT are available without passing them.

SERVICE="${SERVICE_NAME}"
VERSION="v${IMAGE_TAG}"
BUILD="${IMAGE_TAG}"
COMMIT="${DEV_COMMIT:-unknown}"
DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')

# Collect commits from the DEV repo checked out in app/
cd app
PREV_TAG=$(git tag -l "v*" 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$PREV_TAG" ]; then
    LOG=$(git log --pretty=format:"%h|%s|%an|%ad" --date=short --no-merges | head -30)
else
    LOG=$(git log "${PREV_TAG}..HEAD" --pretty=format:"%h|%s|%an|%ad" --date=short --no-merges)
fi
cd ..

# ── Header ────────────────────────────────────────────────────────────────────
{
    echo "# Release Notes: ${SERVICE} ${VERSION}"
    echo ""
    echo "| Campo         | Valor                           |"
    echo "|---------------|---------------------------------|"
    echo "| Servicio      | ${SERVICE}                      |"
    echo "| Version       | ${VERSION}                      |"
    echo "| Build Jenkins | ${BUILD}                        |"
    echo "| Commit DEV    | ${COMMIT}                       |"
    echo "| Fecha         | ${DATE}                         |"
    echo "| Ambiente      | PRODUCCION                      |"
    echo ""
} > release-notes.md

# ── Nuevas funcionalidades (feat:) ────────────────────────────────────────────
FEATS=$(echo "$LOG" | grep '|feat:' || true)
if [ -n "$FEATS" ]; then
    echo "## Nuevas Funcionalidades" >> release-notes.md
    echo "$LOG" | grep '|feat:' | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Correcciones de bugs (fix:) ───────────────────────────────────────────────
FIXES=$(echo "$LOG" | grep '|fix:' || true)
if [ -n "$FIXES" ]; then
    echo "## Correcciones de Bugs" >> release-notes.md
    echo "$LOG" | grep '|fix:' | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Mejoras de rendimiento (perf:) ────────────────────────────────────────────
PERFS=$(echo "$LOG" | grep '|perf:' || true)
if [ -n "$PERFS" ]; then
    echo "## Mejoras de Rendimiento" >> release-notes.md
    echo "$LOG" | grep '|perf:' | while IFS='|' read -r hash msg author date; do
        echo "- ${msg} (${hash} - ${author}, ${date})" >> release-notes.md
    done
    echo "" >> release-notes.md
fi

# ── Mantenimiento (chore|refactor|docs|ci|build|style|test:) ─────────────────
MAINT=$(echo "$LOG" | grep -E '\|(chore|refactor|docs|ci|build|style|test):' || true)
if [ -n "$MAINT" ]; then
    echo "## Mantenimiento y Refactorizacion" >> release-notes.md
    echo "$LOG" | grep -E '\|(chore|refactor|docs|ci|build|style|test):' | while IFS='|' read -r hash msg author date; do
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
