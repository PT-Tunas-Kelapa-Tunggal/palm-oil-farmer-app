#!/bin/bash
set -euo pipefail

tag="${GITHUB_REF_NAME:-}"
number='(0|[1-9][0-9]*)'
tag_pattern="^(beta|release)-v($number\\.$number\\.$number)-[1-9][0-9]*$"
if [[ "${GITHUB_EVENT_NAME:-}" != "push" || "${GITHUB_REF_TYPE:-}" != "tag" || ! "$tag" =~ $tag_pattern ]]; then
    echo "error: Invalid iOS release ref '$tag'. Use beta-vX.Y.Z-N or release-vX.Y.Z-N (N starts at 1)." >&2
    exit 1
fi

lane="${BASH_REMATCH[1]}"
marketing_version="${BASH_REMATCH[2]}"
case "$lane" in
    beta) source_branch=develop; environment=staging ;;
    release) source_branch=main; environment=production ;;
esac

if ! git merge-base --is-ancestor HEAD "refs/remotes/origin/$source_branch"; then
    echo "error: Tag '$tag' must point to a commit on $source_branch." >&2
    exit 1
fi

{
    echo "environment=$environment"
    echo "marketing_version=$marketing_version"
} >> "${GITHUB_OUTPUT:?Missing GITHUB_OUTPUT}"
