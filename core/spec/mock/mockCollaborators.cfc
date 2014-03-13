/**
*
* 
* @author  Rory Laitila
* @description Mocks out the collaborators of an object
*
*/

component output="false" displayname=""  {

	public function init(required component object, required struct contextInfo, parentName="root"){
		

		local.object = arguments.object;
		local.object.mockCollaboratorFunction = this.mockCollaboratorFunction;
		
		//Get the collaborators from the spec
		local.spec = "";
		include template="#arguments.contextInfo.specPath#";
		local.collaborators = local.spec.tests[arguments.contextInfo.functionName][arguments.contextInfo.scenarioName].with;

		
		//For each collaborator, mock out the collaborator
		for(local.collaborator in local.collaborators)
		{
		
				local.collaboratorObject = listFirst(local.collaborator,".");
				local.collaboratorFunction = listLast(local.collaborator,".");
				local.object.mockCollaboratorFunction(collaborator=local.collaboratorObject,
													  functionName=local.collaboratorFunction,
													  contextInfo=arguments.contextInfo,
													  parentName=getMetaData(local.object).fullName);						
		}
		
		
		return local.object;
	}

	public function mockCollaboratorFunction(required string collaborator, required string functionName, required struct contextInfo, parentName="root"){
		
		var spec="";
		include template="#arguments.contextInfo.specPath#";

		//Get the value of the specification document
		local.mockValue = spec.tests[arguments.contextInfo.functionName][arguments.contextInfo.scenarioName].with["#arguments.collaborator#.#arguments.functionName#"];

		/*
		Collaborators can either be in the component under test or a dependency within the variables scope. Look
		at the collaborator value passed in and create a refernece to that object
		*/
		if(arguments.collaborator IS "this"){
			local.collaboratorReference = this;
		} else {
			local.collaboratorReference = variables[collaborator]
		}			
		/*
		There are currently three types of overrides for collaborators:

			1. Mimic
				- The override follows the specification from the overriden dependencies specification. 
			2. Closure
				- The override specifies a function inline that will be used to replace the existing function. This is the quick and dirty way to mockout a return of a function
			3 Value 
				- The ovveride specifies a value that we want the function call to return instead of the natural value
		*/

		// 1. MIMIC
		if(isStruct(local.mockValue) AND structKeyExists(local.mockValue,"mimic"))
		{

			local.specPath = getMetaData(local.collaboratorReference).fullname;

			//If this is a proxy object, then we need to get the spec from the real collaborator object
			if(local.specPath CONTAINS "mockProxy")
			{
				local.specPath = getMetaData(local.collaboratorReference.getobject()).fullName;
				local.collaboratorReference = local.collaboratorReference.getobject();
			}

			//If this is a proxy object, then we need to get the spec from the real collaborator object
			if(local.specPath CONTAINS "affiliates.core.service.model.proxy")
			{
				local.specPath = getMetaData(local.collaboratorReference.object).fullName;
				local.collaboratorReference = local.collaboratorReference.object;
			}

			local.specPath = replace(local.specPath,".","/","all");
			local.specPAth =  "/" & local.specPath & ".spec";

			local.contextInfo = {
				object = local.collaboratorReference,
				specPath = local.specPath,
				functionName = arguments.functionName,
				scenarioName = local.mockValue.mimic,
				parentName = arguments.parentName
			}			
			
			local.collaboratorReference = new cfspec.core.spec.mockBuilderNew(argumentCollection=local.contextInfo);			

		}

		//2. CLOSURE
		else if(isClosure(local.mockValue))
		{

			local.collaboratorReference[arguments.functionName] = local.mockValue;
		}

		//3. VALUE
		else
		{
			//Set the value from the spec into the this scope of the object so that it can be called			
			local.collaboratorReference["#arguments.functionName#_value"] = local.mockValue;

			//Delete the original function from the object so that we can override it
			structDelete(local.collaboratorReference,arguments.functionName);

			if(structKeyExists(local.collaboratorReference,"onMissingMethod"))
			{
				local.collaboratorReference._onMissingMethod = local.collaboratorReference.onMissingMethod;
			}

			//Add onMissingMethod to the object so that we can know which function was called and retreive the value that we just set into the this scope
			local.collaboratorReference.onMissingMethod = function(missingMethodName,missingMethodArguments){

				//If the saved value exists then we know we want to return just that value
				if(structKeyExists(this,"#arguments.missingMethodName#_value")){
					return this["#arguments.missingMethodName#_value"];
				}
				else{
					//Otherwise we are going to call the function on the object mockProxy
					evaluate("this._onMissingMethod(argumentCollection=arguments)");
				}						
				
			}			
		}

		/*
		It seems necessary to write the variable reference in the opposite direction otherwise the original value remains
		*/
		if(arguments.collaborator IS "this"){
			local.collaboratorReference = this;
		} else {
			variables[collaborator] = local.collaboratorReference
		}		

	};

	

	public function getSpecPathFromComponent(required component object)
	{
		local.specPath = getMetaData(arguments.object).fullname;
		local.specPath = replace(local.specPath,".","/","all");

		return "/" & local.specPath & ".spec";
	}
}