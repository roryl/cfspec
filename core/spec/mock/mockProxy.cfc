/**
*
* 
* @author  Rory Laitila
* @description Simply proxies to a real object so that we can intercept the method calls
*
*/

component output="false" displayname=""  accessors="true" {

	property name="object";	

	public function init(required component object, required string parentName){
		variables.object = arguments.object;
		variables.parentName = arguments.parentName;
		return this;
	}

	public function onMissingMethod(missingMethodName, missingMethodArguments)
	{	
		writeDump(missingMethodName);
		try {
			local.value = evaluate("variables.object.#arguments.missingMethodName#(argumentCollection=arguments.missingMethodArguments)");
		}
		catch(any e) {

			if(NOT e.message CONTAINS "There was an error in the collaborator")
			{
				local.name = getMetaData(variables.object).fullName;
				e.message = "There was an error in the collaborator #local.name# " & e.message;
			}
			throw message="#e.message#";
		}
		return local.value;
	}
}