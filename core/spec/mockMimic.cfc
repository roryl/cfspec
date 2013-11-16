/**
*
* 
* @author  Rory Laitila
* @description Handles mimicing other tests when mocking out a function
*
*/

component output="false" displayname=""  {

	public function init(required parent, required mockObjectName, required mockFunctionName, required mockContextName){
		variables.parent = arguments.parent;
		variables.mockObjectName = arguments.mockObjectName;
		variables.mockFunctionName = arguments.mockFunctionName;
		variables.mockContextName = arguments.mockContextName;

		return this;
	}

}