const lambdaServer = {
    serverURLs: {
        dev: "https://t8fqmzvdd7.execute-api.us-east-1.amazonaws.com",
        prod: "https://3s636biw5i.execute-api.us-east-1.amazonaws.com"
    },
    get server() 
    {
        if (window.location.hostname.indexOf("dev") > 0)
            return this.serverURLs["dev"]
        else if (window.location.hostname.indexOf("prod") > 0)
            return this.serverURLs["prod"]
        else
            return this.serverURLs["prod"]          //default to production environment
    }
};
