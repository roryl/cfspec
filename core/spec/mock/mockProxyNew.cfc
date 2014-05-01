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

	public function create(required component object, 
						   required string parentName, 
						   required numeric mockDepth, 
						   required contextInfo){
		variables.object = arguments.object;
		variables.parentName = arguments.parentName;
		variables.depth = arguments.mockDepth;
		variables.cache = new mockCache();
		variables.objectName = getMetaData(variables.object).fullName;
		variables.contextInfo = arguments.contextInfo;	
		variables.mockContexts = {};
		addMockContext(arguments.contextInfo);
		return this;
	}

	public function addMockContext(required contextInfo)
	{
		if(structKeyExists(variables.mockContexts,arguments.contextInfo.functionName))
		{
			throw("Mocking out the same function twice is not currently supported. Ensure that there is only one mock for this function. The function you tried to mock was #arguments.contextInfo.functionName#");
		}
		else
		{
			variables.mockContexts[arguments.contextInfo.functionName] = {			
				contextInfo:arguments.contextInfo
			};	
		}
		
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

	/**
	* doGiven checks and runs the given clause from the specification. Currently only a scenario 
	* can contain the given clause
	*/
	private function doGiven(required specContext, required mockDepth, required missingMethodArguments){

		if(structKeyExists(arguments.specContext,"given") AND arguments.mockDepth IS 1)
		{
			if(isClosure(arguments.specContext.given))
			{
				request.given = arguments.specContext.given(variables.object);		
			}
			else
			{
				request.given = arguments.specContext.given;
			}
			local.given = request.given;
		}
		else
		{

			local.given = arguments.missingMethodArguments;
		}
		return local.given;
	}

	/**
	* doBefore checks and runs the before clauses from the specification. 
	*/
	private function doBefore(required specLevels)
	{
		/*
		BEFORE functions
		
		For each of the levels, check if the before function exists. If it does, we call it
		*/
		for(local.beforeCheck in arguments.specLevels)
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
	}

	/**
	* doAsserts checks and runs the assert clauses from the specification. 
	*/
	private function doAsserts(required specContext, result, required objectUnderTest)
	{
		//Call any assert statements for this specification
		if(structKeyExists(arguments.specContext,"then") AND structKeyExists(arguments.specContext.then,"assert"))
		{	
			local.asserts = arguments.specContext.then.assert;
			if(isClosure(local.asserts))
			{
				local.result = local.asserts(((isNull(arguments.result))?"NULL":arguments.result),arguments.objectUnderTest);

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
					if(isStruct(assert))
					{
						if(isClosure(assert.value))
						{
							local.result = assert.value(arguments.result,arguments.objectUnderTest);

							if(NOT isDefined('local.result'))
							{
								throw("Your test assertion must return either true for success or false for a failure");
							}

							if(local.result IS false)
							{
								throw(message="#assert.message#");
							}
						}	
					}									
				}
			}
		}
	}

	/**
	* doAfter calls any acter clauses in any of the spec levels, in the following order: 
	* All Tests > Test Level > Scenario Level
	*/
	private function doAfter(required specLevels, result, required objectUnderTest, required depth){

		for(local.afterCheck in arguments.specLevels)
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
						if(param.name IS "result" AND isDefined('arguments.result')) { args.result = arguments.result }
						if(param.name IS "object") { args.object = arguments.objectUnderTest }
					}

					local.afterCheck.after(argumentCollection=args);
				}
				else if(isStruct(local.afterCheck.after))
				{
					if(structKeyExists(local.afterCheck.after,"unit") AND arguments.depth IS 1)
					{
						local.afterCheck.after.unit(variables.object);
					}
				}
			}

		}
	}

	private function doError(required error, required specContext, expectedError=false)
	{
		local.name = getMetaData(variables.object).fullName;
		writeLog(file="mock",text="There was an error in the collaborator #local.name#, parent was #variables.parentName#");

		if(structKeyExists(arguments.specContext,"onError") AND isClosure(arguments.specContext.onError))
		{
			arguments.specContext.onError();				
		}		

		if(arguments.expectedError)
		{
			throw(error.message);
		}

		if(structKeyExists(arguments.specContext,"then") AND structKeyExists(arguments.specContext.then,"throws") AND arguments.error.message CONTAINS arguments.specContext.then.throws)
		{

			return true;
		}
		else if(structKeyExists(arguments.specContext,"then") AND structKeyExists(arguments.specContext.then,"throws"))
		{
			throw("The specification expected an error but the error returned was not of the correct text. The error returned was: ""#arguments.error.message#"" <br />");
		}		

		//Call any after functions for this collaborator specification
		if(structKeyExists(arguments.specContext,"then") AND arguments.specContext.then.returns IS "isError")
		{
			return true;
		}
		else
		{
			if(arguments.error.message CONTAINS "There was an error in the collaborator")
			{					
				//rethrow;					
			} 
			else
			{					
				arguments.name = getMetaData(variables.object).fullName;
				if(variables.parentName IS "root")
				{
					arguments.error.message = arguments.error.message;
				}
				else{						
					arguments.error.message = "There was an error in the collaborator #arguments.name#, parent was #variables.parentName#. Message Is: " & arguments.error.message;						
				}					
				throw(error);
			}
		}	
	}

	private function tryFunctionCall(missingMethodName, missingMethodArguments)
	{

		writeLog(file="mock",text="CALL #variables.objectName#.#arguments.missingMethodName#");

		//Look for any after function in the spec and call it if it exists
		local.spec = "";
		if(NOT structKeyExists(variables.mockContexts,"#arguments.missingMethodName#"))
		{
			//This method is not mocked, so just call it and return the result
			try{
				return evaluate("variables.object.#arguments.missingMethodName#(argumentCollection=missingMethodArguments)");
			}
			catch(any e)
			{
				rethrow;
			}
		}

		try {

			include template="#variables.mockContexts[missingMethodName].contextInfo.specPath#";

			local.specTest = local.spec.tests[variables.contextInfo.functionName];
			local.specContext = local.spec.tests[variables.contextInfo.functionName][variables.contextInfo.scenarioName];
			
			/*Set each of the levels of tests into an arry. We will use this to loop over each level, checking 
			for the existense of the function. These will be passed to doBefore and doAfter
			*/
			local.specLevels = [local.spec.tests, //This is the "tests" level and applys to all tests + scenarios
								  local.specTest,  //This is the individual test level and applies to all scenarios within the test
								  local.specContext]; //This is a scenario specific level and only applies to this scenario


			doBefore(local.specLevels);
			

			//Obtain the arguments to be passed into the function
			local.given = doGiven(local.specContext,
								  variables.depth,
								  arguments.missingMethodArguments);
			//writeDump("variables.object.#arguments.missingMethodName#(argumentCollection=local.given)");
			// writeDump(variables.object.onStartTag(variables,{test="test"}));
			// abort;
			if(structIsEmpty(local.given))
			{
				
				//Pass the arguments into the method being called under test			
				local.value = evaluate("variables.object.#arguments.missingMethodName#()");
			}
			else
			{
				//Pass the arguments into the method being called under test			
				local.value = evaluate("variables.object.#arguments.missingMethodName#(argumentCollection=local.given)");
			}
				

			//If we got to this point, then the call worked, so check if the specification expected and error and if so, throw that error. 
			if(structKeyExists(local.specContext,"then") AND structKeyExists(local.specContext.then,"throws"))
			{				
				local.error.message = "The specification expected an error but did not receive one. The specification exptected the error to contain: ""#local.specContext.then.throws#""";
				doError(local.error, local.specContext, true);
			}			


			if(NOT isNull(local.value))
			{
				//set request.testResult to the local value. This is a deprecated function and is no longer how we generally assert values
				request.testResult = local.value;

				//Save the value to the cache so that if this method is called again, the value can be retreived from the cache
				variables.cache.cachePut(local.value,"#variables.objectName#_#arguments.missingMethodName#");	
			}	


			local.doAssertsArgs = {
				specContext:local.specContext,
				objectUnderTest:variables.object,								
			}

			if(NOT isNull(local.value))
			{
				local.doAssertsArgs.result = local.value;
			}					

			doAsserts(argumentCollection=doAssertsArgs);

			/*doAfter arguments 
			Set the arguments into a collection. Then we need to check if the value was null, and if it was not, then we can
			pass it. 
			*/
			local.doAfterArgs = {
				specLevels:local.specLevels,
				objectUnderTest:variables.object,
				depth:variables.depth				
			}

			if(NOT isNull(local.value))
			{
				local.doAfterArgs.result = local.value;
			}

			doAfter(argumentCollection=local.doAfterArgs);			
			
		}
		catch(any e) {
			doError(e,local.specContext);
		}

		if(NOT isNull(local.value))
		{
			return local.value;	
		}
		
	}
}