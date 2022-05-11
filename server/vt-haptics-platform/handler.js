const AWS = require("aws-sdk");
const Validator = require('jsonschema').Validator;
const express = require("express");
const serverless = require("serverless-http");

const db_schema = require("./schema.json");
const web_schema = require("./schema.json");

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


app.post("/setExperiment", async function(req, res) {
    var instance = req.body;
    var json_ins = JSON.stringify(instance)
    var jb = JSON.parse(json_ins)
    var v = new Validator();
    var validation_result = v.validate(instance, web_schema)
    if (validation_result.valid) {
        

        try {
            const getParams = {
                TableName: USERS_TABLE,
                // Key: {
                //   email: req.body.email,
                // },
                FilterExpression: 'email = :email ',
                ExpressionAttributeValues: {
                  ':email': req.body.email
                }
                
              };
           //console.log(48)
            var params;
            const Item= await dynamoDbClient.scan(getParams).promise().then(
              data =>{ console.log(data.Count);
              if(data.Count > 0){
                var toEdit = data.Items[0];
                params = {
              
                  TableName: USERS_TABLE,
                    Item: instance,
                };
                toEdit.haptic_setup.push(instance.haptic_setup[0])
                console.log(toEdit.haptic_setup)
                params = {
              
                  TableName: USERS_TABLE,
                    Item: toEdit,
                };
              }
              else{
                console.log(62)
                params = {
              
                  TableName: USERS_TABLE,
                    Item: instance,
        
                    
                };
                
              }
              }
              );
              await dynamoDbClient.put(params).promise();
            
            
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
