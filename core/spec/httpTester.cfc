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


	public function init(required string specPath, required string method, required string scenario, required string resource){

		//Load the spec path into this variables scope. It is neceessary that the spec be included here so that any function calls from within the spec are in the scope of this object
		variables.spec = "";
		include template="#arguments.specPath#";
		
		variables.method = arguments.method;		
		variables.resource = arguments.resource;
		variables.scenario = arguments.scenario;
		return this;
	}

	public function doHTTPCall()
	{
		local.URI = variables.spec.url & variables.resource;
		
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



			local.given = getOrCallValue(local.context.given);

			request.given = local.given;

			if(structKeyExists(local.given,"path"))
			{
				local.path = getOrCallValue(local.given.path);

				//For each of the path items, replace the variable requested with the value
				for(local.item IN local.path)
				{
					local.uri = replaceNoCase(local.uri, "{#local.item#}", local.path[local.item]);
				}
			}
		}		

		http url="http://#local.uri#" method="#variables.method#" result="local.cfhttp" {

			if(structKeyExists(local.context,"given"))
			{

				if(isClosure(local.context.given))
				{
					local.context.given = local.context.given();
				}

				if(structKeyExists(local.context.given,"url"))
				{
					httpparam type="url" name="url" value="#getOrCallValue(local.context.given.url)#";
				}

				if(structKeyExists(local.context.given,"body"))
				{
					httpparam type="body" value="#getOrCallValue(local.context.given.body)#";
				}

				if(structKeyExists(local.context.given,"formfields"))
				{
					for(local.field IN local.context.given.formfields)
					{
						httpparam type="formfield" name="#local.field#" value="#getOrCallValue(local.context.given.formfields[local.field])#";	
					}
					
				}

				if(structKeyExists(local.context.given,"cookies"))
				{
					for(local.cookie IN local.context.given.cookies)
					{
						httpparam type="cookie" name="#local.cookie.name#" value="#getOrCallValue(local.cookie.value)#";	
					}
					
				}
			}
		}

		//Do all of the standard HTTP response checks (for mime type, response code, etc)
		doAssertStandardHTTPResponses(local.cfhttp, local.context);
		
		doAsserts(local.context, local.cfhttp);

		doAfter(local.specLevels, local.cfhttp);

		return local.cfhttp;

	}

	private function assertResponseValues(actualValue, expectedValue, type)
	{
		if(isClosure(arguments.expectedValue))
		{
			local.expected = arguments.expectedValue(arguments.actualValue);
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

	public function doAsserts(required specContext, required response){
		if(structKeyExists(arguments.specContext,"then"))
		{
			if(structKeyExists(arguments.specContext.then,"assert"))
			{				
				local.result = arguments.specContext.then.assert(arguments.response);
				if(NOT isDefined('local.result'))
				{
					throw("Your test assertion must return either true for success or false for a failure");
				}

				if(local.result IS false)
				{
					throw(message="The assertion failed");
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
					local.beforeCheck.before();	
				}
				else if(isStruct(local.beforeCheck.before))
				{
					if(structKeyExists(local.beforeCheck.before,"unit") AND variables.depth IS 1)
					{
						local.beforeCheck.before.unit();
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

	private function getOrCallValue(required value)
	{
		if(isClosure(arguments.value))
		{
			return arguments.value();
		}
		else
		{
			return arguments.value;
		}

	}


}