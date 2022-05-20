<!--
title: 'Serverless Framework Node Express API service backed by DynamoDB on AWS'
description: 'This is a document that explains how to run the ```server``` on AWS via Express API using DynamoDB, Lambda and Gateway.'
layout: Doc
framework: v3
platform: AWS
language: nodeJS
priority: 1
authorLink: 'https://www.skoll.me'
authorName: 'Sandeep K and Yang C'
-->

# Serverless Framework Node Server Express API on AWS for iOS Haptic Game Platform

This is a document that explains how to run the ```server``` on AWS via Express API using DynamoDB, Lambda and Gateway.


## Setting up the Environment (for Ubuntu)
1.  Execute setup script
    ```bash 
    setuplocal.bash
    ```
2. To deploy to AWS (Lambda/S3/DynamoDB or core logic)
    ```bash 
    npm install         # to install dependencies
    serverless deploy
    serverless remove   # to remove the deployed services
    ```
3. To deploy to AWS (Static Files aka Static Web Pages or website)
    ```bash 
    serverless client deploy
    serverless client remove # to remove the deployed client
    ```    

## For Local Environment    
1. Install Local SERVERLESS for Debug
    ```bash
    serverless plugin install -n serverless-dynamodb-local
    serverless plugin install -n serverless-offline
    serverless plugin install -n serverless-s3-local
    serverless plugin install -n serverless-finch
    sls dynamodb install
    ```
2. After that, running the following command with start both local API Gateway emulator as well as local instance of emulated DynamoDB:
    ```bash
    serverless offline start --lambdaPort 3002 --httpPort 3000
    ```

_Note_: In current form, after deployment, your API is public and can be invoked by anyone. For production deployments, you might want to configure an authorizer. For details on how to do that, refer to [`httpApi` event docs](https://www.serverless.com/framework/docs/providers/aws/events/http-api/). Additionally, in current configuration, the DynamoDB table will be removed when running `serverless remove`. To retain the DynamoDB table even after removal of the stack, add `DeletionPolicy: Retain` to its resource definition.
