/**
*
* @author  Rory Laitila
* @description Extends the MXUnit Test Case to add new functionality 
*
*/

component extends="mxunit.framework.testCase"  {

	private function injectVariablesGetter(required component object)
	{
		object.getPrivateVariable = function(required string variableName){
			if(isDefined(arguments.variableName))
			{
				return evaluate("#arguments.variableName#");
			}
			else{
				return false;
			}
		};

		//injectMethod(object,this,"getPrivateVariable","getPrivateVariable");
	}
	
	private function mightyMock()
	{
		return mock();
	}

	/*private function raakaMock(required componentName);
	{
		
		var mock = new affiliates.core.utilities.mock(arguments.componentName);
		return mock;
	}*/

	private function rdump(required variable)
	{
		writeDump(arguments.variable);
		writeDump(callStackGet());
	}
}