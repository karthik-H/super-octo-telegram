#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_7975479124_20261025151443/api/_infra.sh

# Given
cv_step Given "a registered customer signed in with a valid bearer token" $LINENO
SFX=$(cv_suffix)
EMAIL="creator.$SFX@example.com"
PASSWORD="CreatorPass!$SFX"
cv_register_user "$EMAIL" "$PASSWORD" "Creator $SFX"
cv_login_user "$EMAIL" "$PASSWORD"
TOKEN="$CV_TOKEN"
NAME="New product $SFX"
SKU="SKU-$SFX"

# When
cv_step When "the customer calls POST /products with a valid product body" $LINENO
cv_http POST /products "$(jq -nc --arg n "  $NAME  " --arg s "$SKU" '{name:$n,description:"A fine item",priceCents:4999,sku:$s}')" -H "Authorization: Bearer $TOKEN"
CREATE_STATUS="$CV_HTTP_STATUS"
CREATE_BODY="$CV_HTTP_BODY"

# Then
cv_step Then "201 with the created product, which then appears in the catalog" $LINENO
[ "$CREATE_STATUS" = "201" ] || cv_fail "expected 201 got $CREATE_STATUS" $LINENO
PID=$(printf '%s' "$CREATE_BODY" | jq -r '.product.id // empty')
[ -n "$PID" ] || cv_fail "expected product.id got none" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r .product.name)" = "$NAME" ] || cv_fail "expected trimmed name $NAME got $(printf '%s' "$CREATE_BODY" | jq -r .product.name)" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r .product.description)" = "A fine item" ] || cv_fail "expected description 'A fine item' got $(printf '%s' "$CREATE_BODY" | jq -r .product.description)" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r .product.priceCents)" = "4999" ] || cv_fail "expected priceCents 4999 got $(printf '%s' "$CREATE_BODY" | jq -r .product.priceCents)" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r .product.sku)" = "$SKU" ] || cv_fail "expected sku $SKU got $(printf '%s' "$CREATE_BODY" | jq -r .product.sku)" $LINENO
[ -n "$(printf '%s' "$CREATE_BODY" | jq -r '.product.createdAt // empty')" ] || cv_fail "expected createdAt got none" $LINENO
cv_http GET "/products/$PID"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 fetching created product got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r .product.id)" = "$PID" ] || cv_fail "expected product $PID got $(printf '%s' "$CV_HTTP_BODY" | jq -r .product.id)" $LINENO

# Cleanup
cv_step Cleanup "in-memory store has no delete routes; unique data left in place" $LINENO
echo "nothing to delete for product $PID"

echo "CODEVALID_TEST_ASSERTION_OK:authenticated_customer_creates_product_success"
