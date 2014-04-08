/**
*
* 
* @author  Rory Laitila
* @description Utility object to get the type of a variable based on coldfusion datatypes
*
*/

component {

	public function init(required variable){

		//Object needs to come before struct because objects will evaluate to structs also
		if(isObject(arguments.variable))
		{
			return "object";
		}
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

	public function onMissingMethod(missingMethodName, missingMethodArguments)
	{
		return evaluate("get#arguments.missingMethodName#(data=arguments.missingMethodArguments[1])");
	}

	public function getIsImage(required data)
	{
		return isImage(arguments.data);
	}

	public function getIsCustomFunction(required data)
	{
		return isCustomFunction(arguments.data);
	}

	public function getIsClosure(required data)
	{
		return isClosure(arguments.data);
	}

	public function getIsBinary(required data)
	{
		return isBinary(arguments.data);
	}

	public function getIsJson(required data)
	{
		return isJson(arguments.data);
	}

	public function getIsDate(required data)
	{
		return isDate(arguments.data);
	}

	public function getIsString(required data)
	{
		return isSimpleValue(arguments.data);
	}

	public function getIsNumeric(required data)
	{
		return isNumeric(arguments.data);
	}

	public function getIsArray(required data)
	{
		return isArray(arguments.data);
	}

	public function getIsStruct(required data)
	{
		return isStruct(arguments.data);
	}

	public function getIsObject(required data)
	{			
		return isObject(arguments.data);
	}

	public function getIsBoolean(required data)
	{			
		return isBoolean(arguments.data);
	}

	public function getIsQuery(required data)
	{			
		return isQuery(arguments.data);
	}

	public function getIsXML(required data)
	{
		return isXML(arguments.data);
	}
}
