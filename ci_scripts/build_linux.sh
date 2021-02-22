#!/bin/bash
# Copyright 2015-2020 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

# exit if any command fails
set -e

# Explicitly take newer CMake installed from apt.kitware.com
CMAKE_EXE=/usr/bin/cmake


# Linux

echo "Configure KTX-Software (Linux Debug)"
${CMAKE_EXE} . -G Ninja -Bbuild-linux-debug -DCMAKE_BUILD_TYPE=Debug -DKTX_FEATURE_LOADTEST_APPS=ON
pushd build-linux-debug
echo "Build KTX-Software (Linux Debug)"
${CMAKE_EXE} --build .
echo "Test KTX-Software (Linux Debug)"
ctest # --verbose
popd

# Verify licensing meets REUSE standard.
reuse lint

echo "Configure KTX-Software (Linux Release)"
${CMAKE_EXE} . -G Ninja -Bbuild-linux-release -DCMAKE_BUILD_TYPE=Release -DKTX_FEATURE_LOADTEST_APPS=ON -DKTX_FEATURE_DOC=ON
pushd build-linux-release
echo "Build KTX-Software (Linux Release)"
${CMAKE_EXE} --build .
echo "Test KTX-Software (Linux Release)"
ctest # --verbose
echo "Pack KTX-Software (Linux Release)"
cpack -G DEB
cpack -G RPM
cpack -G TBZ2
popd


# Emscripten/WebAssembly


# Add cmake & cpack to the Emscripten docker image.
#echo "Add CMake to Emscripten Docker image for Web"
#docker exec -it emscripten sh -c "DEBIAN_FRONTEND=noninteractive apt-get update"
#docker exec -it emscripten sh -c "DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends apt-transport-https ca-certificates gnupg software-properties-common wget"
#docker exec -it emscripten sh -c "wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null"
#docker exec -it emscripten sh -c "DEBIAN_FRONTEND=noninteractive apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'"
#docker exec -it emscripten sh -c "DEBIAN_FRONTEND=noninteractive apt-get update"
#docker exec -it emscripten sh -c "DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends cmake"

echo "Emscripten version"
docker exec -it emscripten sh -c "emcc --version"

echo "Configure/Build KTX-Software (Web Debug)"
docker exec -it emscripten sh -c "emcmake cmake -Bbuild-web-debug . && cmake --build build-web-debug --config Debug"
echo "Configure/Build KTX-Software (Web Release)"
docker exec -it emscripten sh -c "emcmake cmake -Bbuild-web-release . && cmake --build build-web-release --config Release"

echo "Pack KTX-Software (Web Release)"
# Call cmake rather than cpack so we don't need knowledge of the working directory
# inside docker.
docker exec -it emscripten sh -c "cmake --build build-web-release --config Release --target package"
