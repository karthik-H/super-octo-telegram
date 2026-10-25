#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_7975479124_20261025151443/api/_infra.sh

# Given
cv_step Given "a registered customer with a known email and password" $LINENO
SFX=$(cv_suffix)
EMAIL="login.$SFX@example.com"
PASSWORD="Secr3tPass!$SFX"
cv_register_user "$EMAIL" "$PASSWORD" "Login Customer $SFX"
USER_ID="$CV_USER_ID"

# When
cv_step When "the customer logs in via POST /auth/login and uses the token for a catalog change" $LINENO
cv_http POST /auth/login "$(jq -nc --arg e "$EMAIL" --arg p "$PASSWORD" '{email:$e,password:$p}')"
LOGIN_STATUS="$CV_HTTP_STATUS"
LOGIN_BODY="$CV_HTTP_BODY"
TOKEN=$(printf '%s' "$LOGIN_BODY" | jq -r '.token // empty')
if [ -n "$TOKEN" ]; then
  cv_http POST /products "$(jq -nc --arg n "Login product $SFX" '{name:$n,priceCents:1500}')" -H "Authorization: Bearer $TOKEN"
  CREATE_STATUS="$CV_HTTP_STATUS"
else
  CREATE_STATUS="none"
fi

# Then
cv_step Then "login returns 200 with a token and the customer's public profile; the token authorizes catalog changes" $LINENO
[ "$LOGIN_STATUS" = "200" ] || cv_fail "expected 200 from login got $LOGIN_STATUS" $LINENO
[ -n "$TOKEN" ] || cv_fail "expected non-empty token got none" $LINENO
[ "$(printf '%s' "$TOKEN" | awk -F. '{print NF}')" = "3" ] || cv_fail "expected JWT with 3 segments got $TOKEN" $LINENO
GOT_ID=$(printf '%s' "$LOGIN_BODY" | jq -r '.user.id // empty')
GOT_EMAIL=$(printf '%s' "$LOGIN_BODY" | jq -r '.user.email // empty')
[ "$GOT_ID" = "$USER_ID" ] || cv_fail "expected user.id $USER_ID got $GOT_ID" $LINENO
[ "$GOT_EMAIL" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL got $GOT_EMAIL" $LINENO
HAS_HASH=$(printf '%s' "$LOGIN_BODY" | jq -r '.user | has("passwordHash")')
[ "$HAS_HASH" = "false" ] || cv_fail "expected no passwordHash in user got it present" $LINENO
[ "$CREATE_STATUS" = "201" ] || cv_fail "expected 201 creating product with login token got $CREATE_STATUS" $LINENO

# Cleanup
cv_step Cleanup "in-memory store has no delete routes; unique data left in place" $LINENO
echo "nothing to delete for $EMAIL"

echo "CODEVALID_TEST_ASSERTION_OK:login_success_registered_customer"
