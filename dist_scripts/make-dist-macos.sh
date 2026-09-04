#!/bin/bash
make clean
make

VERSION=`cargo tree --depth 0 | awk '{print $2;}'`
DIST_DIR=fab-agon-emulator-$VERSION-macos

rm -rf $DIST_DIR
mkdir $DIST_DIR
cp ./fab-agon-emulator $DIST_DIR
cp ./target/release/agon-cli-emulator $DIST_DIR
dist_scripts/bundle-macos-sdl3.sh $DIST_DIR/fab-agon-emulator
cp -r ./firmware $DIST_DIR
cp LICENSE README.md $DIST_DIR
mkdir $DIST_DIR/THIRD-PARTY-LICENSES
cp dist_scripts/THIRD-PARTY-LICENSES/*.txt $DIST_DIR/THIRD-PARTY-LICENSES/
mkdir $DIST_DIR/sdcard
cp -r sdcard/* $DIST_DIR/sdcard/
zip $DIST_DIR.zip -r $DIST_DIR/*
