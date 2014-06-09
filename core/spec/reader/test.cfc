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
		for(local.scenario IN variables.scenarios)
		{
			local.name = "#variables.testName#_#replace(local.scenario," ","_","all")#";
			local.names.append(local.name);
		}
		return local.names;
	}
}