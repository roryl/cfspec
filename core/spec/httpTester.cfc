/**
*
* @author  Rory Laitila
* @description Tests a HTTP specification
*
*/
import cfspec.libraries.queryString.queryString;
component accessors="true"{

	property name="spec";
	property name="method";
	property name="Host";
	property name="Resource";
	property name="afterTests";
	property name="lastGiven";
	property name="httpResponse";

	public function init(required string specPath, required string method, required string scenario, required string resource, any patch={}, hasParentTest=false){

		//Load the spec path into this variables scope. It is neceessary that the spec be included here so that any function calls from within the spec are in the scope of this object
		variables.specPath = arguments.specPath;
		variables.spec = "";
		include template="#variables.specPath#";
		
		variables.method = arguments.method;		
		variables.resource = arguments.resource;
		variables.scenario = arguments.scenario;

		//The spec variables can be overwritten by an import, but the originals need to be use in the URI in the http call, so we need to 
		//keep a reference to them
		variables.originalUrl = variables.spec.url;		
		variables.originalResource = variables.resource;

		variables.hasParentTest = arguments.hasParentTest;
		variables.afterTestsCalls = [];

		//Now we check if the spec we are using is actually an import of another spec. If it is, we're going to replace the values
		//set above with the imported spec
		if(structKeyExists(variables.spec.tests["#variables.resource#"]["#variables.method#"]["#variables.scenario#"],"import"))
		{	
			//Copy the original spec path so that we can compare it;	
			variables.originalSpecPath = variables.specPath;
			variables.originalResource = variables.resource;
			variables.originalScenario = variables.scenario;
			variables.originalMethod = variables.method;

			//After having looped through and replaced all references, we need to do a patch if any
			if(structKeyExists(variables.spec.tests["#variables.resource#"]["#variables.method#"]["#variables.scenario#"],"patch"))
			{
				local.patchReference = variables.spec.tests["#variables.resource#"]["#variables.method#"]["#variables.scenario#"].patch;				
			}

			//Override any of the keys for the import with what were set in this object
			for(local.key in variables.spec.tests["#variables.originalResource#"]["#variables.originalMethod#"]["#variables.originalScenario#"].import)
			{
				variables[local.key] = variables.spec.tests["#variables.originalResource#"]["#variables.originalMethod#"]["#variables.originalScenario#"].import[local.key];				
			}			

			//If the import defines a spec path, then we need to reload the spec file path which will be overridden
			if(variables.specPath IS NOT variables.originalSpecPath)
			{
				include template="#variables.specPath#";
			}

			//After having looped through and replaced all references, we need to do a patch if any
			if(structKeyExists(local,"patchReference"))
			{
				patchSpec(local.patchReference);
			}
		}

		//Patch a spec normally if it is passed into the constructor
		if(structKeyExists(arguments,"patch") AND NOT structIsEmpty(arguments.patch))
		{
			patchSpec(arguments.patch);
		}

		return this;
	}

	private function doLog(string text){
		writeLog(file="cfspec", text=arguments.text);
	}

	private function patchSpec(required any patch){

		//If the patch is a function, then we need to look at what data is being requested to be 
		//patched and we will pass a reference to that into the function
		if(isClosure(arguments.patch))
		{
			local.funcMeta = getMetaData(arguments.patch);
			local.args = {}
			for(local.param in local.funcMeta.parameters)
			{
				if (local.param.name IS "given")
				{
					local.args.given = variables.spec.tests["#variables.resource#"]["#variables.method#"]["#variables.scenario#"].given;
				}							
			}		

			arguments.patch(argumentCollection=local.args);
		}

		if(isStruct(arguments.patch))
		{
			for(local.key in arguments.patch)
			{
				local.keyRef = "[""" & replace(key,".","""][""","all") & """]";			
				evaluate('variables.spec["tests"]["#variables.resource#"]["#variables.method#"]["#variables.scenario#"]#local.keyRef# = arguments.patch[local.key]');
			}
		}		
	}

	public function runHTTPSpec(specPath, method, scenario, resource, patch={}){		

		//Set default values to be the same spec that was already defined here
		local.args = {
			specPath:variables.specPath,
			method:variables.method,
			scenario:variables.scenario,
			resource:variables.resource			
		}
		
		//Override any variables from the arguments that were passed in
		for(local.key in arguments)
		{
			if(NOT isNull(arguments[key]))
			{
				local.args[key] = arguments[key];
			}			
		}

		local.args.hasParentTest = true;
		
		local.httpTester = new httpTester(argumentCollection=local.args);

		local.result = local.httpTester.doHTTPCall();

		local.afterTestsCalls = local.httpTester.getAfterTestsCalls();

		//copy the after tests into the after tests of this object
		for(local.afterTest in local.afterTestsCalls)
		{
			variables.afterTestsCalls.append(local.afterTest);	
		}		

		return local.httpTester;
	}

	public function getCookiesAsStruct(required cookiesData)
	{
		//Old code based on Railo 4.2 cookies as a query
		// local.result = {};
		// for(row in arguments.cookiesData)
		// {
		// 	local.result[row.name] = row;
		// }

		if(isArray(arguments.cookiesData))
		{
			local.result = {};
			for(local.cookieItem in arguments.cookiesData)
			{
				//Get the first list element from the cookie
				local.cookieString = trim(listFirst(local.cookieItem,";"));

				//Extract the name
				local.cookieName = trim(listFirst(local.cookieString,"="));
				
				//Extract the value
				local.cookieValue = trim(listLast(local.cookieString,"="));
				
				//Set the name and the value into the response
				local.result[local.cookieName].value = local.cookieValue;
			}
		}	

		return local.result;
	}

	public function dumpAbort(required variable)
	{
		writeDump(arguments.variable);
		abort;
	}

	public function doHTTPCall()
	{
		
		doLog("Start doHTTPCall");

		//We use the originalUrl and the originalResource because we want to ensure that we are using the endpoint from the parent spec
		local.URI = variables.originalUrl & variables.originalResource;
		
		local.context = variables.spec.tests[variables.resource][variables.method][variables.scenario];

		local.specLevels = [
			variables.spec.tests,
			variables.spec.tests[variables.resource],
			variables.spec.tests[variables.resource][variables.method],
			variables.spec.tests[variables.resource][variables.method][variables.scenario]
		];

		doBefore(local.specLevels);

		//The given function can override placeholders in the URL given for the test
		if(structKeyExists(local.context,"given"))
		{
			//Set the given into a variable that can be passed to the assert function
			variables.lastGiven = local.context.given;

			local.given = getOrCallValue(local.context.given);

			request.given = local.given;

			if(structKeyExists(local.given,"path"))
			{

				local.path = getOrCallValue(local.given.path);
				variables.lastGiven.path = local.path;
				//For each of the path items, replace the variable requested with the value
				for(local.item IN local.path)
				{
					local.value = getOrCallValue(local.path[local.item]);	
					variables.lastGiven.path[local.item] = local.value;				
					local.uri = replaceNoCase(local.uri, "{#local.item#}", local.value);
				}
			}
		}

		doLog(local.uri);

		http url="http://#local.uri#" method="#variables.method#" result="local.cfhttp" {

			if(structKeyExists(local.context,"given"))
			{

				if(isClosure(local.context.given))
				{
					local.context.given = local.context.given();
				}

				if(structKeyExists(local.context.given,"url"))
				{

					local.urlFields = getOrCallValue(local.context.given.url);

					for(local.field IN local.urlFields)
					{
						local.value = getOrCallValue(local.urlFields[local.field]);
						variables.lastGiven.url[local.field] = local.value;
						httpparam type="url" name="#local.field#" value="#local.value#";
					}
				}

				if(structKeyExists(local.context.given,"body"))
				{
					local.value = getOrCallValue(local.context.given.body);
					variables.lastGiven.body = lastValue;
					httpparam type="body" value="#local.value#";
				}

				if(variables.method IS "put")				
				{
					if(structKeyExists(local.context.given,"formfields"))
					{
						local.fieldString = "";
						for(local.field in local.context.given.formfields)
						{
							local.fieldString &= "#local.field#=#urlEncode(local.context.given.formfields[local.field])#&";
						}
						
						httpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded; charset=UTF-8";
						httpparam type="body" value="#local.fieldString#";
					}
					
				}
				else{
					if(structKeyExists(local.context.given,"formfields"))
					{
						for(local.field IN local.context.given.formfields)
						{
							local.value = getOrCallValue(local.context.given.formfields[local.field]);
							variables.lastGiven.formFields[local.field] = local.value
							httpparam type="formfield" name="#local.field#" value="#local.value#";	
						}
						
					}
				}				

				if(structKeyExists(local.context.given,"cookies"))
				{
					local.cookies = getOrCallValue(local.context.given.cookies);
					variables.lastGiven.cookies = [];
					for(local.cookie IN local.cookies)
					{

						local.value = getOrCallValue(local.cookie.value);
						variables.lastGiven.cookies.append({name:local.cookie.name, value:local.value});						
						httpparam type="cookie" name="#local.cookie.name#" value="#local.value#";	
					}
					
				}
			}
			doLog("Start actual HTTPCall");
		}
		doLog("End actual HTTPCall");
		request.httpTesterResponse = local.cfhttp;
		variables.httpResponse = local.cfhttp;

		doAssertReturns(local.cfhttp.fileContent, local.context.then.returns);

		//Do all of the standard HTTP response checks (for mime type, response code, etc)
		doAssertStandardHTTPResponses(local.cfhttp, local.context);
		
		doAsserts(local.context, local.cfhttp);

		doAfter(local.specLevels, local.cfhttp);		

		setAfterTests(local.specLevels, local.cfhttp);

		//If this is the parent test (the root test) then we are going to call all of the afterTests defined 
		//and passed via each of the specs
		if(variables.hasParentTest IS false)
		{
			for(local.afterTest in variables.afterTestsCalls) //257
			{ 				
				local.afterTest.func(argumentCollection=local.afterTest.args) //260		
			} //262

			if(structKeyExists(variables.spec.tests,"afterRoot"))
			{
				doLog("Call After Root");
				variables.spec.tests.afterRoot();
			}
		}

		doLog("End doHTTPCall");
		return local.cfhttp;

	}	

	public function doAsserts(required specContext, required response){

		//Setup a local function that will be called before. We split this out because the assert specification
		//can either be a structure of message or just a general function
		local.doAssert = function(assert, response){
			local.funcMeta = getMetaData(arguments.assert);
			local.args = {}
			for(local.param in local.funcMeta.parameters)
			{
				if(local.param.name IS "response") 
				{ 						
					local.args.response = arguments.response;
				}
				else if (local.param.name IS "given")
				{
					local.args.given = variables.lastGiven;
				}
				else if(local.param.name IS "before")
				{
					local.args.before = variables.lastBefore;
				}
				else {
					local.args[1] = arguments.actualValue;
				}				
			}		

			local.result = arguments.assert(argumentCollection=local.args);
			if(NOT isDefined('local.result'))
			{
				throw("Your test assertion must return either true for success or false for a failure");
			}

			if(local.result IS false)
			{
				throw(message="The assertion failed");
			}
		}

		//Run the asserts 
		if(structKeyExists(arguments.specContext,"then"))
		{
			if(structKeyExists(arguments.specContext.then,"assert"))
			{	
				if(isStruct(arguments.specContext.then.assert))
				{
					for(local.message IN arguments.specContext.then.assert)
					{
						local.doAssert(arguments.specContext.then.assert["#local.message#"]);
					}
				}
				else
				{
					local.doAssert(arguments.specContext.then.assert, arguments.response);
				}
				
			}
		}
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
					variables.lastBefore = getOrCallValue(local.beforeCheck.before);	
				}
				else if(isStruct(local.beforeCheck.before))
				{
					if(structKeyExists(local.beforeCheck.before,"unit") AND variables.depth IS 1)
					{
						variables.lastBefore = local.beforeCheck.before.unit();
					}
				}
				
			}
		}
	}

	/**
	* doAfter calls any acter clauses in any of the spec levels, in the following order: 
	* All Tests > Test Level > Scenario Level
	*/
	private function doAfter(required specLevels, response){

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
						if(param.name IS "response" AND isDefined('arguments.response')) { args.response = arguments.response }
						if(param.name IS "given" AND isDefined('variables.lastGiven')) { args.given = variables.lastGiven }						
					}

					local.afterCheck.after(argumentCollection=args);
				}
				else if(isStruct(local.afterCheck.after))
				{
					if(structKeyExists(local.afterCheck.after,"unit") AND arguments.depth IS 1)
					{
						local.afterCheck.after.unit();
					}
				}
			}

		}
	}

	/**
	* setAfterTests regesters any afterTests to be called at the very end of a test heirarchy
	*/
	public function setAfterTests(required specLevels, response)
	{
		for(local.afterCheck in arguments.specLevels)
		{
			if(structKeyExists(local.afterCheck,"afterTests"))
			{
				//If the after is a function, then call it every time. Else we will check if the user has described calling it for only unit tests or collaborator tests
				if(isClosure(local.afterCheck.afterTests))
				{
					afterMeta = getMetaData(local.afterCheck.afterTests);
					local.args = {}
					for(param in afterMeta.parameters)
					{
						if(param.name IS "response" AND isDefined('arguments.response')) { args.response = arguments.response }
						if(param.name IS "given" AND isDefined('variables.lastGiven')) { args.given = variables.lastGiven }					
					}

					variables.afterTestsCalls.append({func=local.afterCheck.afterTests, args = local.args});			
				}				
			}

		}
	}

	/**
	* Returns the after tests set in this object to the calling parent. this will be used when nesting HTTP specs via 
	* the runHTTPspec function
	*/
	public function getAfterTestsCalls()
	{
		return variables.afterTestsCalls;
	}

	public function doAssertReturns(required string httpFileContent, required responseType)
	{
		switch(arguments.responseType)
		{
			case "isJson":				
				return isJson(arguments.httpFileContent);
			break;

			case "isHTML":
				local.find = reFindNoCase("<*>",arguments.httpFileContent);
				return local.find GT 0;
			break;
		}
	}

	public function doAssertStandardHTTPResponses(required struct httpResponse, required struct context)
	{
		local.context = arguments.context;
		if(structKeyExists(local.context,"then"))
		{
			for(local.key IN local.context.then)
			{
				switch(local.key)
				{
					case "responseCode":
						assertResponseValues(arguments.httpResponse.status_code,local.context.then.responseCode,"responseCode");
					break;

					case "responseText":
						assertResponseValues(arguments.httpResponse.status_text,local.context.then.responseText,"responseText");
					break;

					case "errorDetail":
						assertResponseValues(arguments.httpResponse.errordetail,local.context.then.errorDetail,"errorDetail");
					break;

					case "charSet":
						assertResponseValues(arguments.httpResponse.charset,local.context.then.charSet,"charSet");
					break;

					case "header":
						assertResponseValues(arguments.httpResponse.header,local.context.then.header,"header");
					break;

					case "httpVersion":
						assertResponseValues(arguments.httpResponse.http_version,local.context.then.httpVersion,"httpVersion");
					break;

					case "mimeType":
						assertResponseValues(arguments.httpResponse.mimetype,local.context.then.mimeType,"mimeType");
					break;

					case "filecontent":
						assertResponseValues(arguments.httpResponse.filecontent,local.context.then.fileContent,"fileContent");
					break;
				}
			}
		}
	}


	private function assertResponseValues(actualValue, expectedValue, type)
	{
		if(isClosure(arguments.expectedValue))
		{
			local.funcMeta = getMetaData(arguments.expectedValue);
			local.args = {}
			for(local.param in local.funcMeta.parameters)
			{
				if(local.param.name IS "json") 
				{ 	
					if(NOT isJson(arguments.actualValue))
					{						
						throw("The parameter to the function expected a json string but did not receive one from the API call");
					}
					local.args.json = deserializeJson(arguments.actualValue);
				}
				else if (local.param.name IS "given")
				{
					local.args.given = variables.lastGiven;
				}
				else if(local.param.name IS "before")
				{
					local.args.before = variables.lastBefore;
				}
				else {
					local.args[1] = arguments.actualValue;
				}				
			}		

			local.expected = arguments.expectedValue(argumentCollection=args);
			if(local.expected IS NOT true)
			{
				throw("The assertion for #arguments.type# failed. It returned false");
			}
		}
		else
		{
			local.expected = arguments.expectedValue;
			if(arguments.actualValue IS NOT local.expected)
			{
				throw("The value of #arguments.type# was not correct. The specification expected #local.expected# but received #arguments.actualValue#");
			}		
		}		
	}

	private function assert(value=true,message="",dumpvar=false){

		if(arguments.dumpvar)
		{
			writeDump(arguments.value);
			
		}

		if(arguments.value IS false)
		{		
			if(arguments.dumpvar)
		{
			writeDump(arguments.value);
			
			abort;
		}	
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

	private function getOrCallValue(required value)
	{
		if(isClosure(arguments.value))
		{
			local.injectArgs = getMetaData(arguments.value);

			local.args = {}
			for(local.param in local.injectArgs.parameters)
			{				
				if(local.param.name IS "before" AND isDefined('variables.lastBefore')) 
				{ 
					args.before = variables.lastBefore 
				}
				else
				{
					throw("The previous before method that was called did not return a value. Ensure that it returns a value that can be passed")
				}							
			}

			return arguments.value(argumentCollection=local.args);
		}
		else
		{
			return arguments.value;
		}

	}


}