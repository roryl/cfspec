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

		if(structKeyExists(variables.specObject.getSpecSchema(),"class"))
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

		if(structKeyExists(variables.specObject.getSpecSchema(),"url"))
		{
			local.tests = [];
			for(local.resource in variables.tests)
			{
				if(listContains("before,setup,after,afterTests,afterRoot",local.resource)){
					continue;
				}
				

				for(local.method in variables.tests[local.resource])
				{
					if(listContains("before,setup,after,afterTests,afterRoot",local.resource)){
						continue;
					}
					
					local.testStruct = structNew();				
					local.testStruct.insert("#local.method#: #local.resource#",variables.tests[local.resource][local.method]);
					local.tests.append(new test(variables.specObject,local.testStruct));			
				}			
				// }catch(any e)
				// {
				// 	writeDump(local.resource);
				// 	abort;
				// }
				
			}
			return local.tests;	
		}

		
	}



}