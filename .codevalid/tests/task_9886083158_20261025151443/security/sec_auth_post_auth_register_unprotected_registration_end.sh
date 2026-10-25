#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_9886083158_20261025151443/api/_infra.sh

cv_step Given "app reachable" $LINENO
cv_http GET /products
[ "$CV_HTTP_STATUS" = "000" ] && { echo "app unreachable"; exit 1; }

cv_step When "send 25 rapid registrations with unique emails from one client" $LINENO
SFX=$(cv_suffix)
CREATED=0; LIMITED=0; OTHER=0
for i in $(seq 1 25); do
  cv_http POST /auth/register "$(cv_register_body "bot$i.$SFX@example.com" "BotPass!$i$SFX" "Bot $i")"
  case "$CV_HTTP_STATUS" in
    201) CREATED=$((CREATED + 1)) ;;
    429|403) LIMITED=$((LIMITED + 1)) ;;
    *) OTHER=$((OTHER + 1)) ;;
  esac
done
CHALLENGE=$(grep -ci 'retry-after\|ratelimit\|captcha' "$CV_HTTP_HEADERS_FILE" || true)

cv_step Then "decide verdict" $LINENO
TITLE="Unprotected registration endpoint enables automated account creation"
if [ "$CREATED" -eq 25 ] && [ "$LIMITED" -eq 0 ]; then
  printf 'CV_SECURITY|vulnerable|auth|serious|%s|%s\n' "$TITLE" "25 of 25 rapid POST /auth/register from one client returned 201 with no 429 or rate-limit headers"
else
  printf 'CV_SECURITY|secure|auth|serious|%s|%s\n' "$TITLE" "created=$CREATED limited=$LIMITED other=$OTHER ratelimit_headers=$CHALLENGE over 25 rapid registrations"
fi
# No delete route in the in-memory store; unique emails left in place.
exit 0
