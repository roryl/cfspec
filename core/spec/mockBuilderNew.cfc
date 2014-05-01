/**
*
* 
* @author Rory Laitila  
* @description controlls creating new mocks
*
*/

component output="false" displayname=""  {

	public function init(required component object, required string specPath, required string functionName, required string scenarioName, parentName="root"){
		
		//Record which depth we are in on the collaborator. This is used within the mockProxy to determine if you get a value from the cache or if to request the mimic mock function
		request.mockDepth++;
		
		//Set the current depth into the local scope so that we can pass it to the mockProxy later on
		local.mockDepth = request.mockDepth;		

		//Save the spec context info into an easily passable structure which is used in many places
		local.contextInfo = {
			specPath:arguments.specPath,
		    functionName:arguments.functionName,
		    scenarioNAme:arguments.scenarioName
		}

		//Save the object into the local scope for easy reference
		local.object = arguments.object;

		//Check if the object passed in is already a mockProxy object. If it is, then we want to get the object out of the proxy so that we can mock another method
		
		// if(getMetaData(local.object).fullName CONTAINS "mockProxy")
		// {
		// 	local.object = local.object.getObject();
		// }

		local.proxy = createObject("mock.mockProxy").create(object=local.object,parentName=arguments.parentName,mockDepth=local.mockDepth,contextInfo=local.contextInfo);
		//writeDump(local.result);

		//Ensure that the function call that we are making on the collaborator is a public function
		makeFunctionPublic(local.object,arguments.functionName);
		
		//Get the spec context for the object under test
		local.specContext = getSpecContext(local.contextInfo);

		/*Mock out the collaborators. This is first because mockCollaborators will recursively call
		mockBuilder for every mimic mock that exists
		*/
		if(structKeyExists(local.specContext,"with"))
		{	
			//Mock out the collaborators for the ojbect
			local.object = new mock.mockCollaborators(object=local.object,										 
													  contextInfo=local.contextInfo);
		}
		
		/* Mock out the state for an object as represented by the when keyword
		*/
		if(structKeyExists(local.specContext,"when"))
		{
			//Mock out the state for the object
			local.object = new mock.mockState(object=local.object,
											  context=local.specContext,
											  contextInfo=local.contextInfo);
		}		
		
		/* Wrap the object in a proxy method so that we can introspect the arguments and return values
		of a function call */
		local.result = createObject("mock.mockProxyNew").create(object=local.object,parentName=arguments.parentName,mockDepth=local.mockDepth,contextInfo=local.contextInfo);
		//writeDump(local.result);
		return local.result;
	}

	public function getSpecContext(required struct contextInfo){
		local.spec = "";
		try{
			include template="#arguments.contextInfo.specPath#";
			local.specContext = local.spec.tests[arguments.contextInfo.functionName][arguments.contextInfo.scenarioName];
			if(isNull(local.specContext))
			{
				throw;
			}
			return local.specContext;
		}
		catch (any e) {
			writeDump("Error on mockBuilderNew.getSpecContext");
			writeDump(local.spec);
			writeDump(arguments.contextInfo);
			abort;
		}
		
	}

	public function makeFunctionPublic(required component object, required functionName){
		/*
		Add a closure to make any private functions public. We will call this for every function call being tested
		*/

		arguments.object.makePublic = function(required functionName){
			if(structKeyExists(this,arguments.functionName) AND getMetaData(this[arguments.functionName]).access IS "private")
			{
				this[arguments.functionName] = variables[arguments.functionName];
			}
		}
		arguments.object.makePublic(arguments.functionName);
	}

	
}