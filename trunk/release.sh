#!/bin/bash

if [[ $1 != [0-9].[0-9][0-9] ]]; then
  echo Wrong version format. Expected: d.dd
  exit;
fi

# Update version info
# NB: streaming to a temp file. The "-i" option in sed doesn't seem to work.
sed {s/version\ =\ [0-9]\.[0-9][0-9]/version\ =\ $1/} dsss.conf > dsss.conf.tmp
sed {s/VERSION\ =\ \"[0-9]\.[0-9][0-9]\"/VERSION\ =\ \"$1\"/} src/main.d > main.d.tmp
mv dsss.conf.tmp dsss.conf
mv main.d.tmp src/main.d

NAME="openquran"
BUILD="./build/"
LINDIR="$NAME.$1_linux"
WINDIR="$NAME.$1_windows"
SRCDIR="$NAME.$1_src"
LINDEST="${BUILD}$LINDIR"
WINDEST="${BUILD}$WINDIR"
SRCDEST="${BUILD}$SRCDIR"

# Convert Unix newlines to Windows newlines
function unix2win
{
  sed {s/$/\\r/} $*
}
# Calls the Windows version of dmd with wine.
function windmd
{
  wine ~/bin/dmd.exe $*
}

# Build Windows binary.
if [[ -s ~/bin/dmd.exe ]] ; then
  rm -rf $WINDEST
  mkdir $WINDEST
  windmd src/*.d -release -O -inline -odwinobj -ofquran
  cp quran.exe $WINDEST
  unix2win COPYING > $WINDEST/License.txt
  unix2win CHANGELOG > $WINDEST/Changelog.txt
  # Build an archive
  $(cd $BUILD &&
    zip -q -9 -r $WINDIR.zip $WINDIR
  )
else
  echo Warning: Not building Windows package. dmd.exe not found in \~/bin/
fi

# Build Linux binary and source package.
rm -rf $LINDEST $SRCDEST
mkdir $LINDEST $SRCDEST $SRCDEST/src $SRCDEST/doc
dsss build -clean -full -release -O -inline -D -Dd$SRCDEST/doc
cp quran $LINDEST
cp COPYING $LINDEST/License
cp CHANGELOG $LINDEST/Changelog
# src
rm $SRCDEST/doc/gcstats.html # generated by rebuild
cp src/*.d $SRCDEST/src
cp AUTHORS COPYING CHANGELOG dsss.conf release.sh $SRCDEST

# Build archives
cd $BUILD
tar --owner root --group root -czf $LINDIR.tar.gz $LINDIR
#tar --owner root --group root -czf $SRCDIR.tar.gz $SRCDIR
#tar --owner root --group root --bzip2 -cf $SRCDIR.tar.bz2 $SRCDIR
zip -q -9 -r $SRCDIR.zip $SRCDIR

# Code for zipping every file in the current directory.
#for qfile in $(ls); do
#  zip -q -9 -r ${qfile}_1.0.zip $qfile
#done