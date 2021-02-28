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


# As of this writing (2/23/2021) the official emsdk Docker image is based on
# Debian Buster whose package manager includes CMake 3.13. Therefore we need
# to update the cmake in the docker image.
echo "Add CMake to emsdk Docker image for Web build"
docker exec -it emscripten sh -c "apt-get -qq update -y"
echo "Installing  apt-transport-https, etc."
docker exec -it emscripten sh -c "apt-get -qq install -y --no-install-recommends apt-transport-https gnupg software-properties-common wget libs"
echo "Fetching KitWare keys."
docker exec -it emscripten sh -c "wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null"
echo "Adding Kitware repository."
docker exec -it emscripten sh -c "apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ bionic main'"
echo "Updating package database."
docker exec -it emscripten sh -c "apt-get -qq update -y"
echo "Running autoremove."
docker exec -it emscripten sh -c "apt-get -qq autoremove -y"
echo "Installing cmake."
docker exec -it emscripten sh -c "apt-get -qq install -o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true -y --no-install-recommends cmake"

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
