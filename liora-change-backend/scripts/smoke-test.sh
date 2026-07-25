#!/usr/bin/env bash
#
# scripts/smoke-test.sh
#
# Runs the same 14-step hackathon demo story as tests/Feature/DemoLoopTest.php,
# but against a REAL running server via curl (not PHPUnit/SQLite), to catch
# environment-specific issues the test suite can't see: seeding, .env
# misconfig, migrations not run, MySQL-only behavior, etc.
# (docs/mvp/issues/09-testing-qa.md Part 4)
#
# Usage:
#   php artisan serve &          # or point BASE_URL at a shared staging URL
#   php artisan migrate:fresh --seed
#   ./scripts/smoke-test.sh
#   BASE_URL=https://staging.example.com/api/v1 ./scripts/smoke-test.sh
#
# Exits 0 if every step passes, non-zero otherwise.

set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000/api/v1}"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "$RESPONSE_FILE"' EXIT

PASS_COUNT=0
FAIL_COUNT=0

if ! command -v jq >/dev/null 2>&1; then
    echo "This script requires 'jq' to parse JSON responses (e.g. 'apt install jq' or 'brew install jq')." >&2
    exit 1
fi

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    echo "       response: $(cat "$RESPONSE_FILE")"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# request METHOD PATH [JSON_BODY] [BEARER_TOKEN] -> prints HTTP status code,
# writes the response body to $RESPONSE_FILE.
request() {
    local method="$1" path="$2" body="${3:-}" token="${4:-}"
    local -a headers=(-H 'Accept: application/json')

    if [ -n "$token" ]; then
        headers+=(-H "Authorization: Bearer $token")
    fi

    if [ -n "$body" ]; then
        headers+=(-H 'Content-Type: application/json')
        curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X "$method" "${BASE_URL}${path}" "${headers[@]}" -d "$body"
    else
        curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X "$method" "${BASE_URL}${path}" "${headers[@]}"
    fi
}

# date_plus_days N -> YYYY-MM-DD, N days from today (UTC). Supports both
# GNU date (Linux) and BSD date (macOS) syntax.
date_plus_days() {
    local days="$1"
    date -u -d "+${days} day" +%Y-%m-%d 2>/dev/null || date -u -v"+${days}"d +%Y-%m-%d
}

json() {
    jq -r "$1" "$RESPONSE_FILE"
}

echo "Running smoke test against ${BASE_URL}"
echo "----------------------------------------"

# 1. POST /auth/register -> 201, get token
EMAIL="smoke-$(date +%s)@example.com"
STATUS=$(request POST /auth/register "{\"name\":\"Smoke Test\",\"email\":\"${EMAIL}\",\"password\":\"password\",\"password_confirmation\":\"password\",\"timezone\":\"UTC\"}")
if [ "$STATUS" = "201" ]; then
    TOKEN=$(json '.data.token')
    pass "step 1: register"
else
    fail "step 1: register (expected 201, got ${STATUS})"
    exit 1
fi

# 2. GET /me -> 200, xp_total=0
STATUS=$(request GET /me '' "$TOKEN")
if [ "$STATUS" = "200" ] && [ "$(json '.data.xp_total')" = "0" ]; then
    pass "step 2: get me (xp_total=0)"
else
    fail "step 2: get me (expected 200 + xp_total=0, got ${STATUS})"
fi

# 3. POST /challenges -> 201, status=draft
STATUS=$(request POST /challenges '{"title":"Morning Walk","duration_days":7}' "$TOKEN")
if [ "$STATUS" = "201" ] && [ "$(json '.data.status')" = "draft" ]; then
    CHALLENGE_ID=$(json '.data.id')
    pass "step 3: create challenge (status=draft, id=${CHALLENGE_ID})"
else
    fail "step 3: create challenge (expected 201 + status=draft, got ${STATUS})"
    exit 1
fi

# 4. POST /challenges/{id}/activate -> 200, status=active
STATUS=$(request POST "/challenges/${CHALLENGE_ID}/activate" '' "$TOKEN")
if [ "$STATUS" = "200" ] && [ "$(json '.data.status')" = "active" ]; then
    pass "step 4: activate challenge (status=active)"
else
    fail "step 4: activate challenge (expected 200 + status=active, got ${STATUS})"
fi

# 5. POST check-ins {status: completed} -> 201, streak=1, xp_earned=10
STATUS=$(request POST "/challenges/${CHALLENGE_ID}/check-ins" '{"status":"completed"}' "$TOKEN")
STREAK=$(json '.data.summary.current_streak')
XP_EARNED=$(json '.data.summary.xp_earned')
if [ "$STATUS" = "201" ] && [ "$STREAK" = "1" ] && [ "$XP_EARNED" = "10" ]; then
    pass "step 5: completed check-in (streak=1, xp_earned=10)"
else
    fail "step 5: completed check-in (expected 201 + streak=1 + xp_earned=10, got ${STATUS}/streak=${STREAK}/xp=${XP_EARNED})"
fi

# 6. GET /dashboard -> 200, active_challenges[0].checked_in_today=true
STATUS=$(request GET /dashboard '' "$TOKEN")
CHECKED_IN_TODAY=$(json '.data.active_challenges[0].checked_in_today')
if [ "$STATUS" = "200" ] && [ "$CHECKED_IN_TODAY" = "true" ]; then
    pass "step 6: dashboard shows checked_in_today=true"
else
    fail "step 6: dashboard (expected 200 + checked_in_today=true, got ${STATUS}/${CHECKED_IN_TODAY})"
fi

# 7. POST check-ins {status: skipped, check_in_date: tomorrow} -> 201, streak reset
TOMORROW=$(date_plus_days 1)
STATUS=$(request POST "/challenges/${CHALLENGE_ID}/check-ins" "{\"status\":\"skipped\",\"check_in_date\":\"${TOMORROW}\"}" "$TOKEN")
STREAK=$(json '.data.summary.current_streak')
if [ "$STATUS" = "201" ] && [ "$STREAK" = "0" ]; then
    pass "step 7: skipped check-in resets streak to 0"
else
    fail "step 7: skipped check-in (expected 201 + streak=0, got ${STATUS}/streak=${STREAK})"
fi

# 8. GET /recovery/current -> 200, active=true
STATUS=$(request GET /recovery/current '' "$TOKEN")
ACTIVE=$(json '.data.active')
if [ "$STATUS" = "200" ] && [ "$ACTIVE" = "true" ]; then
    pass "step 8: recovery active=true after skip"
else
    fail "step 8: recovery (expected 200 + active=true, got ${STATUS}/${ACTIVE})"
fi

# 9. POST check-ins {status: completed, check_in_date: day after} -> 201
DAY_AFTER=$(date_plus_days 2)
STATUS=$(request POST "/challenges/${CHALLENGE_ID}/check-ins" "{\"status\":\"completed\",\"check_in_date\":\"${DAY_AFTER}\"}" "$TOKEN")
if [ "$STATUS" = "201" ]; then
    pass "step 9: comeback check-in completed"
else
    fail "step 9: comeback check-in (expected 201, got ${STATUS})"
fi

# 10. GET /recovery/current -> 200, active=false
STATUS=$(request GET /recovery/current '' "$TOKEN")
ACTIVE=$(json '.data.active')
if [ "$STATUS" = "200" ] && [ "$ACTIVE" = "false" ]; then
    pass "step 10: recovery active=false after comeback"
else
    fail "step 10: recovery (expected 200 + active=false, got ${STATUS}/${ACTIVE})"
fi

# 11. POST /ai/motivation {challenge_id} -> 200, message mentions challenge, source in [openai, template]
STATUS=$(request POST /ai/motivation "{\"challenge_id\":${CHALLENGE_ID}}" "$TOKEN")
SOURCE=$(json '.data.source')
MESSAGE=$(json '.data.message')
if [ "$STATUS" = "200" ] && { [ "$SOURCE" = "openai" ] || [ "$SOURCE" = "template" ]; } && echo "$MESSAGE" | grep -q "Morning Walk"; then
    pass "step 11: motivation message mentions challenge (source=${SOURCE})"
else
    fail "step 11: motivation (expected 200 + message mentioning challenge, got ${STATUS}/source=${SOURCE})"
fi

# 12. POST /ai/chat {message} -> 200, session_id present, message.role=assistant
STATUS=$(request POST /ai/chat '{"message":"What if I miss a day?"}' "$TOKEN")
SESSION_ID=$(json '.data.session_id')
ROLE=$(json '.data.message.role')
if [ "$STATUS" = "200" ] && [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ] && [ "$ROLE" = "assistant" ]; then
    pass "step 12: ai chat replies (session_id=${SESSION_ID})"
else
    fail "step 12: ai chat (expected 200 + session_id + role=assistant, got ${STATUS}/session=${SESSION_ID}/role=${ROLE})"
fi

# 13. POST /auth/logout -> 200
STATUS=$(request POST /auth/logout '' "$TOKEN")
if [ "$STATUS" = "200" ]; then
    pass "step 13: logout"
else
    fail "step 13: logout (expected 200, got ${STATUS})"
fi

# 14. GET /me (same token) -> 401
STATUS=$(request GET /me '' "$TOKEN")
if [ "$STATUS" = "401" ]; then
    pass "step 14: token revoked after logout (401)"
else
    fail "step 14: token reuse after logout (expected 401, got ${STATUS})"
fi

echo "----------------------------------------"
echo "Passed: ${PASS_COUNT}  Failed: ${FAIL_COUNT}"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi

exit 0
