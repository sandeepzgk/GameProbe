/**
DESCR: Initializes the LofeltHaptics Suite
INPUT: na
RET  : the function returns true, if it successfully intialized or false if it failed to initialize.
**/

func setupHaptics() 
{

}


/**
DESCR: Check if the iOS meets minimum requirements to make sure it works.
INPUT: na
RET  : return true if it meets requirement, else return false. Important for the game engine to know that it does not qualify to use this particular device for the experiment so a error should be shown to the user. 
DOC: https://developer.lofelt.com/integrating-haptics/studio-framework-for-ios/#integrating-haptics-using-the-studio-framework-for-ios  deviceMeetsMinimumRequirements
**/
func checkDevRequirements()
{

}

/**
DESCR: Load Haptic Data and Store them for use
INPUT: (data: String)
RET  : the function returns true, if it successfully loaded the haptic data or false
**/
func loadHapticData(data: String) 
{

}



/**
DESCR: Play Haptic Data
INPUT: reference to the previously loaded haptic data
RET  : the function returns true, it success or false
**/
func playHapticData(data: !!!!TYPE to be DETERMINED) 
{

}


/**
DESCR: Play Haptic Data 
INPUT: reference to the previously loaded haptic data
RET  : the function returns true, it success or false
DOC: https://developer.lofelt.com/integrating-haptics/studio-framework-for-ios/#play-haptic-with-audio
**/
func playHapticData(data: NSString) 
{

}


///// to gcerate swift struct from JSON, use https://app.quicktype.io/




/**
DESCR: Requests and downloads the JSON config file from our server
INPUT: Requires, two parameters, one is the postURL for the server, which is available from postman (pass it as a parameter) and the experiment ID from the user form.
RET  : the function returns true, it success or false
ERROR: If the service return code is 503, try again upto 2 times before returning error message
**/
func requestJSONConfig(postURL:URL, expID:NSString) 
{

}



/**
DESCR: Requests and downloads the JSON config file from our server
INPUT: Requires, two parameters, one is the postURL for the server, which is available from postman (pass it as a parameter) and the experiment ID from the user form.
RET  : the function returns true, it success or false
ERROR: If the service return code is 503, try again upto 2 times before returning error message
DOC: previously, getConfig function, please do not use HARDCODED url, get it as a parameter
**/
func requestJSONConfig(postURL:URL, expID:NSString) 
{

}


/**
DESCR: Composes URL get parameters for hidden values to the survey url
INPUT: na
RET  : the function returns true, it success or false
DOC: previously this code was wrapped inside the init function, this is not the right place for this code.
**/
func composeGetURLParams() 
{

}

/**
DESCR: This is a loop which iterates through all the items in the "linked_files" currently 4 items, and downloads them and keeps them locally.
INPUT: na
RET  : na
DOC: previously this code was in downloadContent
**/
func downloadAssets() 
{

}








