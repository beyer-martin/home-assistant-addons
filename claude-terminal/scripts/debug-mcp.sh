#!/usr/bin/with-contenv bashio

# Debug script for MCP endpoint testing
# Usage: /opt/scripts/debug-mcp.sh [url] [token]

echo "=== MCP Endpoint Debug Tool ==="
echo ""

# Get parameters from command line or config
URL="${1:-}"
TOKEN="${2:-}"

if [ -z "$URL" ]; then
    # Try to get from config
    URL=$(bashio::config 'mcp_server_url' 'http://homeassistant.local:8123/mcp_server/sse')
fi

if [ -z "$TOKEN" ]; then
    TOKEN=$(bashio::config 'mcp_access_token' '')
fi

echo "Testing URL: $URL"
if [ -n "$TOKEN" ]; then
    echo "Token: ${TOKEN:0:10}... (configured)"
else
    echo "Token: NOT CONFIGURED"
fi
echo ""

# Test 1: Basic connectivity (no auth)
echo "--- Test 1: Basic connectivity (no auth) ---"
response1=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" --max-time 10 "$URL" 2>&1)
echo "$response1"
echo ""

# Test 2: With authentication (if token provided)
if [ -n "$TOKEN" ]; then
    echo "--- Test 2: With authentication ---"
    response2=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Accept: text/event-stream" \
        --max-time 10 \
        "$URL" 2>&1)
    echo "$response2"
    echo ""

    # Test 3: Just status code
    echo "--- Test 3: Status code extraction ---"
    status=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Accept: text/event-stream" \
        --max-time 10 \
        "$URL" 2>&1)
    exit_code=$?
    echo "Curl exit code: $exit_code"
    echo "Status code: '$status'"
    echo "Status length: ${#status}"
    echo ""

    # Test 4: Check what curl is actually returning
    echo "--- Test 4: Raw curl output ---"
    echo "Running: curl -s -w '%{http_code}' -o /tmp/mcp-body.txt ..."
    curl -s -w "%{http_code}" -o /tmp/mcp-body.txt \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Accept: text/event-stream" \
        --max-time 10 \
        "$URL" 2>&1
    echo ""
    echo "Body file size: $(wc -c < /tmp/mcp-body.txt 2>/dev/null || echo 0) bytes"
    echo "Body preview (first 200 bytes):"
    head -c 200 /tmp/mcp-body.txt 2>/dev/null || echo "(empty)"
    echo ""
else
    echo "Skipping auth tests - no token configured"
    echo ""
fi

# Test 5: DNS resolution
echo "--- Test 5: DNS resolution ---"
if command -v getent &> /dev/null; then
    getent hosts homeassistant.local || echo "DNS lookup failed"
elif command -v nslookup &> /dev/null; then
    nslookup homeassistant.local || echo "DNS lookup failed"
else
    echo "No DNS tools available"
fi
echo ""

# Test 6: Network connectivity
echo "--- Test 6: Network connectivity ---"
if command -v nc &> /dev/null; then
    timeout 3 nc -zv homeassistant.local 8123 2>&1 || echo "Port 8123 not reachable"
else
    echo "netcat not available"
fi
echo ""

echo "=== Debug Complete ==="
