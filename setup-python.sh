#!/bin/zsh

# install python
asdf plugin-add python
asdf install python 3.11.3
asdf global python 3.11.3

# torch
pip3 install --upgrade pip
pip3 install torch torchvision
