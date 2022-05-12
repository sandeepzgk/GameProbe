const AWS = require("aws-sdk");
const Validator = require('jsonschema').Validator;
const express = require("express");
const serverless = require("serverless-http");

const db_schema = require("./schema.json");
const web_schema = require("./schema.json");

const app = express();
String.prototype.hashCode = function(){
  var hash = 0;
  for (var i = 0; i < this.length; i++) {
      var code = this.charCodeAt(i);
      hash = ((hash<<5)-hash)+code;
      hash = hash & hash; // Convert to 32bit integer
  }
  return hash;
}
const USERS_TABLE = process.env.USERS_TABLE;
String.prototype.hashCode = function(){
    var hash = 0;
    for (var i = 0; i < this.length; i++) {
        var code = this.charCodeAt(i);
        hash = ((hash<<5)-hash)+code;
        hash = hash & hash; // Convert to 32bit integer
    }
    return hash;
}
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
          //Todo: generate a hash with 6 bit and check theres no collision
          var hashed = false;
          while(!hashed){
            var email = req.body.email
            email = email.substr(email.length - 6)
            var time = String(Date.now())
            time  = time.substring(time.length - 6)
            
            var hash = (email + time).hashCode()
            console.log("time"+time +" hashs: "+ hash)
            //Check if the hash exist in the database, if so, generate another and try again.



            const getParams = {
                TableName: USERS_TABLE,
                // Key: {
                //   email: req.body.email,
                // },
                FilterExpression: 'email = :email and hashs = :hashs',
                ExpressionAttributeValues: {
                  ':email': req.body.email,
                  ':hashs': hash
                }
                
              };
            //console.log(48)
              var params;
              const Item= await dynamoDbClient.scan(getParams).promise().then(
                data =>{ console.log(data.Count);
                if(data.Count ==  0){
                  console.log(62)
                  instance.hashs = String(hash)
                  hashed = true;
                  params = {
                
                    TableName: USERS_TABLE,
                      Item: instance,
                    
                      
                  };
                  
                }
                }
                );
            }
            console.log(params.Item)
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

app.post("/getByEmail", async function(req, res) {
    const getParams = {
      TableName: USERS_TABLE,
      FilterExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': req.body.email
      }
      
    }
    console.log("getParams: "+ getParams.ExpressionAttributeValues+" email: "+ req.body.email);

      try {
        const Item= await dynamoDbClient.scan(getParams).promise().then(
          data =>{
          if(data.Count > 0){
            res.json(data.Items);
            
          }
          else{
            res
            .status(404)
            .json({ error: 'Could not find user with provided "userId"' });}
          }
        );
    
      } catch (error) {
        console.log(error);
        res.status(500).json({ error: "Could not retreive user" });
      }
    
});

app.post("/getById", async function(req, res) {
  const getParams = {
    TableName: USERS_TABLE,
    // Key: {
    //   email: req.body.email,
    // },
    FilterExpression: 'hashs = :hashs ',
    ExpressionAttributeValues: {
      ':hashs': req.body.hashs
    }
    
  }
    try {
      const Item= await dynamoDbClient.scan(getParams).promise().then(
        data =>{
        if(data.Count > 0){
          res.json(data.Items[0] );
          
        }
        else{
          res
          .status(404)
          .json({ error: 'Could not find user with provided "userId"' });}
        }
      );
  
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
