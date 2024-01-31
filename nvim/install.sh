#!/bin/bash

mkdir -p ~/.config/nvim

cp -r init.lua ~/.config/nvim
cp -r lua ~/.config/nvim

# initial installiation of the packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
