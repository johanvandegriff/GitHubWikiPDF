#!/bin/bash

wiki="${1%/}" #trim trailing slash if any
#wiki=`echo "$1" | tr -s /`
out="$2"

wiki=`readlink -f "$wiki"`
out=`readlink -f "$out"`

if [[ ! -d "$wiki" ]]
then
  echo "\"$wiki\" does not exist!"
  exit
fi

if [[ -z "$out" ]]
then
  echo "no output file given!"
  exit
fi

#tmpDir="$wiki/tmp"
tmpDir=`mktemp -d`
orderFile="$wiki/order.txt"
format="format.tex"
marginInches="0.25"

codeBlockMaxChars=102

if [[ ! -f "$orderFile" ]]
then
  echo $(cd "$wiki"; ls -1 *.md) | tr ' ' '\n' > "$orderFile"
fi

order=`cat "$wiki/order.txt"`

input=""
for file in $order
do
  titled="$tmpDir/$file"
  #convert dash to space and remove underscores, then remove ".md" extension
  echo "# $file" | tr '-' ' ' | tr -d '_' | sed 's/.md$//' > "$titled"
  echo >> "$titled"
#  cat "$wiki/$file" >> "$titled"

#download images by searching for "?raw=true" and replace the reference with a local file
  cat "$wiki/$file" <(echo) | while IFS= read -r line; do
    if echo "$line" | grep '\?raw\=true' > /dev/null; then
      link=`echo "$line" | sed 's,\!\[.*\](\(.*\)?raw\=true)$,\1,g'` #get the link
      basename=`basename "$link"`
      #wget "https://github.com/FTC7393/EVLib/blob/master/images/attach.png?raw=true" -O attach.png
      wget "${link}?raw=true" -O "$tmpDir/$basename"
      line2=`echo "$line" | sed 's,\]\(.*\),],g'` #remove the link
      line2="${line2}($tmpDir/$basename)"
      echo "$line2"
    else
      echo "$line"
    fi
  done \
  | perl -pe 's/\[\[([^\]\[]*)\]\]/[\1]/g' \
  | perl -pe 's/\[([^\]\[]*)\|([^\]\[]*)\]/\1 [\2]/g' \
  | fold -w "$codeBlockMaxChars" -s \
  >> "$titled"

  echo >> "$titled"
  echo >> "$titled"

  input="$input $titled"
done

cd "$tmpDir"

echo "
\hypersetup{
  colorlinks=false,
%  colorlinks=true,
%  linkcolor=blue,
  allbordercolors={0 0 0},
  pdfborderstyle={/S/U/W 1}
}
" > "$format"

echo pandoc $input -H "$format" -V geometry:margin="${marginInches}in" -o "$tmpDir/tmp.tex"
echo "======================================="
pandoc $input -H "$format" -V geometry:margin="${marginInches}in" -o "$tmpDir/tmp.tex"

lualatex tmp.tex
#xelatex tmp.tex
#pdflatex tmp.tex
mv tmp.pdf "$out"
#mv tmp.tex "$out.tex"
cd -
rm -r "$tmpDir"
