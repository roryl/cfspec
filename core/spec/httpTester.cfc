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


	public function init(required struct spec, required string method, required string scenario, required string resource){
		variables.spec = arguments.spec;
		variables.method = arguments.method;		
		variables.resource = arguments.resource;
		variables.scenario = arguments.scenario;
		return this;
	}

	public function doHTTPCall()
	{
		local.URI = variables.spec.url & variables.resource;
		
		local.context = variables.spec.tests[variables.resource][variables.method][variables.scenario];
		http url="http://#local.uri#" method="#variables.method#" result="local.cfhttp" {

			if(structKeyExists(local.context,"given"))
			{
				if(structKeyExists(local.context.given,"url"))
				{
					httpparam type="url" name="url" value="#local.context.given.url#";
				}

				if(structKeyExists(local.context.given,"body"))
				{
					httpparam type="body" value="#local.context.given.body#";
				}

				if(structKeyExists(local.context.given,"formfields"))
				{
					for(local.field IN local.context.given.formfields)
					{
						httpparam type="formfield" name="#local.field.name#" value="#local.field.value#";	
					}
					
				}

				if(structKeyExists(local.context.given,"cookies"))
				{
					for(local.cookie IN local.context.given.cookies)
					{
						httpparam type="cookie" name="#local.cookie.name#" value="#local.cookie.value#";	
					}
					
				}
			}

		}
		doAssertStandardHTTPResponses(local.cfhttp, local.context);
		writeDump(serialize(local.cfhttp));
		abort;
		return local.cfhttp;

	}

	private function assertResponseValues(actualValue, expectedValue, type)
	{
		local.expected = getOrCallValue(arguments.expectedValue);
		if(arguments.actualValue IS NOT local.expected)
		{
			throw("The value of #arguments.type# was not correct. The specification expected #local.expected# but received #arguments.actualValue#");
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