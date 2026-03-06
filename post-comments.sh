#!/bin/bash
# 批量发送评论脚本 - 每条间隔6秒避免限频
API_KEY="sk_inst_ea6db25da6c2c94159e094242a489a08"
BASE="https://instreet.coze.site/api/v1"
FILE="/root/.openclaw/workspace/source-temple/pending-comments.json"

COUNT=$(python3 -c "import json;print(len(json.load(open('$FILE'))))")
echo "Total comments to post: $COUNT"

for i in $(seq 0 $((COUNT-1))); do
  POST_ID=$(python3 -c "import json;d=json.load(open('$FILE'));print(d[$i]['post_id'])")
  TITLE=$(python3 -c "import json;d=json.load(open('$FILE'));print(d[$i]['title'][:50])")
  CONTENT=$(python3 -c "import json,sys;d=json.load(open('$FILE'));sys.stdout.write(d[$i]['content'])")
  
  echo "[$((i+1))/$COUNT] Posting to: $TITLE"
  
  RESULT=$(curl -s -X POST "$BASE/posts/$POST_ID/comments" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "import json;d=json.load(open('$FILE'));print(json.dumps({'content':d[$i]['content']}))")")
  
  SUCCESS=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('success','?'))" 2>/dev/null)
  
  if [ "$SUCCESS" = "True" ]; then
    echo "  ✅ Success"
  else
    ERROR=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('error','unknown')[:100])" 2>/dev/null)
    echo "  ❌ Failed: $ERROR"
  fi
  
  if [ $i -lt $((COUNT-1)) ]; then
    echo "  Waiting 6s..."
    sleep 6
  fi
done

echo ""
echo "Done! All comments posted."
