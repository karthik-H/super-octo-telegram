#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_7904079587_20261025151443/api/_infra.sh

# Given
cv_step Given "a seller has published two uniquely named products to the catalog" $LINENO
SFX=$(cv_suffix)
cv_register_and_login $LINENO
cv_create_product "Browse Lamp ${SFX}" "Desk lamp for browse test ${SFX}" 2599 "BRW-A-${SFX}" $LINENO
P1_ID=$CV_PRODUCT_ID
P1_JSON=$CV_PRODUCT_JSON
cv_create_product "Browse Mug ${SFX}" "Coffee mug for browse test ${SFX}" 1250 "BRW-B-${SFX}" $LINENO
P2_ID=$CV_PRODUCT_ID
P2_JSON=$CV_PRODUCT_JSON

# When
cv_step When "an anonymous visitor requests GET /products with no auth headers" $LINENO
cv_http GET /products

# Then
cv_step Then "the full catalog is returned with 200 and includes every published product" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected HTTP 200 got $CV_HTTP_STATUS" $LINENO
TYPE=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.products | type' 2>/dev/null || echo invalid)
[ "$TYPE" = "array" ] || cv_fail "expected .products to be an array got $TYPE" $LINENO
COUNT=$(printf '%s' "$CV_HTTP_BODY" | jq '.products | length')
[ "$COUNT" -ge 2 ] || cv_fail "expected at least 2 products in catalog got $COUNT" $LINENO
for pair in "$P1_ID|$P1_JSON" "$P2_ID|$P2_JSON"; do
  PID=${pair%%|*}
  EXPECTED=${pair#*|}
  ACTUAL=$(printf '%s' "$CV_HTTP_BODY" | jq -c --arg id "$PID" '.products[] | select(.id == $id)')
  [ -n "$ACTUAL" ] || cv_fail "expected product $PID in catalog got not listed" $LINENO
  SAME=$(jq -n --argjson a "$ACTUAL" --argjson e "$EXPECTED" '$a == $e')
  [ "$SAME" = "true" ] || cv_fail "expected listed product $EXPECTED got $ACTUAL" $LINENO
done
for f in id name description priceCents sku createdAt; do
  MISSING=$(printf '%s' "$CV_HTTP_BODY" | jq --arg f "$f" '[.products[] | select(has($f) | not)] | length')
  [ "$MISSING" = "0" ] || cv_fail "expected every product to have field $f got $MISSING without it" $LINENO
done

# Cleanup
cv_step Cleanup "nothing to remove: the app has no delete endpoint and keeps data in memory" $LINENO
echo "created products $P1_ID $P2_ID and user ${CV_USER_ID:-} remain in the in-memory store (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:browse_full_catalog_without_sign_in"
