/**
*
* 
* @author  Rory Laitila
* @description Utility object to get the type of a variable based on coldfusion datatypes
*
*/

component {

	public function init(required variable){

		if(isStruct(arguments.variable))
		{
			return "struct";
		}
		if(isArray(arguments.variable))
		{
			return "array";
		}
		if(isNumeric(arguments.variable))
		{
			return "numeric";
		}
		if(isObject(arguments.variable))
		{
			return "object";
		}
		if(isBoolean(arguments.variable))
		{
			return "boolean";
		}
		if(isSimpleValue(arguments.variable))
		{
			return "string";
		}
		if(isDate(arguments.variable))
		{
			return "date";
		}
		if(isQuery(arguments.variable))
		{
			return "query";
		}
		if(isJson(arguments.variable))
		{
			return "json";
		}
		if(isXML(arguments.variable))
		{
			return "xml";
		}
		if(isBinary(arguments.variable))
		{
			return "binary";
		}
		if(isClosure(arguments.variable))
		{
			return "closure";
		}
		if(isCustomFunction(arguments.variable))
		{
			return "customFunction";
		}
		if(isImage(arguments.variable))
		{
			return "image";
		}
		return false;
	}
}