#!/bin/bash
stagedFile=$(echo $1 | cut -f2 -d'|')
executeCmd=$(echo $1 | cut -f1 -d'|')
echo $stagedFile
echo $executeCmd 
mc cp $executeCmd 
response=$(mc -json ls $stagedFile)
while [[ $response = *"Object does not exist"* ]]; do
 echo "File Not Found"
 sleep 30s
 response=$(mc -json ls $stagedFile)
done

echo "File Found!"
