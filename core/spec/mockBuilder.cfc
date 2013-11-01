/**
*
* 
* @author  Rory Laitila
* @description Respnsible for building mocks of objects
*
*/

component {

	public function init(required parent, required specPath, required functionName, required contextName,skipMocks=false,recurseCount=1){
		this.log("mocking #arguments.specPath#");

		param name="request.dumpc" default="0";
		request.dumpc = request.dumpc + 1;
		//writeDump(var=arguments,label="mockBuilderStart #request.dumpc#");
		
		newExecution()
		request.saveStep = this.saveStep;
		request.indent = this.indent;
		request.dumpAt = this.dumpAt;
		saveStep("start Builder for ''#functionName#', ''#contextName#'",1);
		/*
		TASKS -
			This function will be given component undertest, the specification and the context path that we are on. 
			We will need to build out the mocks and submocks for this object and passback the fully built component
			under test. The following needs to be completed

			1. Override any objects in the variables scope with mocks
			2. We need to override the objects instance variables based on the spec WHEN keyword
			3. We need to override the specific collaborators as described in the spec WITH keyword
		*/
		//try{
			var spec = "";
			//Include the spec document. We need a direct reference to it so that any closures can be called
			include template="#arguments.specPath#";
			request.recurseCount = arguments.recurseCount;
			local.parent = setupFunctionOverrides(parent=arguments.parent,functionName=arguments.functionName);
			
			/* The skipMocks flag is provided for when we are already passing in reference to a component under test. This will occur
			when the specification describes overriding a function of the component under test. In that situation, the CUT is passed back in
			so as to override the function. However, to ensure that no other parameters are incorrectly mocked, we can flag it to skip mocks
			  */



			if(arguments.skipMocks IS FALSE)
			{
				doCreateDefaultMocks(local.parent,local.spec); 	
			}
					
			if(structKeyExists(local.spec.tests[arguments.functionName],"setup"))
			{
				doSpecSetupFunction(specFunction=local.spec.tests[arguments.functionName]);
			}

			var context = spec.tests[arguments.functionName]["#arguments.contextName#"];
			
			if(structKeyExists(context,"when"))
			{
				doWhenKeyword(parent=local.parent,
							  when=context.when,
							  contextName=arguments.contextName,
							  specPath=arguments.specPath,
							  functionName=arguments.functionName);
			}

			if(structKeyExists(context,"with"))
			{
				doWithKeyword(parent=local.parent,
							  specPath=arguments.specPath,
							  functionName=arguments.functionName,
							  contextName=arguments.contextName,
							  skipMocks=arguments.skipMocks,
							  recurseCount=arguments.recurseCount,
							  with=local.context.with);
			}
		/*} 
		catch(any e){
			writeDump(var="#e#",label="Error encounted while in mockBuilder");		
			writeDump(var="#arguments#",label="The arguments passed to mockBuilder");

			if(NOT e.message CONTAINS "key [createNewTempPassword] doesn't exist in struct")
			{
				abort;		
			}
			abort;
		}*/
		saveStep("End Builder for ''#functionName#', ''#contextName#'",-1);
		
		return parent;
	}

	public function log(required string message){
		//writeLog(file="mockBuilder",text=arguments.message);
	}



	private function doCreateDefaultMocks(required parent, required struct spec)
	{		
		saveStep("Start doCreateDefaultMocks",1,{arguments:arguments});

		if(structKeyExists(arguments.spec,"mockObjects"))
		{
			var mocks = arguments.spec.mockObjects;//The objects within the component under test that need to be mocked
			//Create a closure on the object to that we can mock out the dependencies. This allows us to access the internal scope of the object at runtime
			
			//local.parent = addMockOverrideClosure(arguments.parent);
			
			for(var mock in mocks)
			{
				saveStep("Mock #local.mock#");

				//Override the #mock# object within the component under test with a mock version
				arguments.parent.MockOverride("#local.mock#");

			}
			
		}
		
		saveStep("End doCreateDefaultMocks",-1);
		

	}

	private function doSpecSetupFunction(required specFunction)
	{
		saveStep("Start doSpecSetupFunction");
		//If the specification has a setup function, we need to call it
		arguments.specFunction.setup();
	}

	private function doWhenKeyword(required parent, required when, required contextName, required specPath, required functionName)
	{
		saveStep("Start doWhenKeyword",1);
		//Overriding the instance variables
		/* WHEN keyword - Defines the variables that must exist within the component or in other scopes. Then WHEN represents the 'state' of the componet or environment 
					when under test.*/

			//Overwrite any other variables as defined in the spec
			for(var varName in arguments.when)
			{
				saveStep("overwrite #varName#");
				//Call the overriding function to ovverride this variable
				parent.overrideVariable("#local.varName#",arguments.specPath,arguments.functionName,arguments.contextName);
			}
			
		saveStep("End doWhenKeyword",-1);
	}

	private function doWithKeyword(required parent, required with, required specPath, required functionName, required contextName)
	{
		saveStep("Start doWithKeyword, parent is #getMetaData(parent).fullName#",1,{arguments:arguments});
		var MockedFunctions = arguments.with;
		
		
		//Mock any methods which were requests to be mocked
		for(var mockFunc in local.mockedFunctions)
		{
			saveStep("Start Mock #mockFunc#",1,{arguments:arguments});

			//Get the name of the object being mocked
			var mockObject = listFirst(mockFunc,".");
			//Get the function name being mocked within the object
			var mockFunction = listLast(mockFunc,".");
			var mockValue = local.mockedFunctions[mockFunc];

			

			//If the function call being mocked is within the component under test, then we can pass this component under test
			//again to the to the mock builder, along with the context values being mocked, and those variables will be set.
			if(local.mockObject IS "this")
			{	
				saveStep("is This scope mock");
				/*
				The context being sent to the mockBuilder is that of the mimic'd function. We also set the glag skipMocks to true because
				we are passing in a reference to the already mocked object. We won't want to remock dependencies which may have already been
				overridden.
				*/
				arguments.parent = new mockBuilder(parent=arguments.parent,specPath=arguments.specPath,functionName=mockFunction,contextName=mockedFunctions[mockFunc].mimic,skipMocks=true);
				
			}

			//If the 
			else if(isSimpleValue(local.mockValue))
			{	
				saveStep("is simple value mock");
				var mockValuePath = 'tests.#arguments.functionName#["#arguments.contextName#"].with["#mockFunc#"]';
				
				arguments.parent.mockFunction("#local.mockObject#",arguments.specPath,"#local.mockFunction#",local.mockValuePath) ;; //Return it as a string
				
			}

			/*	
			If the value is a mimic, then we are going to be inheriting another test 
			*/
			else if(isStruct(mockValue) AND structKeyExists(mockValue,"mimic")) 
			{
				saveStep("is mimic mock");
				var mockContextName = mockValue.mimic;
				//We need a real mock for this function that uses the real function call and real object
				//arguments.parent = new mockMimic(parent=arguments.parent)
				arguments.parent.mimic(local.mockObject,local.mockFunction,local.mockContextName);					
			}

			else
			{
				saveStep("is another value mock");
				//writeDump(var=arguments,label="Simple value #request.dumpc#");
				var mockValuePath = 'tests.#arguments.functionName#["#arguments.contextName#"].with["#local.mockFunc#"]';
				parent.mockFunction(local.mockObject,arguments.specPath,local.mockFunction,local.mockValuePath);
				
			}
			saveStep("End Mock #mockFunc#",-1);
			
			
		}
		saveStep("End doWithKeyword",-1);
		
		
	}

	private function setupFunctionOverrides(required parent,required functionName)
	{
		
		/*
		Add a closure to make any private functions public. We will call this for every function call being tested
		*/
		arguments.parent.makePublic = function(required functionName){
			if(structKeyExists(this,arguments.functionName) AND getMetaData(this[arguments.functionName]).access IS "private")
			{
				this[arguments.functionName] = variables[arguments.functionName];
			}
		}
		arguments.parent.makePublic(arguments.functionName);


		/*
		Add a closure to allow us to override object dependencies with mock versions of them
		*/
		arguments.parent.mockOverride = function(variableName){
				
				request.saveStep("Start mockOverride()",1,{this:this,arguments:arguments});
				
				//Check if the component is already a mock. If it is, then we can't mock it again because creating a mock
				//of the mock will just result in an invalid object. This may happen when the component under test is mimicing
				//One of the other function calls in the spec.
				var meta = getComponentMetaData(variables[arguments.variableName]);
				//request.dumpAt(37,variables[arguments.variableName],true,true);



				if(NOT meta.name contains "cfspec.core.mock")
				{
					request.saveStep("Before mock",0,{service:variables[arguments.variableName]});
					variables[arguments.variableName] = new cfspec.core.mock(variables[arguments.variableName]);
					request.saveStep("after mock",0,{service:variables[arguments.variableName]});
				}
				request.saveStep("End mockOverride()",-1);

		};

		/*Create a closure on the object so that we can overwrite variables that may exist within the object. We need to perform the override within the scope
		of the component under test because the variables may be in any valid coldfusion scopes, variables, request, session, etc*/
		arguments.parent.overrideVariable = function(variableName,specPath,functionName,contextName){
		
			//We need to import the spec into the internal scope of the component under test in order to call functions conainted with the spec. Any functions within the spec
			//error for not being found unless they are loaded within the scope of the caller.
			var spec = "";
			include template="#arguments.specPath#";

			//Get the value of the variable as described in the spec
			var value = spec.tests[functionName]["#arguments.contextName#"].when["#arguments.variableName#"];
			//Set the value of the variableName passed in with the value obtained from the spec
			if(isStruct(value))
			{
				for(key in value)
				{
					evaluate("structInsert(#variableName#,key,value[key],true)");	
				}
			}
			else
			{
				evaluate("#variableName# = value");	
			}
			
		};

		parent.mockFunction = function(mockObject,specPath,mockFunction,mockValuePath){
			request.saveStep("Start mockFunction()",1,{arguments:arguments});

			var spec="";
			include template="#arguments.specPath#";

			var value = evaluate("spec.#arguments.mockValuePath#")
			request.saveStep("override mock function",0,{value:value,mockObject:variables[arguments.mockObject]});
			//Set the mock return value
			variables[arguments.mockObject].method(arguments.mockFunction).returns(value);
			request.saveStep("override mock function",0,{mockObject:variables[arguments.mockObject]});
			request.saveStep("end mockFunction()",-1);
		};

		arguments.parent.mimic = function(required mockObjectName,mockfunctionName,mockContextName){
			
			try{
			request.saveStep("Start mimic mock for #mockObjectName#,#mockFunctionName#,#mockContextName#",1,{this:this,arguments:arguments});
			
			
			
			//writeDump(var=variables[arguments.mockObjectName],label="Start Mimic #request.dumpc#");

			//Get the specification of the real object so that we can determine what needs to be mocked
			if(structKeyExists(variables[arguments.mockObjectName],"getRealComponentPath"))
			{
				var realMockPath = variables[arguments.mockObjectName].getRealComponentPath();	
			}
			else
			{
				var realMockPath = getMetaData(variables[arguments.mockObjectName]).fullName;	
			}
			
			//request.dumpAt(31,arguments,false,true);
			//request.dumpAt(31,realMockPath);
			//request.dumpAt(31,getMetaData(variables[arguments.mockObjectName]),true);
			
			specPath = replace(realMockPath,".","/","all");
			specPath = "/#lcase(specPath)#.spec";
			
			//Build the spec of the object
			var spec = "";
			include template="#specPath#";
			
			if(structKeyExists(url,"depth") AND url.depth IS NOT 0 AND request.recurseCount GTE url.depth)
			{
				if(structKeyExists(spec.tests[arguments.mockFunctionName][arguments.mockContextName].then,"returns"))
				{
					var mockValuePath = 'tests.#arguments.mockFunctionName#["#arguments.mockContextName#"].then.returns';
					this.mockFunction("#mockObjectName#",specPath,"#mockFunctionName#",mockValuePath) ;; //Return it as a string
				}
				return; 
			};

			request.saveStep("Create subObject #spec.class#");
			//request.saveStep("Before sub object",0,);

			if(structKeyExists(variables[arguments.mockObjectName],"createdInRequest"))
			{
				var subObject = variables[arguments.mockObjectName];
			}
			else
			{
				//Call the factory method from the spec to build the object
				if(structKeyExists(spec,"factory"))
				{
					var subObject = spec.factory();
				}
				else
				{
					//A factory was not defined, so we will create the native object
					var subObject = createObject("component",spec.class);
				}
			}
			subObject.createdInRequest = true;

			/*
			I believe this is deprecated and can be deleted. 
			Set the spec into the object as we may need to use it later
			subObject.setSpec = function(spec){
				variables.spec = arguments.spec;
			}
			subObject.setSpec(spec);*/
			//writeDump(var=subObject,label="Mimic Subobject #request.dumpc#");
			//Set the spec into the object as we need to pass in these values so that we can use them when proxying to the real function call
			subObject.setSpecContext = function(spec,mockFunctionName,mockContextName){
				//writeDump(var=arguments,label="setSpecContext #request.dumpc#");
				variables.specContext = {
					functionName:arguments.mockFunctionName,
					contextName:arguments.mockContextName,
					context:spec.tests[mockfunctionName]["#mockContextName#"]
				}
			}
			subObject.setSpecContext(local.spec,arguments.mockFunctionName,arguments.mockContextName);
			

			request.saveStep("Start Create finalSubObject for #spec.class#",1,[subObject,specPath,arguments.mockFunctionName,arguments.mockContextName,false,request.recurseCount + 1]);
			//Create the final subItem by mocking itself. We do this by recursively calling the mockBuilder with each spec
			finalsubObject = new cfspec.core.spec.mockBuilder(subObject,specPath,arguments.mockFunctionName,arguments.mockContextName,false,request.recurseCount + 1);
			request.saveStep("End create finalSubObject for #spec.class#",-1);


			//Create a getType utility object on the mock as this will be used when assessing the returnType
			finalSubObject.getType = createObject("component","cfspec.core.spec.getType");


			/* The function being mocked may be a real function, or it could be a proxy function via onMissingMethod
			Depending on this, we are going to create a proxy method to the real function, or a proxy to onMissingMethod */							
			if(structKeyExists(finalSubObject,"#mockFunctionName#"))
			{
				//In order to create a proxy to the real method call, we need to first copy the real method to a proxy method
				finalSubObject["_#mockFunctionName#"] = finalSubObject[mockFunctionName];

			}
			else if(structKeyExists(finalSubObject,"onMissingMethod"))
			{
				
					finalSubObject["_onMissingMethod"] = finalSubObject["onMissingMethod"];
					mockFunctionName = "onMissingMethod";
			}
			//Now we can override the real method as a proxy, and call our former copy. This allows us to check the return value that it matches the spec
			finalSubObject["#mockFunctionName#"] = function(){

				request.given = arguments;
				if(structKeyExists(this,"#variables.specContext.functionName#"))
				{
					result = evaluate("this._#variables.specContext.functionName#(argumentCollection=arguments)");
					
				}
				else if(structKeyExists(this,"onMissingMethod")){
					result = evaluate("this._onMissingMethod(argumentCollection=arguments)");
				}

				if(structKeyExists(variables.specContext.context,"then"))
				{	
					if(structKeyExists(variables.specContext.context.then,"returns"))
					{							
						
						returnType = variables.specContext.context.then.returns;
						
						if(returnType IS "void")
						{
							if(isDefined('result'))
							{
								throw(message="The collaborator return value from #variables.spec.class# did not match its specification. It should have returned #variables.specContext.context.then.returns# but returned a value. The tested specification was: #variables.specContext.functionName# #variables.specContext.contextName#");
							}
							else
							{
								resultType = "void";
							}
						}
						else if(returnType CONTAINS "is")
						{
							resultType = this.getType.init(result);
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
					if(structKeyExists(variables.specContext.context.then,"assert"))
					{

						var assert = variables.specContext.context.then.assert;
						
						for(var i=1; i LTE arrayLen(assert); i =i+1)
						{

							if(isClosure(assert[i].value))
							{
								
								var assertValue = assert[i].value();
								if(isSimpleValue(assertValue) and assertValue IS false)
								{
									local.message = "";
									if(structKeyExists(assert[i],"message"))
									{
										local.message = assert[i].message;
									}
									throw(message="The collaborator assertion from #variables.spec.class# failed. The message was:#local.message#");
								}
							}
						}
					}
				}
				if(isDefined("result"))
				{
					return result;
				}
				
			};

			variables[arguments.mockObjectName] = finalSubObject;
			}
			catch(any e){
				writeOutput(request.executionPlan);
				writeDump(e);
				abort;
			}
			request.saveStep("End mimic mock for #mockObjectName#,#mockFunctionName#,#mockContextName#",-1);
			

		};		

		return arguments.parent;
	}

	private function saveStep(message,indent=0,saveVar)
	{
		try{
			request.totalSteps = request.totalSteps + 1
			var indent="------";
			if(arguments.indent IS -1)
			{
				request.indentCount = request.indentCount - 1;
			}

			var indentText = "";
			for(i=1; i LTE request.indentCount; i =i+1)
			{
				indentText = indentText & local.indent;
			}

			if(structKeyExists(arguments,"saveVar"))
			{
				if(request.previousSaves IS 0)
				{
					session.previousSaves = {};
					request.previousSaves = 1;
					structInsert(session.previousSaves,request.totalSteps,arguments.saveVar);
				}
				else{
					structInsert(session.previousSaves,request.totalSteps,arguments.saveVar);
				}

			}

			if(structKeyExists(session.previousSaves,request.totalSteps))
			{
				var varlink = "<a target='_blank' href='/tests/cfspec.cfm?step=#request.totalSteps#'>View Args</a>";
			}
			else
			{
				var varLink = "";
			}

			request.executionPlan = request.executionPlan & indentText & " #message# -//#request.totalSteps# //#callStackGet()[2].lineNumber# #varLink#<br />";

			
			
			if(arguments.indent IS 1)
			{
				request.indentCount = request.indentCount + 1;
			}
			

		}
		catch(any e)
		{
			writeDump(e);
			abort;
		}
	}

	private function indent(default=1)
	{
		if(arguments.default IS 1)
		{
			request.indentCount = request.indentCount + 1;
		}
		else if(arguments.default IS -1)
		{
			request.indentCount = request.indentCount - 1;
		}
	}

	private function newExecution(cursor)
	{
		param name="request.executionPlan" default="<br />";
		param name="request.indentCount" default="0";
		param name="request.totalSteps" default="0";
		param name="request.previousSaves" default="0";
		param name="session.previousSaves" default="#structNew()#";
	}

	private function dumpAt(step,variable,abortRequest=false,executionPlan=false)
	{

		if(request.totalSteps IS arguments.step)
		{
			if(executionPlan)
			{
				writeOutput(request.executionPlan);
			}
			writeDump(var=arguments.variable,label="Dumped at Line #callStackGet()[2].lineNumber#");


			if(arguments.abortRequest)
			{
				abort;
			}
		}
	}


}