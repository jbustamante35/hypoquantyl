#!/bin/bash
OLDIFS=$IFS
IFS=$'\n'
echo "Searching for job:" $1
for prkey in $(sqlite3 -separator ',' /mnt/spaldingarchive/phytoMorphService/dagDB.db 'SELECT sourceName,targetName FROM stage WHERE jobUUID="'"$1"'"') 
do
    source=$(echo "${prkey}" | cut -d',' -f1)
    target=$(echo "${prkey}" | cut -d',' -f2)
    echo "source:"$source
    echo "target:"$target
    mc rm "$target"
done;
IFS=$OLDIFS
