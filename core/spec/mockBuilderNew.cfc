/**
*
* 
* @author Rory Laitila  
* @description controlls creating new mocks
*
*/

component output="false" displayname=""  {

	public function init(required component object, required string specPath, required string functionName, required string scenarioName, parentName="root"){
		

		local.contextInfo = {
			specPath:arguments.specPath,
		    functionName:arguments.functionName,
		    scenarioNAme:arguments.scenarioName
		}

		local.object = arguments.object;

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
		local.result = new mock.mockProxy(object=local.object,parentName=arguments.parentName);
		//writeDump(local.result);
		return local.result;
	}

	public function getSpecContext(required struct contextInfo){
		local.spec = "";
		include template="#arguments.contextInfo.specPath#";
		return spec.tests[arguments.contextInfo.functionName][arguments.contextInfo.scenarioName];
	}
}