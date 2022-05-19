const AWS = require("aws-sdk");
const Validator = require("jsonschema").Validator;
const express = require("express");
const serverless = require("serverless-http");
AWS.config.update(
{
    region: "us-east-1"
});
const db_schema = require("./static/assets/formschema.json");
const app = express();
const DATA_TABLE = process.env.DATA_TABLE;
const STORAGE_BUCKET = process.env.STORAGE_BUCKET;
const s3 = new AWS.S3();
const debug = true;

const dynamoDbClient = new AWS.DynamoDB.DocumentClient();

function debuglog(str)
{
    if (debug)
    {
        console.log(str);
    }
}


app.use(express.json());
app.post("/setExperiment", async function(req, res)
{
    var instance = req.body;
    debuglog("Instance: ",instance);
    debuglog(JSON.stringify(instance));
    var v = new Validator();
    var validation_result = v.validate(instance, db_schema);
    if (validation_result.valid)
    {
        debuglog("Validation Success");
        try
        {
            var unique = false;
            while (!unique)
            {              
                var uid = Math.random().toString(26).slice(-2).toUpperCase()+String(Date.now()).slice(-3);
                debuglog("Computed expid:" + uid);
                //Check if the generated uid is genuinely expid (i.e not exisiting in the database)
                const getParams = {
                    TableName: DATA_TABLE,
                    FilterExpression: "email = :email and expid = :expid",
                    ExpressionAttributeValues:
                    {
                        ":email": req.body.email,
                        ":expid": uid
                    }
                };

                var putParams;
                const Item = await dynamoDbClient.scan(getParams).promise().then(
                    getData =>
                    {
                        if (getData.Count == 0)
                        {

                            instance.expid = String(uid);
                            unique = true;
                            putParams = {
                                TableName: DATA_TABLE,
                                Item: instance,
                            };                        
                        }
                    }
                );
            }

            for (var i=0; i<Object.keys(instance.linked_files).length; i++)
            {
                var s3Key = String(uid) + "/" + Object.keys(instance.linked_files)[i];
                /*** Example File Data
                 * "long_effect": "data:application/octet-stream;name=two.haptics;base64,dHdvdHdvdHdv" 
                 ***/
                var fileData = instance.linked_files[Object.keys(instance.linked_files)[i]].split(";")[2]; //extracting the last part of the upload , i.e. in the above example "base64,dHdvdHdvdHdv"
                var fileBody = Buffer.from(fileData.split(",")[1], 'base64').toString('binary'); // converting fileData after splitting the base64 header to binary object for s3 upload
                await s3.upload(
                    {
                        Bucket: STORAGE_BUCKET,
                        Key: s3Key ,
                        Body: fileBody
                    }).promise()
                    .then(function(data) 
                    {
                        debuglog("Successfully Upload s3");
                        debuglog(JSON.stringify(data));
                    })
                    .catch(function(err) 
                    {
                        debuglog("Failed Upload s3");
                        debuglog(JSON.stringify(err));
                    });

            }

            debuglog("Put Parameters to DB :");
            debuglog(JSON.stringify(putParams));

            delete putParams.Item["linked_files"]; //deleting files from being injected into the database, it needs to be only available for s3 uploads
            debuglog("Delete Put Param Files");
            debuglog(JSON.stringify(putParams));
            dynamoDbClient.put(putParams).promise()
                .then(function(data) 
                    {
                        debuglog("Success");
                        debuglog(JSON.stringify(data));
                    })
                .catch(function(err) 
                    {
                        debuglog("Failure");
                        debuglog(JSON.stringify(err));
                    });

            res.status(200).json(
                {
                    expid: uid
                });
        }
        catch (err)
        {
            debuglog(err);
            res.status(500).json(
            {
                error: "Could not create user"
            });
        }
    }
    else
    {
        debuglog("Validation Error");
        debuglog(JSON.stringify(validation_result.errors));
        res.status(400).json(
        {
            error: "Validation Error",
            validation_result: validation_result.errors
        });
    }
    res.end()
});

app.post("/getByEmail", async function(req, res)
{
    const getParams = {
        TableName: DATA_TABLE,
        FilterExpression: "email = :email",
        ExpressionAttributeValues:
        {
            ":email": req.body.email
        }
    }

    try
    {
        const Item = await dynamoDbClient.scan(getParams).promise().then(
            data =>
            {
                if (data.Count > 0)
                {
                    res.json(data.Items);
                }
                else
                {
                    res.status(404).json(
                    {
                        error: "Could not find user with provided id"
                    });
                }
            }
        );
    }
    catch (error)
    {
        res.status(500).json(
        {
            error: "Could not retreive user"
        });
    }
});

app.post("/getById", async function(req, res)
{
    const getParams = {
        TableName: DATA_TABLE,
        FilterExpression: "expid = :expid ",
        ExpressionAttributeValues:
        {
            ":expid": req.body.expid
        }
    }
    try
    {
        const Item = await dynamoDbClient.scan(getParams).promise().then(
            data =>
            {
                if (data.Count > 0)
                {
                    res.json(data.Items[0]);
                }
                else
                {
                    res.status(404).json(
                    {
                        error: "Could not find experiment with provided id"
                    });
                }
            }
        );
    }
    catch (error)
    {
        res.status(500).json(
        {
            error: "Could not retreive user"
        });
    }
});

app.post("/getFile", async function(req, res)
{
    var bucketParams = {
        Bucket: STORAGE_BUCKET,
        Key: req.body.filename
    };
    s3.getObject(bucketParams, function(err, data)
    {
        // Handle any error and exit
        if (err)
        {
            debuglog(err);
            return err;
        }
        let objectData = data.Body.toString('utf-8'); // Use the encoding necessary
    });
    res.status(200);



})
app.use((req, res, next) =>
{
    return res.status(404).json(
    {
        error: "Not Found",
    });
});



module.exports.handler = serverless(app);