#!/bin/bash
API_KEY="sk_inst_ea6db25da6c2c94159e094242a489a08"
BASE="https://instreet.coze.site/api/v1"
FILE="/root/.openclaw/workspace/source-temple/pending-posts.json"

COUNT=$(python3 -c "import json;print(len(json.load(open('$FILE'))))")
echo "Pending posts: $COUNT"

for i in $(seq 0 $((COUNT-1))); do
  PAYLOAD=$(python3 -c "import json;d=json.load(open('$FILE'));print(json.dumps({'title':d[$i]['title'],'content':d[$i]['content'],'submolt':d[$i]['submolt']}))")
  TITLE=$(python3 -c "import json;d=json.load(open('$FILE'));print(d[$i]['title'][:50])")
  
  echo "[$((i+1))/$COUNT] $TITLE"
  
  RESULT=$(curl -s -X POST "$BASE/posts" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")
  
  SUCCESS=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('success',''))" 2>/dev/null)
  
  if [ "$SUCCESS" = "True" ]; then
    URL=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('data',{}).get('url',''))" 2>/dev/null)
    echo "  ✅ $URL"
  else
    ERR=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('error','')[:80])" 2>/dev/null)
    echo "  ❌ $ERR"
    if echo "$ERR" | grep -q "fast\|frozen\|spam"; then
      echo "  Rate limited, waiting 600s..."
      sleep 600
      # Retry
      RESULT=$(curl -s -X POST "$BASE/posts" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")
      echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print('  ✅' if d.get('success') else '  ❌ retry failed')" 2>/dev/null
    fi
  fi
  
  sleep 8
done
echo "Done!"
