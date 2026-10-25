#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_9886083158_20261025151443/api/_infra.sh

# Given
cv_step Given "a unique email not yet registered and a valid password" $LINENO
SFX=$(cv_suffix)
EMAIL="reg.$SFX@example.com"
PASSWORD="ValidPass!$SFX"
NAME="Reg Customer $SFX"
cv_prereq "confirm the email is not registered (login is rejected)" $LINENO
cv_http POST /auth/login "$(jq -nc --arg e "$EMAIL" --arg p "$PASSWORD" '{email:$e,password:$p}')"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 for unregistered email got $CV_HTTP_STATUS" $LINENO

# When
cv_step When "POST /auth/register with the new email, password and name" $LINENO
cv_http POST /auth/register "$(cv_register_body "$EMAIL" "$PASSWORD" "$NAME")"
REG_STATUS="$CV_HTTP_STATUS"
REG_BODY="$CV_HTTP_BODY"

# Then
cv_step Then "201 with the new public user; the account is stored and can log in" $LINENO
[ "$REG_STATUS" = "201" ] || cv_fail "expected 201 got $REG_STATUS" $LINENO
USER_ID=$(printf '%s' "$REG_BODY" | jq -r '.user.id // empty')
GOT_EMAIL=$(printf '%s' "$REG_BODY" | jq -r '.user.email // empty')
GOT_NAME=$(printf '%s' "$REG_BODY" | jq -r '.user.name // empty')
[ -n "$USER_ID" ] || cv_fail "expected non-empty user.id got none" $LINENO
[ "$GOT_EMAIL" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL got $GOT_EMAIL" $LINENO
[ "$GOT_NAME" = "$NAME" ] || cv_fail "expected user.name $NAME got $GOT_NAME" $LINENO
HAS_HASH=$(printf '%s' "$REG_BODY" | jq -r '.user | (has("passwordHash") or has("password"))')
[ "$HAS_HASH" = "false" ] || cv_fail "expected no password fields in user got them present" $LINENO
cv_http POST /auth/login "$(jq -nc --arg e "$EMAIL" --arg p "$PASSWORD" '{email:$e,password:$p}')"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 login for stored account got $CV_HTTP_STATUS" $LINENO
LOGIN_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ "$LOGIN_ID" = "$USER_ID" ] || cv_fail "expected login user.id $USER_ID got $LOGIN_ID" $LINENO
cv_http POST /auth/register "$(cv_register_body "$EMAIL" "$PASSWORD" "$NAME")"
[ "$CV_HTTP_STATUS" = "409" ] || cv_fail "expected 409 re-registering stored email got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "in-memory store has no delete route; unique data left in place" $LINENO
echo "nothing to delete for $EMAIL"

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_new_email"
