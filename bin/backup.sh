#!/bin/bash

mkdir -p ~/backup

rsync -azP ~/Dropbox/KeePass ~/backup
rsync -azP ~/Dropbox/Logs ~/backup
