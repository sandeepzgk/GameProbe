const AWS = require("aws-sdk");
const Validator = require("jsonschema").Validator;
const express = require("express");
const serverless = require("serverless-http");
AWS.config.update({
    //accessKeyId: 'AKIAZTPKKP6ANO7VKR7Y' ,
    //secretAccessKey: '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' ,
    region: "us-east-1",
    //endpoint: 'http://localhost:8000',
  });
//AWS.config.update({region: 'REGION'});// Create DynamoDB document client
//v//ar docClient = new AWS.DynamoDB.DocumentClient({apiVersion: '2012-08-10'});
const db_schema = require("./schema.json");

//const { S3Client, PutObjectCommand, S3 } = require("@aws-sdk/client-s3");
const app = express();
const USERS_TABLE = process.env.USERS_TABLE;
const s3 = new AWS.S3();

String.prototype.hashCode = function() {
    var hash = 0;
    for (var i = 0; i < this.length; i++) {
        var code = this.charCodeAt(i);
        hash = ((hash << 5) - hash) + code;
        hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
}
const dynamoDbClientParams = {};
// if (process.env.IS_OFFLINE) {
    dynamoDbClientParams.region = "us-east-1";
    // dynamoDbClientParams.endpoint = "http://localhost:8000";
    // AWS.config.update({
    //     region: "localhost",
    //     endpoint: 'http://localhost:8000',
    //     accessKeyId: "xxxxxxxxxxxxxx",
    //     secretAccessKey: "xxxxxxxxxxxxxx",
    //});
//}
const dynamoDbClient = new AWS.DynamoDB.DocumentClient()//dynamoDbClientParams);


app.use(express.json());
app.post("/setExperiment" ,async function(req, res) {
    var instance = req.body;
    var v = new Validator();
    var validation_result = v.validate(instance, db_schema);
    if (validation_result.valid) {
        try {
            //Todo: generate a hash with 6 bit and check theres no collision
            var hashed = false;
            while (!hashed) {
                var email = req.body.email;
                email = email.substr(0, email.length<4?email.length:4); 
                var time = String(Date.now());
                time = time.substring(time.length - 4);
                var hash = (email + time).hashCode();
                console.log(57);
                //Check if the hash exist in the database, if so, generate another and try again.
                const getParams = {
                    TableName: USERS_TABLE,
                    FilterExpression: "email = :email and hashs = :hashs",
                    ExpressionAttributeValues: {
                        ":email": req.body.email,
                        ":hashs": hash
                    }
                };
                // const getParams = {
                //     TableName: USERS_TABLE,
                //     Key: {
	
                //         ":hashs": hash,
                      
                //       },
                // };
                console.log(hash);
                var params;
                const Item = await dynamoDbClient.scan(getParams).promise().then(
                    data => {
                        console.log(data.Count);
                        if (data.Count == 0) {

                            instance.hashs = String(hash);
                            hashed = true;
                            params = {
                                TableName: USERS_TABLE,
                                Item: instance,
                            };
                        }
                    }
                );
                // await dynamoDbClient.get(getParams, (error, result) => {
	
                //     if (error) {
                    
                //       console.log("88: "+error);
                    
                //       res.status(400).json({ error: 'Could not get user' });
                    
                //     }
                //     console.log(101);
                //     if (result.Item) {
                    
                //       print("found user ");

                //     //res.json(result.Item);
                //       //res.json({ userId, name });
                    
                //     } else {
                        
                //             instance.hashs = String(hash);
                //             hashed = true;
                //             params = {
                //                 TableName: USERS_TABLE,
                //                 Item: instance,
                //             };
                        
                //     // res.status(404).json({ error: "User not found" });
                //     console.log("No user found ");
                //     }
                    
                //   }).promise();
                console.log(81);
                //console.log(88)
                console.log(instance.haptic_setup[0].linked_files.long_effect+String(hash)+"-long")
                console.log(instance.haptic_setup[0].linked_files.short_effect+String(hash)+"-short")
               // console.log(88)
                await s3
                  .upload({
                      Bucket: "haptic-bucket",
                      Key: String(hash)+"-long",
                      Body: instance.haptic_setup[0].linked_files.long_effect
                    }
                      //Buffer.from("abcd"),
                    ).promise()
	                //.then(() => callback(null, "ok"));
               
                await s3
                  .upload({
                      Bucket: "haptic-bucket",
                      Key: String(hash)+"-short",
                      Body: instance.haptic_setup[0].linked_files.short_effect,
                      ACL: 'public-read'
                    }
                      //Buffer.from("abcd"),
                    ).promise()
                // s3
                //     .upload(
                //       new PutObjectCommand({
                //         Bucket: "local-bucket",
                //         Key: String(hash)+"-short",
                //         Body: instance.haptic_setup[0].linked_files.short_effect
                //         //Buffer.from("abcd"),
                //       }))
                      //.then(() => callback(null, "ok"));
               
            }
            await dynamoDbClient.put(params).promise();
            res.status(200);
        } catch (error) {
            console.log(error)
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
        FilterExpression: "email = :email",
        ExpressionAttributeValues: {
            ":email": req.body.email
        }
    }

    try {
        const Item = await dynamoDbClient.scan(getParams).promise().then(
            data => {
                if (data.Count > 0) {
                    res.json(data.Items);
                } else {
                    res.status(404).json({
                        error: "Could not find user with provided id"
                    });
                }
            }
        );
    } catch (error) {
        res.status(500).json({
            error: "Could not retreive user"
        });
    }
});

app.post("/getById", async function(req, res) {
    const getParams = {
        TableName: USERS_TABLE,
        FilterExpression: "hashs = :hashs ",
        ExpressionAttributeValues: {
            ":hashs": req.body.hashs
        }
    }
    try {
        const Item = await dynamoDbClient.scan(getParams).promise().then(
            data => {
                if (data.Count > 0) {
                    res.json(data.Items[0]);
                } else {
                    res.status(404).json({
                        error: "Could not find experiment with provided id"
                    });
                }
            }
        );
    } catch (error) {
        res.status(500).json({
            error: "Could not retreive user"
        });
    }
});

app.post("/getFile", async function(req,res){
    console.log("file",req.body.filename);
    var bucketParams = {
        Bucket: "haptic-bucket",  
        Key: req.body.filename
    };
    s3.getObject(bucketParams, function(err, data) {
        // Handle any error and exit
        if (err){
            console.log(err)
            console.log(195)
            return err;
        }
      // No error happened
      // Convert Body from a Buffer to a String
      let objectData = data.Body.toString('utf-8'); // Use the encoding necessary
      console.log(199)
      console.log(objectData);
    });
    res.status(200);
        /*bucketParams)
            .createReadStream()
            .pipe(res);
*/
    

})
app.use((req, res, next) => {
    return res.status(404).json({
        error: "Not Found",
    });
});

module.exports.handler = serverless(app);
