#!/usr/bin/env bash

base=`dirname $0`
echo "$base"
pushd "$base/.." > /dev/null
build="$PWD/test-build"
popd > /dev/null

sym="$build/sym"
obj="$build/obj"

rm -rf "$build"
mkdir -p "$build"

xcodebuild -workspace "KSMockServer.xcworkspace" -scheme "Unit Tests" -sdk "macosx" -config "Debug" test OBJROOT="$obj" SYMROOT="$sym" # > "$testout" 2> "$testerr"
