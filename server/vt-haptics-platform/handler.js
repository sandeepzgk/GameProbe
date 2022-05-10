const AWS = require("aws-sdk");
const Validator = require('jsonschema').Validator;


const express = require("express");
const serverless = require("serverless-http");
const db_schema = require("./server_schema.json");
const web_schema = require("./web_schema.json");

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

app.post("/createExperiment", async function (req, res) {
  var instance = req.body;
  var v = new Validator();
  var validation_result = v.validate(instance,web_schema)
  if(validation_result.valid==True)
  {

  }
  else
  {
    res.status(400).json({ error: "Could not retreive user",result:validation_result.errors });
  }

  const params = {
    TableName: USERS_TABLE,
    Item: {
      userId: userId,
      name: name,
    },
  };

  try {
    await dynamoDbClient.put(params).promise();
    res.json({ userId, name });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "Could not create user" });
  }
});

app.use((req, res, next) => {
  return res.status(404).json({
    error: "Not Found",
  });
});


module.exports.handler = serverless(app);
