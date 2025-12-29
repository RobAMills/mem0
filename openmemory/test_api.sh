#!/bin/bash

# OpenMemory API Test Script
# Tests all major API endpoints

set -e

API_URL="http://localhost:8765"
USER_ID="rob"

echo "========================================="
echo "OpenMemory API Test Suite"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    
    echo -n "Testing: $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$API_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_URL$endpoint" \
            -H 'Content-Type: application/json' \
            -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        echo "  Response: $body"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "1. Configuration Tests"
echo "----------------------"
test_endpoint "Get Configuration" "GET" "/api/v1/config/"
test_endpoint "Get LLM Config" "GET" "/api/v1/config/mem0/llm"
test_endpoint "Get Embedder Config" "GET" "/api/v1/config/mem0/embedder"
echo ""

echo "2. Memory Tests"
echo "---------------"
test_endpoint "List Memories" "POST" "/api/v1/memories/filter" \
    '{"user_id":"'$USER_ID'","page":1,"size":10}'

test_endpoint "Search Memories" "POST" "/api/v1/memories/filter" \
    '{"user_id":"'$USER_ID'","page":1,"size":10,"search_query":"test"}'

# Create a test memory
echo -n "Creating test memory... "
create_response=$(curl -s -X POST "$API_URL/api/v1/memories/" \
    -H 'Content-Type: application/json' \
    -d '{
        "user_id":"'$USER_ID'",
        "text":"Test memory for API validation",
        "app":"openmemory",
        "infer":false
    }')

if echo "$create_response" | grep -q '"id"'; then
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    MEMORY_ID=$(echo "$create_response" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  Response: $create_response"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    MEMORY_ID=""
fi

if [ -n "$MEMORY_ID" ]; then
    test_endpoint "Get Memory by ID" "GET" "/api/v1/memories/$MEMORY_ID"
fi
echo ""

echo "3. Stats Tests"
echo "--------------"
test_endpoint "Get User Stats" "GET" "/api/v1/stats/?user_id=$USER_ID"
echo ""

echo "4. Apps Tests"
echo "-------------"
test_endpoint "List Apps" "GET" "/api/v1/apps/?user_id=$USER_ID"
echo ""

echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi

