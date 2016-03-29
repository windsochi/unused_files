#!/bin/sh
START=./sites/default/files
CURDIR=`pwd`
IG_STYLES=./styles/*
IG_JS=./js/*
IG_CSS=./css/*

dbdump=`pwd`/dumpwebsite.sql
usedfile=`pwd`/output_used.txt
notusedfile=`pwd`/output_notused.txt
notusedfile_check=`pwd`/output_notused_check.txt

cd ${START}
echo "Step 1. Checking for used and unused files to database..."
echo "$(date) $line"
for file in `find . ! -path "$IG_JS" ! -path "$IG_CSS" ! -path "$IG_STYLES" -type f -print | cut -c 3- | sed 's/ /#}/g'`
do
  file2=`echo $file | sed 's/#}/ /g'`
  file3=`basename $file2`
  result=`grep -c "$file3" $dbdump`
  if [ $result = 0 ]; then
    echo $file2 >> $notusedfile
  else
    echo $file2 >> $usedfile
  fi
done
cd ${CURDIR}

echo "Step 2. Checking files from list not used files..."
echo "$(date) $line"
for p in $(cat $notusedfile); do
  grep -rnw --include=*.{module,inc,php,js,css,html,htm,xml} ${CURDIR} -e $p  > /dev/null || echo $p >> $notusedfile_check;
done

echo "Files checking done."
echo "Check the following text-file for results:"
echo "$notusedfile_check"
