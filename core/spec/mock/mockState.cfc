/**
*
* 
* @author  Rory Laitila
* @description Component to mock out the state of an object
*
*/

component output="false" displayname=""  {

	public function init(required component object,
						 required struct context, 
						 required struct contextInfo){

		//Get the when variables
		local.when = arguments.context.when;
		local.object = arguments.object;

		//Copy the override variable into the object so that calls to it are within the scope of the object
		local.object.overrideVariable = this.overrideVariable;

		//For each state variable that needs to be overwritten, call the override variable
		for(local.variableName in local.when){
			local.object.overrideVariable(variableName=local.variableName,
										  contextInfo=arguments.contextInfo);
		}

		//Return the object with the now overridden state
		return local.object;
	}

	/*Create a closure on the object so that we can overwrite variables that may exist within the object. We need to perform the override within the scope
		of the component under test because the variables may be in any valid coldfusion scopes, variables, request, session, etc*/
	public function overrideVariable(required string variableName,required struct contextInfo){
		
		//We need to import the spec into the internal scope of the component under test in order to call functions conainted with the spec. Any functions within the spec
		//error for not being found unless they are loaded within the scope of the caller.
		var spec = "";
		include template="#arguments.contextInfo.specPath#";

		//Get the value of the variable as described in the spec
		var value = spec.tests[arguments.contextInfo.functionName]["#arguments.contextInfo.scenarioName#"].when["#arguments.variableName#"];
		//Set the value of the variableName passed in with the value obtained from the spec
		if(isStruct(value))
		{
			evaluate("#arguments.variableName# = {}");
			for(key in value)
			{
				evaluate("structInsert(#arguments.variableName#,key,value[key],true)");	
			}
		}
		else
		{
			evaluate("#arguments.variableName# = value");	
		}
		
	}
}