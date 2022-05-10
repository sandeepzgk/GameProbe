#!/bin/bash

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs default-jre
sudo npm i -g serverless

cd server/vt-haptics-platform
npm i -g serverless-offline
serverless plugin install -n serverless-dynamodb-local
serverless plugin install -n serverless-offline
sls dynamodb install


