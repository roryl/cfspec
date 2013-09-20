/**
*
* 
* @author  Rory Laitila
* @description Respnsible for building mocks of objects
*
*/

component {

	public function init(required parent, required specPath, required functionName, required contextName){
		
		/*
		TASKS -
			This function will be given component undertest, the specification and the context path that we are on. 
			We will need to build out the mocks and submocks for this object and passback the fully built component
			under test. The following needs to be completed

			1. Override any objects in the variables scope with mocks
			2. We need to override the objects instance variables based on the spec WHEN keyword
			3. We need to override the specific collaborators as described in the spec WITH keyword
		*/
		try{
		var spec = "";
		//Include the spec document. We need a direct reference to it so that any closures can be called
		include template="#arguments.specPath#";



		if(structKeyExists(spec,"mockObjects"))
		{


			mocks = spec.mockObjects;//The objects within the component under test that need to be mocked
			//Create a closure on the object to that we can mock out the dependencies. This allows us to access the internal scope of the object at runtime
			parent.mockOverride = function(variableName){variables[arguments.variableName] = new cfspec.core.mock(variables[arguments.variableName]);};
			
			for(var mock in mocks)
			{
				//Override the #mock# object within the component under test with a mock version
				parent.MockOverride("#mock#");
			}
		}
		
		
		context = spec.tests[arguments.functionName]["#arguments.contextName#"];
		

		//Overriding the instance variables
		/* WHEN keyword - Defines the variables that must exist within the component or in other scopes. Then WHEN represents the 'state' of the componet or environment 
					when under test.*/
		
		if(structKeyExists(context,"when"))
		{
			var when = context.when;//The state of the system under test
			/*Create a closure on the object so that we can overwrite variables that may exist within the object. We need to perform the override within the scope
			of the component under test because the variables may be in any valid coldfusion scopes, variables, request, session, etc*/
			parent.overrideVariable = function(variableName,specPath,functionName,contextName){
			
				//We need to import the spec into the internal scope of the component under test in order to call functions conainted with the spec. Any functions within the spec
				//error for not being found unless they are loaded within the scope of the caller.
				var spec = "";
				include template="#arguments.specPath#";

				//Get the value of the variable as described in the spec
				
				var value = spec.tests[functionName]["#arguments.contextName#"].when["#arguments.variableName#"];
				//Set the value of the variableName passed in with the value obtained from the spec
				evaluate("#variableName# = value");
			};

			//Overwrite any other variables as defined in the spec
			for(varName in when)
			{
				//Call the overriding function to ovverride this variable
				parent.overrideVariable("#varName#",arguments.specPath,arguments.functionName,arguments.contextName);
			}
		}

		if(structKeyExists(context,"with"))
		{

			parent.mockFunction = function(mockObject,specPath,mockFunction,mockValuePath){
				
				var spec="";
				include template="#arguments.specPath#";
				var value = evaluate("spec.#arguments.mockValuePath#")
				variables[arguments.mockObject].method(arguments.mockFunction).returns(value);
			}
			
			var MockedFunctions = context.with;
				
			//Mock any methods which were requests to be mocked
			for(var mockFunc in mockedFunctions)
			{
				var mockObject = listFirst(mockFunc,".");
				var mockFunction = listLast(mockFunc,".");

				//If it is a simple value then we can just pass in the value 
				if(isSimpleValue(mockedFunctions[mockFunc]))
				{	
					var mockValuePath = 'tests.#arguments.functionName#["#arguments.contextName#"].with["#mockFunc#"]';
					parent.mockFunction("#mockObject#",arguments.specPath,"#mockFunction#",mockValuePath) ;; //Return it as a string
				}

				else if(isStruct(mockedFunctions[mockFunc]) AND structKeyExists(mockedFunctions[mockFunc],"mimic")) 
				{
					mockContextName = mockedFunctions[mockFunc].mimic;
					//We need a real mock for this function that uses the real function call and real object
						parent.mimic = function(required mockObjectName,mockfunctionName,mockContextName){
							
							//Get the specification of the real object so that we can determine what needs to be mocked
							realMockPath = variables[arguments.mockObjectName].getRealComponentPath();
							
							specPath = replace(realMockPath,".","/","all");
							specPath = "/#lcase(specPath)#.spec";
							
							//Build the spec of the object
							var spec = "";
							include template="#specPath#";

							//Call the factory method from the spec to build the object
							subObject = spec.factory();

							//Set the spec into the object as we may need to use it later
							subObject.setSpec = function(spec){
								variables.spec = arguments.spec;
							}
							subObject.setSpec(spec);

							//Set the spec into the object as we need to pass in these values so that we can use them when proxying to the real function call
							subObject.setSpecContext = function(spec,mockFunctionName,mockContextName){
								variables.specContext = {
									functionName:arguments.mockFunctionName,
									contextName:arguments.mockContextName,
									context:spec.tests[mockfunctionName]["#mockContextName#"]
								}
							}
							subObject.setSpecContext(spec,arguments.mockFunctionName,arguments.mockContextName);

							//Create the final subItem by mocking itself. We do this by recursively calling the mockBuilder with each spec
							finalsubObject = new cfspec.core.spec.mockBuilder(subObject,specPath,arguments.mockFunctionName,arguments.mockContextName);

							//Create a getType utility object on the mock as this will be used when assessing the returnType
							finalSubObject.getType = createObject("component","cfspec.core.spec.getType");

							//In order to create a proxy to the real method call, we need to first copy the real method to a proxy method
							finalSubObject["_#mockFunctionName#"] = finalSubObject[mockFunctionName];

							//Now we can override the real method as a proxy, and call our former copy. This allows us to check the return value that it matches the spec
							finalSubObject["#mockFunctionName#"] = function(){
								
								result = evaluate("this._#variables.specContext.functionName#(argumentCollection=arguments)");

								if(structKeyExists(variables.specContext.context,"then"))
								{	
									if(structKeyExists(variables.specContext.context.then,"returns"))
									{
										resultType = this.getType.init(result);
										
										returnType = variables.specContext.context.then.returns;
										if(returnType CONTAINS "is")
										{
											returnType = replaceNoCase(returnType,"is","");
										}
										else if(isBoolean(returnType))
										{
											resultType = result;
										}

										if(resultType IS NOT returnType)
										{
											throw(message="The collaborator return value from #variables.spec.class# did not match its specification. It should have returned #variables.specContext.context.then.returns# but returned #resultType#. The tested specification was: #variables.specContext.functionName# #variables.specContext.contextName#");
										}
									}
								}
								
								return result;
							};	


							variables[arguments.mockObjectName] = finalSubObject;


						};
					parent.mimic(mockObject,mockFunction,mockContextName);
				}
				else
				{	
					
					var mockValuePath = 'tests.#functionName#["#contextName#"].with["#mockFunc#"]';
					parent.mockFunction(mockObject,arguments.specPath,mockFunction,mockValuePath);
					
				}
				
				
			}
		}
		} catch(any e){
			writeDump(arguments);
			writeDump(e);
			abort;
		}
		
		return parent;
	}
}