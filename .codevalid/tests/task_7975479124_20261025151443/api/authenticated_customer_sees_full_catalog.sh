#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_7975479124_20261025151443/api/_infra.sh

# Given
cv_step Given "a logged-in customer who has made a catalog change" $LINENO
SFX=$(cv_suffix)
EMAIL="catalog.$SFX@example.com"
PASSWORD="CatalogPass!$SFX"
cv_register_user "$EMAIL" "$PASSWORD" "Catalog Customer $SFX"
cv_login_user "$EMAIL" "$PASSWORD"
TOKEN="$CV_TOKEN"
NAME="Catalog change $SFX"
cv_prereq "create product via authenticated POST /products" $LINENO
cv_http POST /products "$(jq -nc --arg n "$NAME" --arg s "SKU-$SFX" '{name:$n,description:"added after sign-in",priceCents:2599,sku:$s}')" -H "Authorization: Bearer $TOKEN"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 creating product got $CV_HTTP_STATUS" $LINENO
PRODUCT_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.product.id // empty')
[ -n "$PRODUCT_ID" ] || cv_fail "expected product.id got none" $LINENO

# When
cv_step When "the logged-in customer calls GET /products" $LINENO
cv_http GET /products -H "Authorization: Bearer $TOKEN"

# Then
cv_step Then "200 with a products array that includes the post-login catalog change" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
IS_ARR=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.products | type')
[ "$IS_ARR" = "array" ] || cv_fail "expected products array got $IS_ARR" $LINENO
MATCH=$(printf '%s' "$CV_HTTP_BODY" | jq -c --arg id "$PRODUCT_ID" '[.products[] | select(.id==$id)] | first // empty')
[ -n "$MATCH" ] || cv_fail "expected product $PRODUCT_ID in catalog got none" $LINENO
[ "$(printf '%s' "$MATCH" | jq -r .name)" = "$NAME" ] || cv_fail "expected name $NAME got $(printf '%s' "$MATCH" | jq -r .name)" $LINENO
[ "$(printf '%s' "$MATCH" | jq -r .priceCents)" = "2599" ] || cv_fail "expected priceCents 2599 got $(printf '%s' "$MATCH" | jq -r .priceCents)" $LINENO
[ "$(printf '%s' "$MATCH" | jq -r .sku)" = "SKU-$SFX" ] || cv_fail "expected sku SKU-$SFX got $(printf '%s' "$MATCH" | jq -r .sku)" $LINENO

# Cleanup
cv_step Cleanup "in-memory store has no delete routes; unique data left in place" $LINENO
echo "nothing to delete for product $PRODUCT_ID"

echo "CODEVALID_TEST_ASSERTION_OK:authenticated_customer_sees_full_catalog"
