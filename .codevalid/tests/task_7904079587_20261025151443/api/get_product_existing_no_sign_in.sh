#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_7904079587_20261025151443/api/_infra.sh

# Given
cv_step Given "a seller has published a product with known details" $LINENO
SFX=$(cv_suffix)
NAME="Detail Kettle ${SFX}"
DESC="Stainless kettle for detail test ${SFX}"
PRICE=4999
SKU="DTL-${SFX}"
cv_register_and_login $LINENO
cv_create_product "$NAME" "$DESC" "$PRICE" "$SKU" $LINENO
PID=$CV_PRODUCT_ID
CREATED_AT=$(printf '%s' "$CV_PRODUCT_JSON" | jq -r '.createdAt')

# When
cv_step When "an anonymous visitor requests GET /products/{id} with no auth headers" $LINENO
cv_http GET "/products/${PID}"

# Then
cv_step Then "200 with the full product details matching what was published" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected HTTP 200 got $CV_HTTP_STATUS" $LINENO
P=$(printf '%s' "$CV_HTTP_BODY" | jq -c '.product // empty' 2>/dev/null || true)
[ -n "$P" ] || cv_fail "expected .product object in body got $CV_HTTP_BODY" $LINENO
check() {
  _got=$(printf '%s' "$P" | jq -r "$1")
  [ "$_got" = "$2" ] || cv_fail "expected $1 = $2 got $_got" "$3"
}
check '.id' "$PID" $LINENO
check '.name' "$NAME" $LINENO
check '.description' "$DESC" $LINENO
check '.priceCents' "$PRICE" $LINENO
check '.sku' "$SKU" $LINENO
check '.createdAt' "$CREATED_AT" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: the app has no delete endpoint and keeps data in memory" $LINENO
echo "created product $PID and user ${CV_USER_ID:-} remain in the in-memory store (no delete API)"

echo "CODEVALID_TEST_ASSERTION_OK:get_product_existing_no_sign_in"
