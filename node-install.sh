#!/bin/bash
echo '========================================================'
echo '=== STEP 1: NODE.JS PRE REQUIREMENTS ==='
echo '========================================================'
sudo apt-get update
sudo apt-get install -y \
curl \
software-properties-common \
unzip
echo '=============================================================='
echo '=== STEP 2: ADD REPO FOR NODE.JS INSTALLATION ==='
echo '=============================================================='
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
echo '====================================='
echo '=== STEP 3: NODE.JS INSTALLATION ==='
echo '====================================='
sudo apt-get install -y nodejs
echo '==============================================================='
echo '=== STEP 4: VERIFY NODE.JS AND NPM INSTALLATION ==='
echo '==============================================================='
node -v
npm -v
echo '========================================================='
echo '=== STEP 5: INSTALL YARN (OPTIONAL) ==='
echo '========================================================='
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install -y yarn
yarn -v
echo '========================================================='
echo '=== NODE.JS INSTALLATION COMPLETED SUCCESSFULLY ==='
echo '========================================================='
