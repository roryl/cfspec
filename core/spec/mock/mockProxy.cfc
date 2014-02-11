/**
*
* 
* @author  Rory Laitila
* @description Simply proxies to a real object so that we can intercept the method calls
*
*/

component output="false" displayname=""  {

	public function init(required component object){
		variables.object = arguments.object;
		return this;
	}

	public function onMissingMethod(missingMethodName, missingMethodArguments)
	{	
		return evaluate("variables.object.#arguments.missingMethodName#(argumentCollection=arguments.missingMethodArguments)");
	}
}