/**
*
* 
* @author  Rory Laitila
* @description Simply proxies to a real object so that we can intercept the method calls
*
*/


component output="false" displayname=""  accessors="true" extends="" {

	property name="object";	

	public function create(required component object, required string parentName, required numeric mockDepth, required contextInfo){
		variables.object = arguments.object;
		variables.parentName = arguments.parentName;
		variables.depth = arguments.mockDepth;
		variables.cache = new mockCache();
		variables.objectName = getMetaData(variables.object).fullName;
		variables.contextInfo= arguments.contextInfo;	
		return this;
	}

	private function executeSQL(required string SQLString)
	{
		return genericQuery(arguments.SQLString);
	}

	private function genericQuery(required string SQLString){
		
		local.result = true;
		query name="local.result"{
			echo("#arguments.sqlString#");
		}
		return local.result;
	}

	public function onMissingMethod(missingMethodName, missingMethodArguments)
	{	
		
		param name="url.depth" default="0";
		writeLog(file="mock",text="#variables.depth#");
		if(url.depth IS 0){

			local.value = tryFunctionCall(argumentCollection=arguments);
		}
		else if(variables.depth LTE url.depth)
		{
			local.value = tryFunctionCall(argumentCollection=arguments);
		}
		else
		{
			writeLog(file="mock",text="Retreive Cache #variables.objectName#.#arguments.missingMethodName#");
			local.value = variables.cache.cacheGet("#variables.objectName#_#arguments.missingMethodName#");
			
			if(isBoolean(local.value) AND local.value IS false)
			{
				local.value = tryFunctionCall(argumentCollection=arguments);
			}
		}
		if(NOT isNull(local.value))
		{
			return local.value;	
		}
		
	}

	private function tryFunctionCall(missingMethodName, missingMethodArguments)
	{

		writeLog(file="mock",text="CALL #variables.objectName#.#arguments.missingMethodName#");
		try {

			

			//Look for any after function in the spec and call it if it exists
			local.spec = "";
			include template="#variables.contextInfo.specPath#";
			local.specContext = local.spec.tests[variables.contextInfo.functionName][variables.contextInfo.scenarioName];
			
			//Call any after functions for this collaborator specification
			if(structKeyExists(local.specContext,"before"))
			{
				//If the before is a function, then call it every time. Else we will check if the user has described calling it for only unit tests or collaborator tests
				if(isClosure(local.specContext.before))
				{
					local.specContext.before(variables.object);	
				}
				else if(isStruct(local.specContext.before))
				{
					if(structKeyExists(local.specContext.before,"unit") AND variables.depth IS 1)
					{
						local.specContext.before.unit(variables.object);
					}
				}
				
			}


			if(structKeyExists(local.specContext,"given") AND variables.depth IS 1)
			{
				if(isClosure(local.specContext.given))
				{
					request.given = local.specContext.given(variables.object);		
				}
				else
				{
					request.given = local.specContext.given;
				}
				local.given = request.given;
			}
			else
			{
				local.given = arguments.missingMethodArguments;
			}

			local.value = evaluate("variables.object.#arguments.missingMethodName#(argumentCollection=local.given)");

			// if(arguments.missingMethodName IS NOT variables.contextInfo.functionName)
			// {
			// 	return local.value;
			// }

			if(NOT isNull(local.value))
			{
				variables.cache.cachePut(local.value,"#variables.objectName#_#arguments.missingMethodName#");	
			}

			//Call any assert statements for this specification
			if(structKeyExists(local.specContext,"then") AND structKeyExists(local.specContext.then,"assert"))
			{	

				local.asserts = local.specContext.then.assert;
				for(assert in asserts)
				{
					if(isSimpleValue(assert))
					{

					}
					else if(isStruct(assert))
					{

						if(isClosure(assert.value))
						{
							local.result = assert.value(local.value,variables.object);
							if(local.result IS false)
							{
								throw(message="#assert.message#");
							}
						}	
					}
					
				}
			}

			//Call any after functions for this collaborator specification
			if(structKeyExists(local.specContext,"after"))
			{
				//If the after is a function, then call it every time. Else we will check if the user has described calling it for only unit tests or collaborator tests
				if(isClosure(local.specContext.after))
				{
					local.specContext.after(variables.object);	
				}
				else if(isStruct(local.specContext.after))
				{
					if(structKeyExists(local.specContext.after,"unit") AND variables.depth IS 1)
					{
						local.specContext.after.unit(variables.object);
					}
				}
			}

			
			
		}
		catch(any e) {
			local.name = getMetaData(variables.object).fullName;
			writeLog(file="mock",text="There was an error in the collaborator #local.name#, parent was #variables.parentName#");
			if(e.message CONTAINS "There was an error in the collaborator")
			{
				rethrow;
				
			} else
			{
				local.name = getMetaData(variables.object).fullName;
				if(variables.parentName IS "root")
				{
					e.message = e.message;
				}
				else{
					e.message = "There was an error in the collaborator #local.name#, parent was #variables.parentName#. Message Is: " & e.message;
				}
				
				throw(e);
			}
			
			
		}
		if(NOT isNull(local.value))
		{
			return local.value;	
		}
		
	}
}