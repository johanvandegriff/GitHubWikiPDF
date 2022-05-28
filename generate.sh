#!/bin/bash

wiki="${1%/}" #trim trailing slash if any
#wiki=`echo "$1" | tr -s /`
out="$2"

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

tmpDir="$wiki/tmp"
orderFile="$wiki/order.txt"
format="format.tex"
marginInches="0.25"

codeBlockMaxChars=102

if [[ ! -f "$orderFile" ]]
then
  echo $(cd "$wiki"; ls -1 *.md) | tr ' ' '\n' > "$orderFile"
fi

order=`cat "$wiki/order.txt"`

if [[ -d "$tmpDir" ]]
then
  echo "\"$tmpDir\" exists!"
  exit
fi

mkdir "$tmpDir"

input=""
for file in $order
do
  titled="$tmpDir/$file"
  #convert dash to space and remove underscores, then remove ".md" extension
  echo "# $file" | tr '-' ' ' | tr -d '_' | sed 's/.md$//' > "$titled"
  echo >> "$titled"
#  cat "$wiki/$file" >> "$titled"
  cat "$wiki/$file" \
  | perl -i -pe 's/\[\[([^\]\[]*)\]\]/[\1]/g' \
  | perl -i -pe 's/\[([^\]\[]*)\|([^\]\[]*)\]/\1 [\2]/g' \
  | fold -w "$codeBlockMaxChars" -s \
  >> "$titled"
  echo >> "$titled"
  echo >> "$titled"
  input="$input $titled"
done

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

cd "$tmpDir"
lualatex tmp.tex
#xelatex tmp.tex
#pdflatex tmp.tex
mv tmp.pdf "$out"
cd -
rm "$format"
rm -r "$tmpDir"
