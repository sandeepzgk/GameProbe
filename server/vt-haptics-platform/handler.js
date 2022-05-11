const AWS = require("aws-sdk");
const Validator = require('jsonschema').Validator;
const express = require("express");
const serverless = require("serverless-http");

const db_schema = require("./schema.json");
const web_schema = require("./schema.json");
const {google} = require('googleapis');
const google_api_key ={
    client_email: process.env.CLIENT_EMAIL,
    private_key: process.env.PRIVATE_KEY,
   }
const auth = new google.auth.JWT(
    google_api_key.client_email,
    null,
    google_api_key.private_key,
    ["https://www.googleapis.com/auth/analytics.readonly"],
    null
);
const app = express();

const USERS_TABLE = process.env.USERS_TABLE;

const dynamoDbClientParams = {};
if (process.env.IS_OFFLINE) {
    dynamoDbClientParams.region = 'localhost'
    dynamoDbClientParams.endpoint = 'http://localhost:8000'
    AWS.config.update({
        region: 'localhost',
        accessKeyId: 'xxxxxxxxxxxxxx',
        secretAccessKey: 'xxxxxxxxxxxxxx',
    });
}
const dynamoDbClient = new AWS.DynamoDB.DocumentClient(dynamoDbClientParams);

app.use(express.json());

google.options({auth});

app.post("/setExperiment", async function(req, res) {
    var instance = req.body;
    var v = new Validator();
    var validation_result = v.validate(instance, web_schema)
    if (validation_result.valid) {
        const params = {
            TableName: USERS_TABLE,
            Item: instance,

            
        };

        try {
            const getParams = {
                TableName: USERS_TABLE,
                Key: {
                  email: req.body.email,
                },
                
              };
           
            const { Item } = await dynamoDbClient.get(getParams).promise();
            var toEdit = Item
            toEdit.haptic_setup+=(instance.haptic_setup)
            console.log(toEdit.haptic_setup);
            await dynamoDbClient.put(toEdit).promise();
            
            res.status(200); 
            
        } catch (error) {
            console.log(error);
            res.status(500).json({
                error: "Could not create user"
            });
        }

    } else {
        res.status(400).json({
            error: "Validation Error",
            validation_result: validation_result.errors
        });
    }
   
    
    res.end()
    
});

app.post("/getExperiment", async function(req, res) {
    const params = {
        TableName: USERS_TABLE,
        Key: {
          email: req.body.email,
        },
        
      };
    
      try {
        const { Item } = await dynamoDbClient.get(params).promise();
        
        if (Item) {
            
          

          res.json(Item );
        } else {
          res
            .status(404)
            .json({ error: 'Could not find user with provided "userId"' });
        }
      } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Could not retreive user" });
      }
    
});

app.use((req, res, next) => {
    return res.status(404).json({
        error: "Not Found",
    });
});


module.exports.handler = serverless(app);
