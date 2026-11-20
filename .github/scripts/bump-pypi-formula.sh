#!/usr/bin/env bash
# Point a Python formula at a PyPI release and refresh its resources.
#
# Usage: bump-pypi-formula.sh <tap> <formula> [version]
#
# The formula's PyPI project must share its name. Without a version, the
# latest PyPI release is used. Prints "changed=true|false" on the last line
# (appended to $GITHUB_OUTPUT when set).
set -euo pipefail

tap=$1
formula=$2
version=${3:-}

file="$(brew --repository "$tap")/Formula/$formula.rb"
[[ -f $file ]] || { echo "No formula at $file" >&2; exit 1; }

api="https://pypi.org/pypi/$formula${version:+/$version}/json"
read -r version url sha256 < <(
  curl -fsSL "$api" | jq -r '
    .info.version as $v
    | (.urls[] | select(.packagetype == "sdist")) as $s
    | "\($v) \($s.url) \($s.digests.sha256)"'
)
[[ -n $url ]] || { echo "No sdist for $formula $version on PyPI" >&2; exit 1; }

changed=false
if grep -qF "  url \"$url\"" "$file"; then
  echo "$formula is already at $version"
else
  echo "Bumping $formula to $version"
  # Top-level url/sha256 are indented two spaces; resource ones are deeper.
  URL=$url SHA=$sha256 perl -pi -e '
    s/^  url ".*"$/  url "$ENV{URL}"/;
    s/^  sha256 ".*"$/  sha256 "$ENV{SHA}"/;
  ' "$file"
  # Brew ignores PyPI uploads younger than a day. Waive that for the package
  # just released; its dependencies still have to clear the cooldown.
  brew update-python-resources --ignore-main-package-cooldown "$tap/$formula"
  changed=true
fi

echo "version=$version"
echo "changed=$changed"
if [[ -n ${GITHUB_OUTPUT:-} ]]; then
  { echo "version=$version"; echo "changed=$changed"; } >>"$GITHUB_OUTPUT"
fi
