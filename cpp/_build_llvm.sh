#!/bin/bash

git clone https://github.com/llvm/llvm-project.git

cd llvm-project

mkdir -p build && cd build

cmake -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ../llvm

make -j 4
