<!--
title: 'Serverless Framework Node Express API service backed by DynamoDB on AWS'
description: 'This is a document that explains how to run the ```vt-haptics-platform``` on AWS via Express API using DynamoDB, Lambda and Gateway.'
layout: Doc
framework: v3
platform: AWS
language: nodeJS
priority: 1
authorLink: 'https://www.skoll.me'
authorName: 'Sandeep K and Yang C'
-->

# Serverless Framework Node Express API on AWS

This is a document that explains how to run the ```vt-haptics-platform``` on AWS via Express API using DynamoDB, Lambda and Gateway.


## Setting up the Environment
1. Install NodeJS + NPM + JRE (offline dynamodb)
    ```bash
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs default-jre
    ```
2. Install SERVERLESS
    ```bash
    sudo npm i -g serverless
    ```
3. Move into directory
    ```bash
    cd vt-haptics-platform
    ```
4. Install Local SERVERLESS for Debug
    ```bash
    serverless plugin install -n serverless-dynamodb-local
    serverless plugin install -n serverless-offline
    sls dynamodb install
    ```
5. After that, running the following command with start both local API Gateway emulator as well as local instance of emulated DynamoDB:
    ```bash
    serverless offline start --lambdaPort 3002 --httpPort 3000
    ```

## Deploying

1. Install dependencies with:

    ```bash
    npm install
    ```
2. and then deploy with:
    ```bash
    serverless deploy
    ```


_Note_: In current form, after deployment, your API is public and can be invoked by anyone. For production deployments, you might want to configure an authorizer. For details on how to do that, refer to [`httpApi` event docs](https://www.serverless.com/framework/docs/providers/aws/events/http-api/). Additionally, in current configuration, the DynamoDB table will be removed when running `serverless remove`. To retain the DynamoDB table even after removal of the stack, add `DeletionPolicy: Retain` to its resource definition.
