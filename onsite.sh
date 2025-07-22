#!/bin/bash

if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root"
  exit 1
fi

OUT_DIR="/reports"
mkdir -p "$OUT_DIR"

OUT_FILE="$OUT_DIR/$(date +%s)"
EXT_FILE=$(mktemp)
YMS_FILE=$(mktemp)
SIZ_FILE=$(mktemp)
PMS_FILE=$(mktemp)
TMP_FILES=$(mktemp)

touch "$OUT_FILE"

# below path must be absolute
find /home/skndash96/httpd > $TMP_FILES
readarray -n 1000 files < $TMP_FILES

declare -A extensions
declare -A yms
declare -A yms_array
declare -A pms

for file in "${files[@]}"; do
  file=$(echo "$file" | tr -d '\n')

  if [[ ! -f "$file" ]]; then
    echo "Skipping $file, not a file"
    continue
  fi

  name=`basename "$file"`

  ext=none
  if [[ -n "$(echo "$name" | grep '\.')" ]]; then
    ext=${name##*.}
  fi

  # mod=`stat -c %Y "$file"`  # doesnt work why?
  size=`stat -c %s "$file"`
  mod=`stat -c %y "$file"`
  urwx=`stat -c %A "$file"`
  octal=`stat -c %a "$file"`
  ym=${mod:0:7}

  echo "$size $file" >> $SIZ_FILE

  yms[$ym]=$(( ${yms[$ym]:-0} + 1 ))
  if [[ yms[$ym] -le "10" ]]; then
    yms_array[$ym]=`echo "${yms_array[$ym]:-}###$file"`
  fi

  extensions[$ext]=$(( ${extensions[$ext]:-0} + 1 ))
  pms[$octal]=$(( ${pms[$octal]:-0} + 1 ))
done

for ext in "${!extensions[@]}"; do
  echo "$ext: ${extensions[$ext]}" >> $EXT_FILE
done

for ym in "${!yms[@]}"; do
  echo "$ym: ${yms[$ym]}${yms_array[$ym]}" >> $YMS_FILE
  echo "" >> $YMS_FILE
done

for pm in "${!pms[@]}"; do
  echo "$pm: ${pms[$pm]}" >> $PMS_FILE
done

echo "Report at $OUT_FILE" > $OUT_FILE
echo "Total files: ${#files[@]}" >> $OUT_FILE

echo -e "\nMost Active Months" >> $OUT_FILE
cat $YMS_FILE | sort -k2 -n -r | head -n 10 | sed 's/###/\n/g' >> $OUT_FILE

echo -e "\nMost Common Extensions" >> $OUT_FILE
cat $EXT_FILE | sort -k2 -n -r | head -n 10 >> $OUT_FILE

echo -e "\nLargest File sizes" >> $OUT_FILE
cat $SIZ_FILE | sort -k1 -n -r | head -n 10 >> $OUT_FILE

echo -e "\nMost Common Permissions" >> $OUT_FILE
cat $PMS_FILE | sort -k2 -n -r | head -n 10 >> $OUT_FILE

echo "Report generated at $OUT_FILE, SIZ_FILE $SIZ_FILE, EXT_FILE $EXT_FILE, YMS_FILE $YMS_FILE"

echo "Temp files cleaning.."
rm -f "$EXT_FILE" "$YMS_FILE" "$SIZ_FILE" "$PMS_FILE"

echo "Older reports cleaning.."
find $OUT_DIR -type f -mtime +7 -delete

# For the cronjob part, move this script to cron.daily and it should work.