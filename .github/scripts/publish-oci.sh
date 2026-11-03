#!/usr/bin/env bash
# Publish the charts in this repository to an OCI registry.
#
#   publish-oci.sh detect          print a JSON array of the chart directories whose
#                                  Chart.yaml version is not in the registry yet
#   publish-oci.sh publish <dir>   build, lint, package and push one chart
#
# Each directory with a Chart.yaml (including forked/) is one chart. Asking the
# registry, not git, which versions are missing means a failed or missed run is
# retried by the next one and a published version is never replaced. publish
# checks again, so pushing the same version twice is a no-op.
#
# Environment:
#   OCI_REPO     target, e.g. oci://registry.wdr.io/charts (required)
#   DRY_RUN      "true": publish builds, lints and packages but does not push
#   PLAIN_HTTP   "true" talks HTTP to the registry (local test registries only)
#   REGISTRY_USERNAME / REGISTRY_PASSWORD
#                optional; used to read tags of a private project. Pushes use
#                the credentials stored by `helm registry login`.
#
# Needs bash, curl, jq, yq v4 (mikefarah) and helm >= 3.8. Run from the repo root.
set -euo pipefail

OCI_REPO="${OCI_REPO:?set OCI_REPO, e.g. oci://registry.wdr.io/charts}"
DRY_RUN="${DRY_RUN:-false}"
PLAIN_HTTP="${PLAIN_HTTP:-false}"

target="${OCI_REPO#oci://}"
host="${target%%/*}"
path="${target#*/}"
scheme=https
push_args=()
if [ "${PLAIN_HTTP}" = "true" ]; then
  scheme=http
  push_args+=(--plain-http)
fi
accept="application/vnd.oci.image.manifest.v1+json"
# A network blip should not fail a whole run.
retry=(--retry 3 --retry-connrefused)

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

# Quote a value for a curl config file, where " and \ are special.
curl_config_quote() {
  local value="${1//\\/\\\\}"
  printf '"%s"' "${value//\"/\\\"}"
}

# Print the HTTP status of the manifest <path>/<chart>:<version>: 200 exists,
# 404 missing. Registries such as Harbor answer 401 with a Bearer challenge
# first; fetch a pull token (anonymous unless credentials are set) and retry.
manifest_status() {
  local repo="$1" tag="$2" url auth realm service token
  url="${scheme}://${host}/v2/${repo}/manifests/${tag}"
  auth="$(curl -sI "${retry[@]}" -H "Accept: ${accept}" "${url}" | tr -d '\r')"
  case "$(head -n1 <<<"${auth}" | awk '{print $2}')" in
    401) ;;
    "") echo 000; return ;;
    *) head -n1 <<<"${auth}" | awk '{print $2}'; return ;;
  esac
  realm="$(sed -n 's/^www-authenticate: bearer .*realm="\([^"]*\)".*/\1/Ip' <<<"${auth}")"
  service="$(sed -n 's/^www-authenticate: bearer .*service="\([^"]*\)".*/\1/Ip' <<<"${auth}")"
  # The registry names the token realm; send credentials only to its own host.
  case "${realm}" in
    "${scheme}://${host}/"*) ;;
    *) echo "token realm ${realm:-missing} is not on ${host}" >&2; echo 000; return ;;
  esac
  if [ -n "${REGISTRY_USERNAME:-}" ]; then
    # Credentials go through a curl config on stdin, not the command line.
    token="$(printf 'user = %s\n' "$(curl_config_quote "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD:-}")" |
      curl -sf "${retry[@]}" -K - -G "${realm}" --data-urlencode "service=${service}" \
        --data-urlencode "scope=repository:${repo}:pull" | jq -r '.token // .access_token')"
  else
    token="$(curl -sf "${retry[@]}" -G "${realm}" --data-urlencode "service=${service}" \
      --data-urlencode "scope=repository:${repo}:pull" | jq -r '.token // .access_token')"
  fi
  curl -s "${retry[@]}" -o /dev/null -w '%{http_code}' -I -H "Accept: ${accept}" \
    -H "Authorization: Bearer ${token}" "${url}"
}

# Print the registry status of a chart directory's version (see manifest_status).
chart_status() {
  local name version
  name="$(yq -r '.name' "$1/Chart.yaml")"
  version="$(yq -r '.version' "$1/Chart.yaml")"
  # OCI tags cannot contain "+"; Helm pushes such versions with "_" instead.
  manifest_status "${path}/${name}" "${version//+/_}"
}

detect() {
  local chart status missing=()
  for chart in $(find . -name Chart.yaml -not -path './.git/*' -not -path '*/charts/*' -printf '%h\n' | sort); do
    chart="${chart#./}"
    status="$(chart_status "${chart}")"
    case "${status}" in
      200) echo "${chart}: already in ${OCI_REPO}" >&2 ;;
      404) echo "${chart}: missing" >&2; missing+=("${chart}") ;;
      *) echo "::error::${chart}: registry check returned HTTP ${status}" >&2; return 1 ;;
    esac
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    echo '[]'
  else
    printf '%s\n' "${missing[@]}" | jq -R . | jq -cs .
  fi
}

publish() {
  local chart="${1:?usage: publish-oci.sh publish <chart dir>}" name version status repo n=0
  name="$(yq -r '.name' "${chart}/Chart.yaml")"
  version="$(yq -r '.version' "${chart}/Chart.yaml")"
  status="$(chart_status "${chart}")"
  case "${status}" in
    200) echo "${name} ${version} is already in ${OCI_REPO}; nothing to do"; return 0 ;;
    404) ;;
    *) echo "::error::${name} ${version}: registry check returned HTTP ${status}"; return 1 ;;
  esac

  # helm dependency build needs the chart's HTTP dependency repositories added.
  for repo in $(yq -r '.dependencies[]?.repository // ""' "${chart}/Chart.yaml" | grep -E '^https?://' |
    sed 's:/*$::' | sort -u); do
    n=$((n + 1))
    # Named after the URL, so a rerun in the same Helm config reuses the entry.
    helm repo add --force-update "dep-$(sha1sum <<<"${repo}" | cut -c1-12)" "${repo}" >/dev/null
  done
  if [ "${n}" -gt 0 ]; then
    helm repo update >/dev/null
  fi

  helm dependency build "${chart}"
  helm lint "${chart}"
  helm package "${chart}" --destination "${work}"
  if [ "${DRY_RUN}" = "true" ]; then
    echo "would push ${name} ${version} to ${OCI_REPO}"
  else
    helm push "${work}/${name}-${version}.tgz" "${OCI_REPO}" "${push_args[@]}"
  fi
}

case "${1:-}" in
  detect) detect ;;
  publish) publish "${2:-}" ;;
  *) echo "usage: publish-oci.sh detect | publish <chart dir>" >&2; exit 2 ;;
esac
