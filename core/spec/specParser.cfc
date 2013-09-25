/**
*
* 
* @author  Rory Laitila
* @description Parses a JSON Spec into a runnable MXunit test
*
*/

import writeFileAndDirectories;
component {

	property name="compilePath";
	property name="specFilePath";
	public function init(){
		variables.lastTab = 0;
		variables.debugging = true;
		return this;
	}

	public function parseSpec(required filePath, outputPath)
	{

		writeDump(arguments);
		
		var specFileName = listGetAt(filePath,listLen(filePath,"/"),"/");
		var componentUnderTestDirectoryPath = replace(filePath,specFileName,"");
		var componentUnderTestFileName = replace(specFileName,".spec","");
				
		var finalCompileDirectory = outputPath & componentUnderTestDirectoryPath;
		
		//Create the directory and all directories if they do not exist
		if(NOT directoryExists(finalCompileDirectory))
		{
			directoryCreate(finalCompileDirectory,true);	
		}
		
		finalCompilePath = finalCompileDirectory & "/#componentUnderTestFileName#Tests.cfc";
		
		variables.specFilePath=arguments.filePath;
		include template="#variables.specFilePath#";
		return _parseSpec(spec,finalCompilePath);
	}

	public function parseAllSpecs(required specDirectory, required outputPath)
	{
		
		if(structKeyExists(url,"reloadFiles") OR NOT structKeyExists(application,"specFiles"))
		{
			application.specFiles = getSpecFiles(arguments.specDirectory,"*.spec");	
		}


		for(var file in application.specFiles)
		{
			try{
				parseSpec(application.specFiles[file].path,arguments.outputPath);	
			}
			catch(any e)
			{
				writeDump(e);
			}
			
		}
		
		return application.specFiles;
	}

	private function getSpecFiles(required mapping,required filter){
		var output = {};

		files = directoryList(expandPath(arguments.mapping),true,"query",arguments.filter);	
		
		for(i=1;i LTE files.recordCount; i=i+1)
		{
			template = files["name"][i];
			finalpath = replace(files["directory"][i],expandPath(mapping),"");
			
			//finalpath = replace(finalpath,"/",".","all");
			//finalpath = replace(finalpath,"\",".","all");

			output[template].path = "#mapping##finalPath#/#template#";
		}
		
		return output;
	}

	private function _parseSpec(specObject,compilePath){
		

		/* 	Design Notes:
			
				The compiler generates output to create the MXunit test case, mock out the dependencies and functions under test, and test the methods. There
				are a number of complicated design decisions to acheive this so they are discussed below: 

				1. Code Scope - Throughout the compilation, we change the scope where our logic is, and use technices to pass information in between these scopes.
				   By code scope I mean where the execution of the code takes place. The executing code can be within:
				   		a this class file you are reading now, or any function thereof. (highlest level)
				   			b within the class file of the MXunit generated output, or any function thereof
				   				c within the class file of the componenet under test, or any function thereof
				   					d Within the class file of a dependency of the component under test, or any function thereof
				   						e Any further child object
					
					Pay attention to the scope of the operating logic. Sometimes say within scope b, the componenet under test, we will have hard coded a variable from scope A.
					Variables surrounded by single #'s (ex. #variable#) mean that we are defining a variable in the parent scope for text output into the child scope. Double pounds
					(ex. ##variable##) means that we want to reference a variable in the outputted text. 


				2. Injecting values, objects and methods into components using closures - The primary method of changing internal state of a component under test or of its 
				   dependencies is to define a closure on the public interface of the component and then call that closure, passing in the values of the outside scope
				   where the function body of the closure will then operate on the internal scope of the object. All closures opperate within the scope of the component 
				   that they are assigned to. 

				3. Including the specification document within the generated MXunit test case, the component under test, or any dependency - 
				   The specification format allows defining functions in line in numerous places. In order for calls of these functions to work, the functions
				   must be cfincluded into the scope of the code calling the functions. If they are not, but are instead passed in from the outside, they seem to not
				   be reachable. This is some extra work and duplication, but unavoidable. 

				4. A primary goal was to reduce the amount of redundant code generated in the compiled test so that it is actually human readable. 
				   As such, most use of the logic of interacting with the spec document is in the outside scope, in this compiler class. However on occassion and mentioned
				   about in point 3.), sometimes the spec needs to be embedded and accessed within another objects scope. 

				5. Text output helper - In order to make formatting of the final text easier to generate and read, we have a couple extra output helpers: 

					o(required string) - 'o' stands for output and echo's the string it contains. It also clears any tabs in the string and sets the number of tabs it should have at the beginning
						  of the line. In general for best output, o() should only be used one line at a time for each line of source code generated. o() will also output the line number
						  of this file into the generated code so that you can see where the line came from. 
					tab(required count) - Sets and outputs the number of tab chatacters specified by the count. Useful in aligning code in the generated output
					nl() - Creates a newline in the generated output



		*/
		try {
			savecontent variable="output"{

			o('component extends="mxunit.framework.testCase" {');
			nl()
				//Component Body
				tab(1)
				o('public function setup(){')
					tab(2);
					o('var spec = "";');
					o('/*We need to import the spec in order to call the setup function because any functions within the spec')
					o('dont seem to return unless they are loaded within the scope of the caller*/')
					o('include template="#variables.specFilePath#";')
					o('variables.spec = spec')

					if(structKeyExists(spec,"setup"))
					{
						o('spec.setup();')
					}
					tab(0);tab(1);
					o('}')
					nl()

				var metaData = getComponentMetaData(spec.class);
				//writeDump(metaData);
				//abort;
				//If the spec describes a persistent entity, then we can automatically build out tests to test the 
				//entity methods
				if(structKeyExists(metaData,"persistent") and metaData.persistent IS true)
				{
					var entityTester = new entityTester(spec.class);
					var entityName = entityTester.getEntityName();
					var simpleProps = entityTester.getSimpleProperties();
					/* First we want to test the basic methods: entityNew, entitySave, entityDelete
					we will accomplish this by getting all of the simple properties (non relationships and non identities)
					and using those properties to populate the calls
					*/
					
					//Test the entityNew function
					o('public function entityNew_Should_create_new_entity(){')
						tab("+1");
						o('var #entityName# = entityNew("#entityName#");')
						for(var prop in simpleProps)
						{
							o('#entityName#.set#prop.name#("#prop.specTestValue#");')
						}
						o('entitySave(#entityName#);')
						o('ORMFlush();')
						o('entityDelete(#entityName#);')
						o('ORMFlush();')
						tab("-1");
					o('}')
					//writeDump(simpleProps);
					//abort;

				}
					
				for(name in spec.tests)//For each of the tested functions
				{
					if(structKeyExists(spec.tests[name],"setup"))
					{
						//Duplicate the test so that we can delete values without affecting the original
						func = duplicate(spec.tests[name]);
						//Delete the seutp function which is only going to leave the contexts under test
						structDelete(func,"setup");
					}	
					else{
						func = spec.tests[name];
					}			
					
					for(context in func)//For each of the contexts for this function that we are testing
					{
						clean = replace(context," ","_","all");//Clean up the name so that we can use it

						o('public function #name#_#clean#(){');
						//Function body	
						tab(2);
						if(structKeyExists(spec.tests[name],"setup"))
						{
							o('//Get the setup function for the test')
							o('var testSetup = variables.spec.tests.#name#.setup')
							o('//Call the setup function for the test')
							o('testSetup()')
							
						}
						
						
						
						if(structKeyExists(spec,"factory"))							
						{
							o('//A factory was defined in the test and so we call it. The factory is defined if the component under test has a special creation routine other than just "new"')
							o('var test = variables.spec.factory();')
						}
						else
						{
							o('//Create the object that needs to be called')
							o('var test = new #spec.class#()')
						}
						
						o('//Set the portion of the spec under test into the the test object so that we can use any values within the spec within the scope of the component under test')
						o('test.setSpec = function(spec){')
							tab("+1");
							o('variables.spec = arguments.spec;')
							tab("-1");
							o('}')
						o('test.setSpec(variables.spec.tests.#name#["#context#"]);')

						o('test = new cfspec.core.spec.mockBuilder(test,"#variables.specFilePath#","#name#","#context#")')

						/*if(structKeyExists(spec,"mockObjects"))
						{
							mocks = spec.mockObjects;//The objects within the component under test that need to be mocked
							o('//Create a closure on the object to that we can mock out the dependencies. This allows us to access the internal scope of the object at runtime')
							o('test.mockOverride = function(variableName){variables[##arguments.variableName##] = new cfspec.core.mock(variables[##arguments.variableName##]);};')
							
							for(var mock in mocks)
							{
								o('//Override the #mock# object within the component under test with a mock version')
								o('test.MockOverride("#mock#");');nl();tab(2);
							}
						}*/
						

						/* WHEN keyword - Defines the variables that must exist within the component or in other scopes. Then WHEN represents the 'state' of the componet or environment 
						when under test.*/
						
						/*
						if(structKeyExists(func[context],"when"))
						{
							when = func[context].when;//The state of the system under test
							o('//Create a closure on the object so that we can overwrite variables that may exist within the object. We need to perform the override within the scope')
							o('//of the component under test because the variables may be in any valid coldfusion scopes, variables, request, session, etc')
							o('test.overrideVariable = function(variableName){')
								tab(3);		
								o('//We need to import the spec into the internal scope of the component under test in order to call functions conainted with the spec. Any functions within the spec')
								o('//error for not being found unless they are loaded within the scope of the caller.')
								o('include template="#variables.specFilePath#";')

								o('//Get the value of the variable as described in the spec')
								o('var value = spec.tests.#name#["#context#"].when["##variableName##"];')
								o('//Set the value of the variableName passed in with the value obtained from the spec')
								o('evaluate("##variableName## = value");')
								tab(2);
							o('}');
							nl(2);tab(2);

							//Overwrite any other variables as defined in the spec
							for(varName in when)
							{
								o('//Call the overriding function to ovverride this variable')
								o('test.overrideVariable("#varName#");')
							}
						}
						*/


						/* WITH keyword - Defines the function overrides for the collaborating objects that we are working with. There are multiple ways that we can mock out the collaborators:

							1. Default Mock - If the dependency was described as a MockObject in the spec, then all of the dependencies functions will return nothing. We therefore need to 
											  override the functions that we want to return something, described below
								2. Simple Override - We can tell the function to return a simple value by specifying in the spec the value that it should return. 
								3. Function Override - Give the mock function a full new function. This is most similar to traditional mocking where you mock out the function with a replacement
								4. Impersonate Test - Tell the mock to impersonate a specific specification of the real object. This allows the mock to adhere to the real API but return 
													  fake values, and also not have to specify this mock scneario multiple times.

							 */



						/*
						if(structKeyExists(func[context],"with"))
						{

							o('test.mockFunction = function(mockObject,mockFunction,mockValuePath){')
								tab(3);
								o('include template="#variables.specFilePath#"')
								o('var value = evaluate("spec.##mockValuePath##")')
								o('variables[arguments.mockObject].method(arguments.mockFunction).returns(value);')
							tab(2);
							o('}')
							nl();

							var MockedFunctions = func[context].with;
								
							//Mock any methods which were requests to be mocked
							for(var mockFunc in mockedFunctions)
							{
								var mockObject = listFirst(mockFunc,".");
								var mockFunction = listLast(mockFunc,".");

								//If it is a simple value then we can just pass in the value 
								if(isSimpleValue(mockedFunctions[mockFunc]))
								{	
									o('var mockValuePath = ''tests.#name#["#context#"].with["#mockFunc#"]''')
									o('test.mockFunction("#mockObject#","#mockFunction#",mockValuePath) ;'); //Return it as a string
								}

								else if(isStruct(mockedFunctions[mockFunc]) AND structKeyExists(mockedFunctions[mockFunc],"impersonateTest")) 
								{
									//We need a real mock for this function that uses the real function call and real object
										o('test.impersonateTest = function(required mockObjectName){')
											tab(3);
											o('//Get the specification of the real object so that we can determine what needs to be mocked')
											o('realMockPath = variables[arguments.mockObjectName].getRealComponentPath();')
											o('specPath = replace(realMockPath,".","/","all");')
											
											o('//Build the spec of the object')
											o('include template="/##lcase(specPath)##.spec";')

										
											o('//Call the factory method from the spec to build the object')
											o('newObject = spec.factory();')

											o('//Set the spec into the object as we may need to use it later')
											o('newObject.setSpec = function(spec){')
												o('variables.spec = arguments.spec;')
											o('}')
											
											o('newObject.setSpec(spec);')

											o('if(structKeyExists(spec,"mockObjects")){')
												tab("+1")
												o('//Get the objects that we are going to need to mock out from the spec')
												o('mocks = spec.mockObjects;')

												o('//Create a function that we can pass in the overrides to')
												o('newObject.mockOverride = function(variableName){variables[##arguments.variableName##] = new cfspec.core.mock(variables[##arguments.variableName##]);}')

												o('//Overwrite any of the objects dependencies with mocks as specified in the spec')
												o('for(var mock in mocks)')
												o('{')
													o('//Call overriding mock')
													o('newObject.MockOverride("##mock##");')
												o('}')
												tab("-1")
											o('}')
										

											o('//Get the specification of the test that we are impersonating, which will tell us what methods need to be mocked')
											o('impersonatedTest = spec.tests["#mockFunction#"]["#mockedFunctions[mockFunc].impersonateTest#"];')

											o('newObject.setImpersonatedTest = function(impersonatedTest){')
												o('variables.impersonatedTest = arguments.impersonatedTest;')
											o('}')
											o('newObject.setImpersonatedTest(impersonatedTest);')
											
											o('//Create an override so that we can mock out the method retruns of the mocks')
											o('newObject.mockFunction = function(mockObject,mockFunction,value){')
												o('variables[arguments.mockObject].method(arguments.mockFunction).returns(evaluate(arguments.value));')
											o('}')

											o('//Override the methods on the mock based on the specification.')
											o('//TODO - Right now the second level mock only allows simple values. If this mock itself depends on a third level mock, we will need to')
											o('//add support for that later. We can accomplish it by looking the third level mock and merely retruning the return value of the third level')
											o('for(newMock in impersonatedTest.with)')
											o('{')
												o('newMockObject = listFirst(newMock,".");')
												o('newMockFunction = listLast(newMock,".");')
												o('newMockValue = impersonatedTest.with[newMock];')
												o('newObject.mockFunction(newMockObject,newMockFunction,serialize(newMockValue));')
												
											o('}')

											o('//Now that we have setup the new object and its mocks, we need to override the newObject method with a proper')
											o('//innvocation of the method based on the specification. We save the real method into a new method name') 
											o('newObject._#mockFunction# = newObject.#mockFunction#;')

											o('//No we overrite the real method so that we can proxy to the old method and pass in the correct parameters')											
											o('newObject.#mockFunction# = function(){')

												
												
												

												
												
												o('//Create a closure on the object so that we can overwrite variables')
												o('this.override = function(variableName,value){')
														o('if(listFirst(arguments.variableName,".") IS "request")')
														o('{')
															o('var remainder = listDeleteAt(arguments.variableName,1,".");')
															o('request[remainder] = arguments.value')
														o('}')
														o('else')
														o('{')
															o('##arguments.variableName## = arguments.value;')	
														o('}')
														
													o('}')
												o('if(structKeyExists(variables.impersonatedTest,"when")){')
													tab(4)
													o('//Get the predicates that need to be setup')
													o('when = variables.impersonatedTest.when;')
													o('//Overwrite any other variables as defined in the spec')
													o('for(varName in when)')
													o('{')
														tab(5);
														o('//Call overriding functions')
														o('this.override("##varName##",##serialize(when[varName])##);')
													tab(4);
													o('}')
												tab(3);
												o('}')
												o('//Call the function that we duplicated')

												o('if(structKeyExists(variables.impersonatedTest,"given")){')
													tab("+1")
													o('if(isClosure(variables.impersonatedTest.given)){')
														tab("+1")
														o('//Get the parameters that need to be passed into the function')
														o('given = variables.impersonatedTest.given();')
														tab("-1")
													o('} else{')
														tab("+1")
														o('given = variables.impersonatedTest.given;')
														tab("-1")
													o('}')
													tab("-1")
												o('}')

												o('result = this._checkEmailExists(argumentCollection=given);')


												o('if(result IS NOT impersonatedTest.then.returns)')
												o('{')
													o('throw(message="The collaborator return value from ##variables.spec.class## did not match its specification. It should have returned ##impersonatedTest.then.returns## but returned ##result ##. The tested specification was: #mockFunction# ''#mockedFunctions[mockFunc].impersonateTest#''");')
												o('}')

												o('return result;')
											o('}')
											
											o('//Set the new object into the')
											o('variables[arguments.mockObjectName] = newObject;')


										o('};');
									o('test.impersonateTest("#mockObject#");');
								}
								else
								{	
									
									o('var mockValuePath = "tests.#name#[""#context#""].with[""#mockFunc#""]"')
									o('test.mockFunction("#mockObject#","#mockFunction#",mockValuePath);');
									
								}
								
								
							}
						}*/



						if(structKeyExists(func[context],"given"))
						{

							args = func[context].given;//The arguments given to the test
							
							if(isClosure(args))
							{
								args = args();
							}
							//Serialize any arguments which are intended
							o('coll = #serialize(args)#;');
							//Call the method under test
							o('var testResult = test.#name#(argumentCollection=coll);');
						}
						else
						{
							//Call the method under test
							o('var testResult = test.#name#();');
						}

						if(structKeyExists(func[context],"cacheResult") AND func[context].cacheResult IS true){
							var cacheKey = hash(name & context);
							o('new cfspec.core.spec.specCache().put("#cacheKey#",testResult)');
						}					
						
						o('//Assert facts based on the specification''s "then" attribute')
						if(structKeyExists(func[context],"then"))
						{
							facts = func[context].then
							for(fact in facts)
							{
								if(fact IS "returns")
								{
									o('var assertValue = variables.spec.tests.#name#["#context#"].then.returns')
									if(facts[fact] IS "void")
									{
										o('assert(NOT isDefined("testResult"),"Result returned a value but the specification expected to return void")')
									}
									else if(facts[fact] CONTAINS "is")
									{
										var compareType = replace(facts[fact],"is","");
										var type = serialize(createObject("component","getType"));
										o('var getType = evaluate("#type#")')
										o('var type = getType.init(testResult)')
										o('assert(type IS "#compareType#","The result from the function call #name# was of type ##type## but the specification expected to return a #compareType#")')	
									}
									else
									{
										o('assert(testResult IS assertValue,"The result from the function call #name# returned the value ##testResult## but the specification expected the value ##assertValue##")')
									}
									
									
								}
								else if(fact IS "assert")
								{
									for(var test in facts[fact])
									{
										if(isStruct(test))
										{
											o('assert(evaluate("#test.value#"),"#test.message#");');
										}
										else{
											o('assert(evaluate("#test#"));');	
										}
										
										
									}
								}
							}
						}
						

						
						tab(1);o('}')//Ending function tab
						nl();
					}

				}

						nl();
					tab();
					
			nl();
			echo('}');//Ending component Tag

			}
		}
		catch(any e){
			writeDump(entityName);
			writeDump(metaData);
			writeDump(spec);
			writeDump(e);
		}

		//Get the file path by first removing the last element
		
		fileWrite(finalCompilePath,output);
		return spec;
	}

	private function buildContext(required context)
	{

	}

	/*private function verifySchema(spec)
	{
		//Import the schema
		include template="specSchema.spec";

		schemaNodes = schema.children;
		specNodes = spec;

		for(node in nodes)
		{
			if(nodes[node].required)
			{
				if(NOT structKeyExists(specNodes[node]))
				{
					throw(message="Schema error for specification, element #node# is required");
				}
			}
		}

	}*/

	private function tab(count=1){
		
		if(count CONTAINS "+")
		{
			count = variables.lastTab + replace(count,"+","");
		}

		if(count CONTAINS "-")
		{
			count = variables.lastTab - replace(count,"-","");
		}

		var result = "";
		for(i=1; i LTE count; i = i+1)
		{
			result = result & chr(9);
		}
		variables.lastTab = count;
		return echo(result);
	}

	private function nl(count=1){
		var result = "";
		for(i=1; i LTE count; i = i+1)
		{
			result = result & chr(10);
		}
		return echo(result);
	}

	private function ln(text){
		return echo("//#text# #chr(10)#");
	}

	private function o(string)
	{
		
		//Remove all Tabs
		output = replaceNoCase(string,chr(9),"","all");
		//Remove all new lines
		//output = replaceNoCase(output,chr(10),"","all");
		//Remove all Windows new lines
		//output = replaceNoCase(output,chr(10)&chr(13),"","all");
		
		nl();
		tab(variables.lastTab);
		lineNumber = callStackGet()[2].lineNumber;
		//writeDump(callStackGet());
		//abort;
		if(variables.debugging)
		{
			output = output & " //#lineNumber#";
		}
		return echo(output);
	}

	

	
}