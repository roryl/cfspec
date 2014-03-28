/**
*
* 
* @author  Rory Laitila
* @description Simply proxies to a real object so that we can intercept the method calls
*
*/


component output="false" displayname=""  accessors="true" extends="" {

	property name="object";	
	property name="parentName";
	property name="depth";
	property name="cache";
	property name="objectName";
	property name="contextInfo";
	property name="mockContexts";

	public function create(required component object, required string parentName, required numeric mockDepth){
		variables.object = arguments.object;
		variables.parentName = arguments.parentName;
		variables.depth = arguments.mockDepth;
		variables.cache = new mockCache();
		variables.objectName = getMetaData(variables.object).fullName;
		variables.contextInfo = arguments.contextInfo;	
		variables.mockContexts = {};
		return this;
	}

	public function addMockContext(required functionName, required scope, required contextInfo)
	{
		variables.mockContexts[arguments.functionName] = {
			scope:arguments.type,
			contextInfo:arguments.contextInfo
		};
	}

	private function getContextByName(string functionName)
	{

	}

	private function executeSQL(required string SQLString, datasource="")
	{
		return genericQuery(arguments.SQLString,arguments.datasource);
	}

	private function genericQuery(required string SQLString, datasource){		
		
		local.result = true;
		if(structKeyExists(arguments,"datasource") AND trim(arguments.datasource) IS NOT "")
		{
			query name="local.result" datasource="#arguments.datasource#"{
				echo("#arguments.sqlString#");
			}
		}
		else
		{
			query name="local.result"{
				echo("#arguments.sqlString#");
			}
		}		
		return local.result;
	}

	public function getCallCount(required string functionName)
	{
		local.count = 0;
		local.calls = callStackGet();
		for(local.call in local.calls)
		{
			if(compareNoCase(local.call.function,arguments.functionName))
			{
				local.count = local.count + 1;
			}
		}
		return local.count;
	}

	public function isEntity(required entity)
	{	
		local.meta = getMetaData(arguments.entity);
		if(structKeyExists(meta,"persistent") AND meta.persistent AND isObject(arguments.entity))
		{
			return true;
		}
		else
		{
			return false;
		}		
	}

	private function assert(value=true,message=""){

		if(arguments.value IS false)
		{			
			local.call = callStackGet()[2]
		
			local.specFile = fileOpen(local.call.template);
			
			local.readCount = 0;
			while(!fileIsEOF(local.specFile))
			{
				local.readCount = local.readCount + 1;
				local.code = fileReadLine(local.specFile);
				
				if(local.readCount IS local.call.lineNumber)
				{
					local.code = replace(local.code,"assert(","","all");
					local.code = left(local.code,len(local.code) -1);
					throw("Assertion failed <br /> Message Was:#arguments.message# <br />Called from: #local.call.template# <br />Line: #local.readCount# <br /> Asserted: #trim(local.code)#");
				}
			}
			
		}
	}

	private function countFunctionCall(required string functionName){
		

		if(NOT structKeyExists(request.funcCount,arguments.functionName))
		{
			request.funcCounts.insert(arguments.functionName,0);
		}
		request.funcCounts[arguments.functionName] = request.funcCounts[arguments.functionName] + 1
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
			local.specTest = local.spec.tests[variables.contextInfo.functionName];
			local.specContext = local.spec.tests[variables.contextInfo.functionName][variables.contextInfo.scenarioName];
			
			/*Set each of the levels of tests into an arry. We will use this to loop over each level, checking 
			for the existense of the function
			*/
			local.specLevels = [local.spec.tests, //This is the "tests" level and applys to all tests + scenarios
								  local.specTest,  //This is the individual test level and applies to all scenarios within the test
								  local.specContext]; //This is a scenario specific level and only applies to this scenario


			/*
			BEFORE functions
			
			For each of the levels, check if the before function exists. If it does, we call it
			*/
			for(local.beforeCheck in local.specLevels)
			{
				//Call any after functions for this collaborator specification
				if(structKeyExists(local.beforeCheck,"before"))
				{
					//If the before is a function, then call it every time. Else we will check if the user has described calling it for only unit tests or collaborator tests
					if(isClosure(local.beforeCheck.before))
					{
						local.beforeCheck.before(variables.object);	
					}
					else if(isStruct(local.beforeCheck.before))
					{
						if(structKeyExists(local.beforeCheck.before,"unit") AND variables.depth IS 1)
						{
							local.beforeCheck.before.unit(variables.object);
						}
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

			//If we got to this point, then the call worked, so check if the specification expected and error and if so, throw that error. 
			if(structKeyExists(local.specContext,"then") AND structKeyExists(local.specContext.then,"throws"))
			{
				throw("The specification expected an error but did not receive one. The specification exptected the error to contain: ""#local.specContext.then.throws#""");
			}
			

			if(NOT isNull(local.value))
			{
				request.testResult = local.value;	
			}						

			if(NOT isNull(local.value))
			{
				variables.cache.cachePut(local.value,"#variables.objectName#_#arguments.missingMethodName#");	
			}

			//Call any assert statements for this specification
			if(structKeyExists(local.specContext,"then") AND structKeyExists(local.specContext.then,"assert"))
			{	

				local.asserts = local.specContext.then.assert;
				if(isClosure(local.asserts))
				{
					local.result = local.asserts(((isNull(local.value))?"NULL":local.value),variables.object);

					if(NOT isDefined('local.result'))
					{
						throw("Your test assertion must return either true for success or false for a failure");
					}

					if(local.result IS false)
					{
						throw(message="The assertion failed");
					}
				}
				else if(isArray(local.asserts))
				{
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
			}

			for(local.afterCheck in local.specLevels)
			{
				if(structKeyExists(local.afterCheck,"after"))
				{

					//If the after is a function, then call it every time. Else we will check if the user has described calling it for only unit tests or collaborator tests
					if(isClosure(local.afterCheck.after))
					{
						afterMeta = getMetaData(local.afterCheck.after);
						args = {}
						for(param in afterMeta.parameters)
						{
							if(param.name IS "result") { args.result = local.value }
							if(param.name IS "object") { args.object = variables.object }
						}

						local.afterCheck.after(argumentCollection=args);
					}
					else if(isStruct(local.afterCheck.after))
					{
						if(structKeyExists(local.afterCheck.after,"unit") AND variables.depth IS 1)
						{
							local.afterCheck.after.unit(variables.object);
						}
					}
				}

			}
			
		}
		catch(any e) {
			local.name = getMetaData(variables.object).fullName;
			writeLog(file="mock",text="There was an error in the collaborator #local.name#, parent was #variables.parentName#");

			if(structKeyExists(local.specContext,"then") AND structKeyExists(local.specContext.then,"throws") AND e.message CONTAINS local.specContext.then.throws)
			{
				return true;
			}
			else if(structKeyExists(local.specContext,"then") AND structKeyExists(local.specContext.then,"throws"))
			{
				throw("The specification expected an error but the error returned was not of the correct text. The error returned was: ""#e.message#"" <br />");
			}

			if(structKeyExists(local.specContext,"onError") AND isClosure(local.specContext.onError))
			{
				local.specContext.onError();				
			}	

			//Call any after functions for this collaborator specification
			if(structKeyExists(local.specContext,"then") AND local.specContext.then.returns IS "isError")
			{
				return true;
			}
			else
			{
				if(e.message CONTAINS "There was an error in the collaborator")
				{					
					rethrow;					
				} 
				else
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
		}

		if(NOT isNull(local.value))
		{
			return local.value;	
		}
		
	}
}