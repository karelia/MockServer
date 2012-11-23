#!/usr/bin/env bash

base=`dirname $0`
echo "$base"
pushd "$base/.." > /dev/null
build="$PWD/test-build"
ocunit2junit="$base/OCUnit2JUnit/bin/ocunit2junit"
popd > /dev/null

sym="$build/sym"
obj="$build/obj"

testout="$build/output.log"
testerr="$build/error.log"

rm -rf "$build"
mkdir -p "$build"

xcodebuild -workspace "MockServer.xcworkspace" -scheme "Unit Tests" -sdk "macosx" -config "Debug" test OBJROOT="$obj" SYMROOT="$sym" > "$testout" 2> "$testerr"
cd "$build"
"../$ocunit2junit" < "$testout"
