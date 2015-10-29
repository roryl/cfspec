/**
*
* @author  Rory Laitila
* @description Represents a particular test function
*
*/

component accessors="true"{

	property name="spec" setter="false";
	property name="test" hint="The structure for the current test";
	property name="testName" hint="The function name of this test";
	property name="friendlyName" hint="A friendly name for the test used when displaying the list of availavble tests";
	property name="scenarios" hint="The scenarios under this test";

	public function init(required spec spec, required struct test){
		variables.spec = arguments.spec;
		variables.testName = structKeyList(arguments.test);
		variables.test = arguments.test;
		variables.scenarios = arguments.test[variables.testName];		
		return this;
	}

	public function getUnitTestNames(){
		local.names = [];

		if(structKeyExists(variables.spec.getSpecSchema(),"class"))
		{
			for(local.scenario IN variables.scenarios)
			{
				if(local.scenario IS "before" OR
				   local.scenario IS "after" OR
				   local.scenario IS "setup" OR
				   local.scenario IS "factory"){
				   continue;	
				}
				
				local.name = "#variables.testName#_#replace(local.scenario," ","_","all")#";
				local.names.append(local.name);
			}
		}

		if(structKeyExists(variables.spec.getSpecSchema(),"url"))
		{
			for(local.scenario IN variables.scenarios)
			{
				local.method = listFirst(variables.testName,":");
				local.uri = trim(listLast(variables.testName,":"));
				local.clean = cleanURI(local.uri & "_" & local.scenario);				
				local.name = "#local.method#_#local.clean#";
				local.names.append(local.name);
			}
		}

		
		return local.names;
	}

	public function getTestName(){
		return variables.testName;
	}

	private function cleanURI(required string URI)
	{
		local.output = arguments.uri;
		local.output = replaceNoCase(local.output,"?","","all");
		local.output = replaceNoCase(local.output,"/","_","all");
		local.output = replaceNoCase(local.output,"=","_","all");
		local.output = replaceNoCase(local.output,".","_","all");
		local.output = replaceNoCase(local.output,"&","_","all");	
		local.output = replaceNoCase(local.output,"{","_","all");	
		local.output = replaceNoCase(local.output,"}","_","all");
		local.output = replaceNoCase(local.output," ","_","all");
		return local.output;
	}
}