#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-${ROOT_DIR}/dist}"
TOC_FILE="${ROOT_DIR}/TrashPanda.toc"

version="$(awk -F': *' '/^## Version:/ { print $2; exit }' "${TOC_FILE}")"
if [[ -z "${version}" ]]; then
    echo "Unable to read ## Version from TrashPanda.toc" >&2
    exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "${stage}"' EXIT
addon_dir="${stage}/TrashPanda"
mkdir -p "${addon_dir}" "${OUTPUT_DIR}"
OUTPUT_DIR="$(cd "${OUTPUT_DIR}" && pwd)"

files=("TrashPanda.toc" "LICENSE")
while IFS= read -r file; do
    [[ -n "${file}" ]] || continue
    files+=("${file}")
done < <(awk 'NF && $1 !~ /^##/' "${TOC_FILE}")

for relative in "${files[@]}"; do
    source_path="${ROOT_DIR}/${relative}"
    if [[ ! -f "${source_path}" ]]; then
        echo "Missing package input: ${relative}" >&2
        exit 1
    fi

    mkdir -p "${addon_dir}/$(dirname "${relative}")"
    cp "${source_path}" "${addon_dir}/${relative}"
done

archive="${OUTPUT_DIR}/TrashPanda-${version}.zip"
rm -f "${archive}"
(
    cd "${stage}"
    zip -q -r "${archive}" TrashPanda
)

if unzip -Z1 "${archive}" | grep -Eq '(^|/)(AGENT_GUIDE|ARCHITECTURE|CODE_GRAPH|CODE_INDEX|todo)\.md$|(^|/)(tests|scripts|\.github)/'; then
    echo "Package contains development-only files" >&2
    exit 1
fi

printf '%s\n' "${archive}"
