/*
String Utility Component version 1.5

Mike Chambers

thanks to Branden Hall, Ben Glazer, Christian Cantrell, Nik Schramm
*/

/*
	This allows user to check from other include files whether or not the stringUtils
	library has been included.

	Example:

	if(!String.stringUtilsDefined)
	{
		trace("stringUtils.as not found");
	}
*/
String.prototype.constructor.stringUtilsDefined = true;
String.prototype.constructor.stringUtilsVersion = 1.5;

/**
*	This methods trims all of the white space from the left side of a String.
*/
String.prototype.ltrim = function()
{

	var size = this.length;
	for(var i = 0; i < size; i++)
	{
		if(this.charCodeAt(i) > 32)
		{
			return this.substring(i);
		}
	}
	return "";

}

/**
*	This methods trims all of the white space from the right side of a String.
*/
String.prototype.rtrim = function()
{
	var size = this.length;
	for(var i = size; i > 0; i--)
	{
		if(this.charCodeAt(i) > 32)
		{
			return this.substring(0, i + 1);
		}
	}
	return "";
}

/**
*	This methods trims all of the white space from both sides of a String.
*/
String.prototype.trim = function()
{
	return this.rtrim().ltrim();
}

/**
*	This methods returns true if the String begins with the string passed into
*	the method. Otherwise, it returns false.
*/

String.prototype.beginsWith = function(s) {
	return (s == this.substring(0, s.length));
};

/**
*	This methods returns true if the String ends with the string passed into
*	the method. Otherwise, it returns false.
*/
String.prototype.endsWith = function(s) {
	return (s == this.substring(this.length - s.length));
};




String.prototype.remove = function(remove)
{
	return this.replace(remove, "");
}

String.prototype.replace = function(replace, replaceWith)
{
	sb = new String();
 	found = false;
	for (var i = 0; i < this.length; i++)
    {
    	if(this.charAt(i) == replace.charAt(0))
        {			
        	found = true;
            for(var j = 0; j < replace.length; j++)
            {
            	if(!(this.charAt(i + j) == replace.charAt(j)))
                {
                	found = false;
                    break;
                }
			}
            if(found)
            {
            	sb += replaceWith;
                i = i + (replace.length - 1);
                continue;
            }
		}
        sb += this.charAt(i);
	}
    return sb;
}
