#!/usr/bin/env bash

# sanity checks for argument 1/filepath
if [ -z "$1" ]; then
    echo "File not found"
    exit 2
fi


pathTo=~/icon.iconset

mkdir $pathTo
cp $1 $pathTo/icon_512x512@2x.png
convert $1 -resize 512x512  $pathTo/icon_512x512.png
convert $1 -resize 512x512  $pathTo/icon_512x512.png
convert $1 -resize 512x512  $pathTo/icon_256x256@2x.png
convert $1 -resize 256x256  $pathTo/icon_256x256.png
convert $1 -resize 256x256  $pathTo/icon_128x128@2x.png
convert $1 -resize 128x128  $pathTo/icon_128x128.png
convert $1 -resize 64x64    $pathTo/icon_32x32@2x.png
convert $1 -resize 32x32    $pathTo/icon_32x32.png
convert $1 -resize 32x32    $pathTo/icon_16x16@2x.png
convert $1 -resize 16x16    $pathTo/icon_16x16.png
iconutil -c icns $pathTo
rm -r $pathTo



