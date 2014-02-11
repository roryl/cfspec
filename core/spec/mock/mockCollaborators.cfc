/**
*
* 
* @author  Rory Laitila
* @description Mocks out the collaborators of an object
*
*/

component output="false" displayname=""  {

	public function init(required component object, required struct contextInfo){
		
		local.object = arguments.object;
		local.object.mockCollaboratorFunction = this.mockCollaboratorFunction;

		//Get the collaborators from the spec
		local.spec = "";
		include template="#arguments.contextInfo.specPath#";
		local.collaborators = local.spec.tests[arguments.contextInfo.functionName][arguments.contextInfo.scenarioName].with;

		//For each collaborator, mock out the collaborator
		for(local.collaborator in local.collaborators)
		{
			if(listFirst(local.collaborator,".") IS "this")
			{
				
			}
			else
			{
				local.collaboratorObject = listFirst(local.collaborator,".");
				local.collaboratorFunction = listLast(local.collaborator,".");
				local.object.mockCollaboratorFunction(collaborator=local.collaboratorObject,
													  functionName=local.collaboratorFunction,
													  contextInfo=arguments.contextInfo);
			}
						
		}

		return local.object;
	}

	public function mockCollaboratorFunction(required string collaborator, required string functionName, required struct contextInfo){
		
		var spec="";
		include template="#arguments.contextInfo.specPath#";

		local.mockValue = spec.tests[arguments.contextInfo.functionName][arguments.contextInfo.scenarioName].with["#arguments.collaborator#.#arguments.functionName#"];
		
		if(isStruct(local.mockValue) AND structKeyExists(local.mockValue,"mimic"))
		{

			local.specPath = getMetaData(variables[collaborator]).fullname;
			local.specPath = replace(local.specPath,".","/","all");
			local.specPAth =  "/" & local.specPath & ".spec";

			local.contextInfo = {
				object = variables[collaborator],
				specPath = local.specPath,
				functionName = arguments.functionName,
				scenarioName = local.mockValue.mimic
			}

			variables[collaborator] = new cfspec.core.spec.mockBuilderNew(argumentCollection=local.contextInfo);
		}
		else if(isClosure(local.mockValue))
		{
			variables[collaborator][arguments.functionName] = local.mockValue;
		}
		
	};

	public function mockThisScopeFunction()
	{

	}

	public function mimicSpec(){

	}

	public function getSpecPathFromComponent(required component object)
	{
		local.specPath = getMetaData(arguments.object).fullname;
		local.specPath = replace(local.specPath,".","/","all");
		return "/" & local.specPath & ".spec";
	}
}