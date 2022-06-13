const AWS = require("aws-sdk");
const Validator = require("jsonschema").Validator;
const express = require("express");
const serverless = require("serverless-http");
const cors = require("cors");
AWS.config.update(
{
    region: process.env.REGION
});
const db_schema = require("./client/dist/assets/formschema.json"); /// <--- reference to the original form schema that works for both the webpage and the server side validation
const app = express();
const DATA_TABLE = process.env.DATA_TABLE;
const STORAGE_BUCKET = process.env.STORAGE_BUCKET;
const s3 = new AWS.S3();
const debug = true;
const signedUrlExpireSeconds = 60 * 5; //Link Expires in 5 minutes

const dynamoDbClient = new AWS.DynamoDB.DocumentClient();

function debuglog(str)
{
    if (debug)
    {
        console.log(str);
    }
}


app.use(express.json({ limit: '20MB' })); //To enable larger file upload upto 20M
app.use(cors());
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
                if(instance.linked_files[Object.keys(instance.linked_files)[i]]!="") //Only upload files that have values.
                {
                    var fileData = instance.linked_files[Object.keys(instance.linked_files)[i]].split(";")[2]; //extracting the last part of the upload , i.e. in the above example "base64,dHdvdHdvdHdv"
                    var fileBody = Buffer.from(fileData.split(",")[1], 'base64'); // converting fileData after splitting the base64 header to binary object for s3 upload
                    await s3.upload(
                        {
                            Bucket: STORAGE_BUCKET,
                            Key: s3Key ,
                            ContentEncoding: 'base64',
                            Body: fileBody
                        }).promise()
                        .then(function(data) 
                        {
                            debuglog("Successfully Upload s3");
                            debuglog(JSON.stringify(data));
                            instance.linked_files[Object.keys(instance.linked_files)[i]] = "true"; // Updating the string for the database to know if a file exists for that key, else its blank.
                        })
                        .catch(function(err) 
                        {
                            debuglog("Failed Upload s3");
                            debuglog(JSON.stringify(err));
                        });
                }

            }

            debuglog("Put Parameters to DB :");
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
                    debuglog("Data Count: "+ data.Count)
                    for(var i = 0; i < data.Count; i++)
                    {
                        //get signed urls for links       
                        debuglog("Outerloop");
                        debuglog(JSON.stringify(data.Items[i]));
                        debuglog(JSON.stringify(data.Items[i].linked_files));
                        debuglog(JSON.stringify(Object.keys(data.Items[i].linked_files)));
                        var allJSONKeys =   Object.keys(data.Items[i].linked_files);              
                        debuglog("all JSON Keys Length:  "+allJSONKeys.length);
                        for (var j=0; j<allJSONKeys.length; j++)
                        {
                            var jsonKey = allJSONKeys[j];
                            debuglog("JSONKey: "+ jsonKey);
                            var currentLinkedFile = data.Items[i].linked_files[jsonKey];
                            
                            if(currentLinkedFile == "true")
                            {
                              var fileKey = data.Items[i].expid+"/"+jsonKey;
                              if(fileKey.includes("audio"))
                                var signedURL = s3.getSignedUrl('getObject', {Bucket: STORAGE_BUCKET,Key: fileKey,Expires: signedUrlExpireSeconds, ResponseContentType: "audio/wav", ResponseContentDisposition: 'attachment; filename ="' + fileKey + '.wav"'});
                              else
                              var signedURL = s3.getSignedUrl('getObject', {Bucket: STORAGE_BUCKET,Key: fileKey,Expires: signedUrlExpireSeconds});
                              debuglog("Signed URL: " + signedURL);
                              data.Items[i].linked_files[jsonKey] = signedURL;
                            }
                        }
                    }
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
    catch (err)
    {
        console.log(err)
        res.status(500).json(
        {
            error: "Could not retreive user",
            errorString: err
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
            ":expid": req.body.expid.toString().toUpperCase()
        }
    }

    try
    {
        const Item = await dynamoDbClient.scan(getParams).promise().then(
            data =>
            {
                if (data.Count > 0)
                {
                    debuglog("Data Count: "+ data.Count)
                    for(var i = 0; i < data.Count; i++)
                    {
                        //get signed urls for links       
                        debuglog("Outerloop");
                        debuglog(JSON.stringify(data.Items[i]));
                        debuglog(JSON.stringify(data.Items[i].linked_files));
                        debuglog(JSON.stringify(Object.keys(data.Items[i].linked_files)));
                        var allJSONKeys =   Object.keys(data.Items[i].linked_files);              
                        debuglog("all JSON Keys Length:  "+allJSONKeys.length);
                        for (var j=0; j<allJSONKeys.length; j++)
                        {
                            var jsonKey = allJSONKeys[j];
                            debuglog("JSONKey: "+ jsonKey);
                            var currentLinkedFile = data.Items[i].linked_files[jsonKey];
                            if(currentLinkedFile == "true")
                            {
                              var fileKey = data.Items[i].expid+"/"+jsonKey;
                              if(fileKey.includes("audio"))
                              var signedURL = s3.getSignedUrl('getObject', {Bucket: STORAGE_BUCKET,Key: fileKey,Expires: signedUrlExpireSeconds, ResponseContentType: "audio/wav", ResponseContentDisposition: 'attachment; filename ="' + fileKey + '.wav"'});
                              else
                                var signedURL = s3.getSignedUrl('getObject', {Bucket: STORAGE_BUCKET,Key: fileKey,Expires: signedUrlExpireSeconds});
                              debuglog("Signed URL: " + signedURL);
                              data.Items[i].linked_files[jsonKey] = signedURL;
                            }
                        }
                    }
                    res.json(data.Items);
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
    catch (err)
    {
        res.status(500).json(
        {
            error: "Could not retreive experiment",
            errorString: err
        });
    }
});


app.use((req, res, next) =>
{
    return res.status(404).json(
    {
        error: "Not Found",
    });
});



module.exports.handler = serverless(app);