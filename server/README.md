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
1.  Execute setup pre-requisites, please install nodeJS first
    ```bash 
    sudo npm i -g serverless         #install serverless for nodeJS
    cd server/                      
    npm install                      #install dependencies for the server from package.json
    ```
2. Configuring AWS Keys for deployment

    * You would need to configure your local machine with the appropriate keys to ensure that you have the right roles to deploy the services and files to AWS. You can do that by running the following code. You will not be able to deploy without these keys setup properly.

    ```bash
    export AWS_ACCESS_KEY_ID="YOUR_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_KEY"
    ```
3. Perform serverless login
    ```bash
    serverless login
    ````

4. To deploy to AWS (Lambda/S3/DynamoDB or core logic)

    _Important Note_: To update the ```******``` **_--stage variable_** to the right environment that is being used
    ```bash 
    serverless deploy --stage ******
    serverless remove --stage ******   # to remove the deployed services
    ```
    
5. To export the server environment so that the the webclient "knows" where to call 
    - This is the file that the webclient loads to find the server URL. This file has a getter function that looks at the static website domain, and pick the right URL for the backend lambda server. Please update the path for ```client/dist/assets/server.js``` as appropriately needed when introducing new environments.


6. To deploy to AWS (Static Files aka Static Web Pages or website)

    _Important Note_: To update the ```******``` **_--stage variable_** to the right environment that is being used
    ```bash 
    serverless client deploy --stage ******
    serverless client remove --stage ****** # to remove the deployed client
    ```


7. To deploy to different environments

    _Important Notes_: 
    * By default the deploy happens to the "dev" channel, i.e. development environment of aws for testing. To deploy to production environment execute 
    * Deploy to production environment only after thorough testing in the development environment

    ```bash
    serverless deploy --stage prod # for deploying the core logic to production environment, the DB, Lambda, S3 buckets are all different for this environment
    serverless client deploy --stage prod # for deploying the static website to production environment. 
    ```

## Testing
1. This project uses Postman for API testing and you can download local copy of postman from https://www.postman.com/
2. Postman collection is available at https://www.postman.com/sandeepzgk/workspace/vtgame-platform    
    * This collection is configured with the API and enviroment variables to test out the APIs

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
