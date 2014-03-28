/**
*
* @author  Rory Laitila
* @description Represents the tests in a given component
*
*/

component accessors="true" {

	property name="specObject" hint="The reference to the spec" setter="false";
	property name="tests" hint="The struct of the tests";


	public function init(required specObject, required struct tests){
		
		variables.tests = arguments.tests;		
		variables.specObject = arguments.specObject;
		return this;
	}

	public function getTestByName(required string name)
	{	
		for(local.test in variables.tests)
		{
			if(local.test IS arguments.name)
			{
				local.testStruct = structNew();
				local.testStruct.insert(local.test,variables.tests[local.test]);
				return new test(variables.specObject,local.testStruct);
			}
		}
	}

	public function getAllTests()
	{
		
		local.tests = [];
		for(local.test in variables.tests)
		{
			local.testStruct = structNew();			

			local.testStruct.insert(local.test,variables.tests[local.test]);			
			local.tests.append(new test(variables.specObject,local.testStruct));			
		}
		return local.tests;
	}



}