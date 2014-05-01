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
		//doStandardHTTPResponses(local.cfhttp);
		writeDump(local.cfhttp);
		abort;
		return local.cfhttp;

	}

	private function assert(value="true",message="")
	{
		if(arguments.value IS false)
		{
			throw(arguments.message);
		}
	}

	public function doAssertStandardHTTPResponses(required struct httpResponse)
	{
		local.context = variables.spec.tests[variables.resource][variables.method][variables.scenario];
		if(structKeyExists(local.context,"then"))
		{
			for(local.key IN local.context.then)
			{
				switch(local.key)
				{
					case "responseCode":
						assert(arguments.httpResponse.status_code IS getOrCallValue(local.context.then.responseCode),"responseCode");
					break;

					case "responseText":
						assert(arguments.httpResponse.status_text IS getOrCallValue(local.context.then.responseText),"responseText");
					break;

					case "errorDetail":
						assert(arguments.httpResponse.errordetail IS getOrCallValue(local.context.then.errorDetail),"errorDetail");
					break;

					case "charSet":
						assert(arguments.httpResponse.charset IS getOrCallValue(local.context.then.charSet),"charSet");
					break;

					case "header":
						assert(arguments.httpResponse.header IS getOrCallValue(local.context.then.header),"header");
					break;

					case "httpVersion":
						assert(arguments.httpResponse.http_version IS getOrCallValue(local.context.then.httpVersion),"httpVersion");
					break;

					case "mimeType":
						assert(arguments.httpResponse.mimetype IS getOrCallValue(local.context.then.mimeType),"mimeType");
					break;

					case "filecontent":
						assert(arguments.httpResponse.filecontent IS getOrCallValue(local.context.then.filecontent),"fileContent");
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