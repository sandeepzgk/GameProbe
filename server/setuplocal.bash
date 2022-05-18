#!/bin/bash
curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "./.fnm" --skip-shell
fnm install
sudo npm i -g serverless
cd server/
npm install


