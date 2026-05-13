#!/usr/bin/env sh
set -eu

tmp_base="${TMPDIR:-/tmp}/lua-ui-setup-gates.$$"
luacheck_log="$tmp_base.luacheck"
doc_log="$tmp_base.docs"
expected_luacheck="Total: 125 warnings / 0 errors"

cleanup() {
  rm -f "$tmp_base".*
}

trap cleanup EXIT HUP INT TERM

run() {
  echo
  echo "==> $*"
  "$@"
}

check_no_doc_match() {
  pattern="$1"
  description="$2"

  echo
  echo "==> rg $pattern"
  if rg -n "$pattern" . \
    --glob '!node_modules/**' \
    --glob '!lua_modules/**' \
    --glob '!external/**' \
    --glob '!tmp/**' >"$doc_log"; then
    echo "error: $description" >&2
    cat "$doc_log" >&2
    exit 1
  else
    status=$?
    if [ "$status" -gt 1 ]; then
      cat "$doc_log" >&2
      exit "$status"
    fi
  fi
}

run npm run list:ts
run npm run build:ts
run npm run check:boundaries

run ./lua -e 'require("spec.rule_spec").run()'
run ./lua -e 'require("spec.schema_spec").run()'
run ./lua -e 'require("lib.ui.core.container")'

check_no_doc_match \
  'typescript_refactor[.]md' \
  'references to the removed root migration document remain'

check_no_doc_match \
  'build[/]tstl|(^|[^/])types[/]lua-interop|src[/]lib[/]ui' \
  'stale root build/type/runtime paths remain'

echo
echo "==> ./lua_modules/bin/luacheck ."
if ./lua_modules/bin/luacheck . >"$luacheck_log" 2>&1; then
  echo "luacheck passed without warnings"
else
  summary="$(grep '^Total:' "$luacheck_log" || true)"
  case "$summary" in
    *"$expected_luacheck"*)
      echo "luacheck matched known baseline: $summary"
      ;;
    *)
      cat "$luacheck_log" >&2
      echo "error: luacheck differs from known baseline: $expected_luacheck" >&2
      exit 1
      ;;
  esac
fi

echo
echo "setup validation gates ok"
