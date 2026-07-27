#!/bin/bash
# Script to create the admin document in Firestore
# Uses the Firebase CLI to set the document at /admins/{uid}

cd "$(dirname "$0")/.."

# Create a temporary JSON file with the admin data
cat > /tmp/admin_doc.json << 'DATA'
{
  "fields": {
    "uid": { "stringValue": "58dh7Rn7ZUSSLvvC41qPzJabgnV2" },
    "email": { "stringValue": "jagadeeshmurthym4@gmail.com" },
    "fullName": { "stringValue": "Jagadeesh Murthy M" },
    "role": { "stringValue": "admin" },
    "isActive": { "booleanValue": true },
    "createdAt": { "timestampValue": null },
    "updatedAt": { "timestampValue": null }
  }
}
DATA

echo "📝 Creating admin document at /admins/58dh7Rn7ZUSSLvvC41qPzJabgnV2..."

# Use firebase firestore:set to ensure the document is created correctly
firebase firestore:set --project cashspark-c15bd /admins/58dh7Rn7ZUSSLvvC41qPzJabgnV2 /tmp/admin_doc.json 2>&1

echo ""
echo "✅ Done!"
