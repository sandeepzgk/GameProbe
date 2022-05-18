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
const debug = True;

String.prototype.hashCode = function()
{
    var hash = 0;
    for (var i = 0; i < this.length; i++)
    {
        var code = this.charCodeAt(i);
        hash = ((hash << 5) - hash) + code;
        hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
}

const dynamoDbClient = new AWS.DynamoDB.DocumentClient();

function log(str)
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
    var v = new Validator();
    var validation_result = v.validate(instance, db_schema);
    if (validation_result.valid)
    {
        log("Validation Success");
        try
        {
            var hashed = false;
            while (!hashed)
            {
                var email = req.body.email;
                email = email.substr(0, email.length < 4 ? email.length : 4);
                var time = String(Date.now());
                time = time.substring(time.length - 4);
                var uid = (email + time).hashCode();
                log("Computed UUID:" + uid);
                //Check if the generated uid is genuinely uuid (i.e not exisiting in the database)
                const getParams = {
                    TableName: DATA_TABLE,
                    FilterExpression: "email = :email and uuid = :uid",
                    ExpressionAttributeValues:
                    {
                        ":email": req.body.email,
                        ":uuid": uid
                    }
                };

                var putParams;
                const Item = await dynamoDbClient.scan(getParams).promise().then(
                    getData =>
                    {
                        if (getData.Count == 0)
                        {

                            instance.uuid = String(uid);
                            hashed = true;
                            putParams = {
                                TableName: DATA_TABLE,
                                Item: instance,
                            };
                        }
                    }
                );
            }
            await s3.upload(
            {
                Bucket: STORAGE_BUCKET,
                Key: String(hash) + "/long",
                Body: instance.haptic_setup[0].linked_files.long_effect
            }).promise();

            await s3.upload(
            {
                Bucket: STORAGE_BUCKET,
                Key: String(hash) + "/short",
                Body: instance.haptic_setup[0].linked_files.short_effect
            }).promise();


            await dynamoDbClient.put(params).promise();
            res.status(200);
        }
        catch (error)
        {
            console.log(error)
            res.status(500).json(
            {
                error: "Could not create user"
            });
        }
    }
    else
    {
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
        FilterExpression: "uuid = :uuid ",
        ExpressionAttributeValues:
        {
            ":uuid": req.body.uuid
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
            console.log(err)
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