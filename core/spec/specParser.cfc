/**
*
* 
* @author  Rory Laitila
* @description Parses a JSON Spec into a runnable MXunit test
*
*/

import writeFileAndDirectories;
component accessors="true" {

	property name="compilePath";
	property name="specFilePath";
	property name="timeForDirectory";
	property name="specFileList";

	public function init(){
		variables.lastTab = 0;
		variables.debugging = true;
		return this;
	}

	public function parseSpec(required filePath, outputPath)
	{	
		writeLog(file="cfspec",text="Start parseSpec");
		var specFileName = listGetAt(arguments.filePath,listLen(arguments.filePath,"/"),"/");
		var componentUnderTestDirectoryPath = replace(arguments.filePath,specFileName,"");
		var componentUnderTestFileName = replace(specFileName,".spec","");
				
		var finalCompileDirectory = arguments.outputPath & componentUnderTestDirectoryPath;
		
		//Create the directory and all directories if they do not exist
		if(NOT directoryExists(finalCompileDirectory))
		{
			directoryCreate(finalCompileDirectory,true);	
		}
		
		var finalCompilePath = finalCompileDirectory & "/#componentUnderTestFileName#Tests.cfc";
		
		variables.specFilePath=arguments.filePath;
		var spec = "";
		include template="#variables.specFilePath#";
		writeLog(file="cfspec",text="End parseSpec");
		return _parseSpec(spec,finalCompilePath);
	}

	public function parseAllSpecs(required specDirectory, required outputPath, ignore=[])
	{
		writeLog(file="cfspec",text="Start parseAllSpecs");
		if(structKeyExists(url,"reloadFiles") OR NOT structKeyExists(application,"specFiles"))
		{
			application.specFiles = getSpecFiles(arguments.specDirectory,arguments.ignore,"%.spec%");
			variables.specFileList = application.specFiles;
		}
		else
		{
			variables.specFileList = application.specFiles;
		}

		for(var file in application.specFiles)
		{
			try{
				parseSpec(file.path,arguments.outputPath);	
			}
			catch(any e)
			{
				writeDump(e);
				abort;
			}
			
		}
		writeLog(file="cfspec",text="End parseAllSpecs");
		return this;
	}

	private function getSpecFiles(required mapping,ignore=[],required filter){
		writeLog(file="cfspec",text="Start getSpecFiles");
		var output = [];

		//var files = directoryList(expandPath(arguments.mapping),false,"query");
		
		var files = getDirectoryFiles(expandPath(arguments.mapping),arguments.ignore,arguments.filter);
		
		for(i=1;i LTE files.recordCount; i=i+1)
		{
			template = files["name"][i];
			finalpath = replace(files["directory"][i],expandPath(mapping),"");
			
			//finalpath = replace(finalpath,"/",".","all");
			//finalpath = replace(finalpath,"\",".","all");
			arrayAppend(output,{file=template,path="#mapping##finalPath#/#template#"});
			//output[template].path = "#mapping##finalPath#/#template#";
		}
		writeLog(file="cfspec",text="End getSpecFiles");
		return output;
	}

	private function getDirectoryFiles(path,ignore=[],filter="%.spec%")
	{
		local.start = getTickCount();
		local.directories = directoryList(arguments.path,false,"query");
		variables.timeForDirectory = queryNew("path,time");
		//Append the fileName to the directory
		local.directories.addColumn("fullpath");
		for(local.i = 1; local.i LTE local.directories.recordCount; local.i++) {
			local.directories.fullPath[i] = "#local.directories.directory[i]#/#local.directories.name[i]#";
		}		
		
		//Get the files/directories that are not ignored
		query name="local.clean" dbtype = "query" {
			echo("SELECT * from local.directories WHERE 1=1");
			for(match in arguments.ignore)
			{
				echo("AND fullpath NOT LIKE '#match#'");
			}
		}

		//Get the files
		query name="local.files" dbtype = "query" {
			echo("SELECT * from local.clean WHERE type = 'File' AND name LIKE '#arguments.filter#'");
		}

		//Get the directories
		query name="local.dirs" dbtype = "query" {
			echo("SELECT * from local.clean WHERE type = 'Dir'");
		}

		loop query="#local.dirs#"{
			//writeDump("#directory#/#name#");

			local.newfiles = getDirectoryFiles("#directory#/#name#",arguments.ignore,arguments.filter);

			query name="local.files" dbtype="query"{
				echo("SELECT * FROM local.files
					  UNION ALL 
					  SELECT *
					  FROM local.newFiles");
			}
		}
		local.end = getTickCount();
		variables.timeForDirectory.addRow([arguments.path, (local.end - local.start) / 1000]);

		return local.files;
	}

	private function _parseSpec(specObject,compilePath){
		
		writeLog(file="cfspec",text="Start _parseSpec");
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
		var spec = arguments.specObject;

		if(structKeyExists(spec,"URL"))
		{
			local.output = buildHTTPSpec(spec);
		}
		else{
			try {
				local.output = buildClassSpec(local.spec);
			}
			catch(any e){
				
				writeDump(arguments);
				writeDump(spec);
				writeDump(e);
				abort;
			}
		}

		

		//Get the file path by first removing the last element
		writeLog(file="cfspec",text="End _parseSpec");
		fileWrite(arguments.compilePath,local.output);
		return spec;
	}

	private function buildBeforeTests(required struct spec)
	{
		local.spec = arguments.spec
		o('public function beforeTests(){')
			tab(2);
			o('var spec = "";');
			o('/*We need to import the spec in order to call the setup function because any functions within the spec')
			o('dont seem to return unless they are loaded within the scope of the caller*/')
			o('include template="#variables.specFilePath#";')
			o('variables.spec = spec')

			//If There is a setup function defined in the spec
			if(structKeyExists(spec,"setup"))
			{
				o('//Call the setup function that is defined in the spec')
				o('spec.setup();')
			}
			tab(0);tab(1);
			o('}')
			nl()
	}

	private string function buildHTTPSpec(required struct spec)
	{
		local.spec = arguments.spec;
		savecontent variable="local.output"{
			tab(0);
			o('component extends="cfspec.core.spec.testCase" {');
			nl()
				//Component Body
				tab(1)
				buildBeforeTests(local.spec);

				for(local.uri IN spec.tests)
				{
					//These keywords are not actually URIs and so they can be skipped
					if(local.uri IS "setup" OR local.uri IS "before" OR local.uri IS "after" OR local.uri IS "factory"){
						continue;	
					}

					for(local.method IN spec.tests[local.uri])
					{
						//These keywords are not actually methods and so they can be skipped
						if(local.method IS "setup" OR local.method IS "before" OR local.method IS "after" OR local.method IS "factory"){
							continue;	
						}

						for(local.context IN spec.tests[local.uri][local.method])
						{
							//These keywords are not actually scenarios and so they can be skipped
							if(local.context IS "setup" OR local.context IS "before" OR local.context IS "after" OR local.context IS "factory"){
								continue;	
							}

							//Setup at the all tests level
							if(structKeyExists(spec.tests,"setup"))
							{
								o('//Get the setup function for the test')
								o('var allTestsSetup = variables.spec.tests.setup')
								o('//Call the setup function for the test')
								o('allTestsSetup()')							
							}

							//Setup at the specific function test level
							if(structKeyExists(spec.tests[local.uri],"setup"))
							{
								o('//Get the setup function for the test')
								o('var uriTestSetup = variables.spec.tests.#name#.setup')
								o('//Call the setup function for the test')
								o('uriTestSetup()')							
							}

							//Setup at the context level
							if(structKeyExists(spec.tests[local.uri][local.method],"setup"))
							{
								o('//Get the setup function for the test')
								o('var methodTestSetup = variables.spec.tests.#name#["#context#"].setup')
								o('//Call the setup function for the test');
								
								o('methodTestSetup()')
							}

							//Setup at the context level
							if(structKeyExists(spec.tests[local.uri][local.method][local.context],"setup"))
							{
								o('//Get the setup function for the test')
								o('var contextTestSetup = variables.spec.tests.#name#["#context#"].setup')
								o('//Call the setup function for the test');
								
								o('contextTestSetup()')
							}

							local.clean = cleanURI(local.uri & local.context);

							o('public function #local.method#_#local.clean#(){');
								tab("+1");
								o('test = new cfspec.core.spec.httpTester(specPath="#variables.specFilePath#", method="#local.method#", resource="#local.uri#", scenario="#local.context#")');
								o('test.doHTTPCall();')
								tab("-1");
							o('}')
							nl();
						}
					}
				}


				tab(-1);
			nl();
			echo('}');//Ending component Tag
		}

		return local.output;
	}

	private function cleanURI(required string URI)
	{
		local.output = arguments.uri;
		local.output = replaceNoCase(local.output,"?","","all");
		local.output = replaceNoCase(local.output,"/","_","all");
		local.output = replaceNoCase(local.output,"=","_","all");
		local.output = replaceNoCase(local.output,".","_","all");
		local.output = replaceNoCase(local.output,"&","_","all");	
		local.output = replaceNoCase(local.output,"{","_","all");	
		local.output = replaceNoCase(local.output,"}","_","all");
		local.output = replaceNoCase(local.output," ","_","all");
		return local.output;
	}


	private string function buildClassSpec(required struct spec)
	{
		local.spec = arguments.spec;
		savecontent variable="local.output"{

			o('component extends="cfspec.core.spec.testCase" {');
			nl()
				//Component Body
				tab(1);
				buildBeforeTests(local.spec);

				if(structKeyExists(spec,"class"))
				{
					var metaData = getComponentMetaData(spec.class);					
					//If the spec describes a persistent entity, then we can automatically build out tests to test the 
					//entity methods
					if(structKeyExists(metaData,"persistent") and metaData.persistent IS true)
					{
						buildEntityTests(local.spec);					
					}
				}				
					
				for(var name in spec.tests)//For each of the tested functions defined in the specification
				{
					//These keywords are not actually tests and so they can be skipped
					if(name IS "setup" OR name IS "before" OR name IS "after" OR name IS "factory"){
						continue;	
					}
					
					//IF there was a setup function specified, it was used above. But now we need to delete it as we don't need it for the tests
					if(structKeyExists(spec.tests[name],"setup"))
					{
						//Duplicate the test so that we can delete values without affecting the original
						var func = duplicate(spec.tests[name]);
						//Delete the seutp function which is only going to leave the contexts under test
						structDelete(func,"setup");
					}	
					else{
						var func = spec.tests[name];
					}

					for(var context in func)//For each of the contexts for this function that we are testing
					{						
						//Skip any before contexts as they should not be called
						if(context IS "before" OR
						   context IS "after"){
							continue;	
						}

						var clean = replace(context," ","_","all");//Clean up the name so that we can use it

						o('public function #name#_#clean#(){');
						//Function body	
						tab(2);
							o('request.mockDepth = 0');
							o('request.funcCounts = {}');

						//Setup at the all tests level
						if(structKeyExists(spec.tests,"setup"))
						{
							o('//Get the setup function for the test')
							o('var allTestsSetup = variables.spec.tests.setup')
							o('//Call the setup function for the test')
							o('allTestsSetup()')							
						}

						//Setup at the specific function test level
						if(structKeyExists(spec.tests[name],"setup"))
						{
							o('//Get the setup function for the test')
							o('var functionTestSetup = variables.spec.tests.#name#.setup')
							o('//Call the setup function for the test')
							o('functionTestSetup()')							
						}

						//Setup at the context level
						if(structKeyExists(spec.tests[name][context],"setup"))
						{
							o('//Get the setup function for the test')
							o('var contextTestSetup = variables.spec.tests.#name#["#context#"].setup')
							o('//Call the setup function for the test');
							
							o('contextTestSetup()')
						}

						/* Manual MXUnit Test Override - There are some instances where we cannot use the
						cfspec testing libary to finish the test. (like when testing aspects of the testing framework itself)
						In these instances we can override the normal test paramters and prive a fully completed
						function which will be run to test
						*/
						if(structKeyExists(spec.tests[name][context],"mxunit"))
						{
							o('//Get the only test function for this test')
							o('var mxUnitOverride = variables.spec.tests.#name#["#context#"].mxUnit')
							o('//Call the mxunit test function')
							o('mxUnitOverride();')
							tab("-1");
							o('}');
							continue;
						}


						/* FACTORY - We only want to call the factory once. As such, we check each 
						level, starting from the scenario. If it has a factory, we use it. If not, we check the level
						higher. If we do not find a factory, then we generate the object like normal*/
		
						if(structKeyExists(spec.tests[name][context],"factory"))
						{
							o('//A factory was defined in the test and so we call it. The factory is defined if the component under test has a special creation routine other than just "new"')
							o('var test = variables.spec.tests["#name#"]["#context#"].factory();')
						}
						else if(structKeyExists(spec.tests[name],"factory"))
						{
							o('//A factory was defined in the test and so we call it. The factory is defined if the component under test has a special creation routine other than just "new"')
							o('var test = variables.spec.tests["#name#"].factory();')
						}
						else if(structKeyExists(spec.tests,"factory"))
						{
							o('//A factory was defined in the test and so we call it. The factory is defined if the component under test has a special creation routine other than just "new"')
							o('var test = variables.spec.tests.factory();')
						}
						else if(structKeyExists(spec,"factory"))
						{
							o('//A factory was defined in the test and so we call it. The factory is defined if the component under test has a special creation routine other than just "new"')
							o('var test = variables.spec.factory();')
						}
						else{
							if(name IS "init") //Functions that we are testing with the name init, need to be created with createObject or the init() will be called prematurely
							{
								o('//Create the object that needs to be called')
								o('var test = createObject("#spec.class#")')
							}
							else
							{
								o('//Create the object that needs to be called')
								o('var test = new #spec.class#()')
							}
						}
						
						
						o('//Set the portion of the spec under test into the the test object so that we can use any values within the spec within the scope of the component under test')
						o('test.setSpec = function(spec){')
							tab("+1");
							o('variables.spec = arguments.spec;')
							tab("-1");
							o('}')
						o('test.setSpec(variables.spec.tests.#name#["#context#"]);')

						o('//Pass the component under test to the mockBuilder. The mock builder will mock out state and dependencies as described by the spec')
						o('test = new cfspec.core.spec.mockBuilderNew(test,"#variables.specFilePath#","#name#","#context#")')
						
						o('var testResult = test.#name#();');
						
						o('//Assert facts based on the specification''s "then" attribute')
						if(structKeyExists(func[context],"then"))
						{
							var facts = func[context].then
							for(var fact in facts)
							{
								if(fact IS "returns")
								{
									o('var assertValue = variables.spec.tests.#name#["#context#"].then.returns')
									if(facts[fact] IS "void" OR facts[fact] IS "isVoid")
									{
										o('assert(NOT isDefined("testResult"),"Result returned a value but the specification expected to return void")')
									}
									else if(facts[fact] CONTAINS "isString" 
														OR facts[fact] CONTAINS "isStruct"
														OR facts[fact] CONTAINS "isArray"
														OR facts[fact] CONTAINS "isNumeric"
														OR facts[fact] CONTAINS "isBoolean"
														OR facts[fact] CONTAINS "isDate"
														OR facts[fact] CONTAINS "isQuery"
														OR facts[fact] CONTAINS "isJson"
														OR facts[fact] CONTAINS "isXml"
														OR facts[fact] CONTAINS "isBinary"
														OR facts[fact] CONTAINS "isClosure"
														OR facts[fact] CONTAINS "isCustomFunction"
														OR facts[fact] CONTAINS "isImage"
														OR facts[fact] CONTAINS "isObject"
														)
									{
										var compareType = replace(facts[fact],"is","");
										var type = serialize(createObject("component","getType"));
										o('var getType = evaluate("#type#")')
										o('var type = getType.#facts[fact]#(testResult)');
										o('assert(type,"The result from the function call #name# was not the right type, the specification expected to return a #compareType#")')	
									}
									else if(facts[fact] CONTAINS "isError") //If we are expecting an error, then the mockProxy will return true if the error happened
									{
										o('assert(testResult)');
									}
									else if(facts[fact] CONTAINS "isNotDefined")
									{
										o('assert(NOT isDefined("testResult"))');
									}
									else if(facts[fact] CONTAINS "any")
									{
										o('//Spec allows return type of any, so do nothing');
									}
									else
									{
										o('assert(testResult IS assertValue,"The result from the function call #name# returned the value ##testResult## but the specification expected the value ##assertValue##")')
									}									
									
								}
								/*else if(fact IS "assert")
								{
									for(var i=1; i LTE arrayLen(facts[fact]); i=i+1)
									{
										var test = facts[fact][i];
										if(isStruct(test))
										{
											if(isClosure(test.value))
											{
												o('var assertValue = variables.spec.tests.#name#["#context#"].then.assert[#i#].value(testResult)')
												o('assert(assertValue);');
											}
											else
											{
												o('assert(evaluate("#test.value#"),"#test.message#");');
											}
										}
										else{
											o('assert(evaluate("#test#"));');	
										}
										
										
									}
								}*/

								else if(fact is "assertTrue")
								{
									if(isClosure(facts[fact]))
									{
										o('assertValue = variables.spec.tests.#name#["#context#"].then.returns')
										o('assert();');	
									}
								}
							}
						}

						/*if(structKeyExists(func[context],"after") AND isClosure(func[context].after))
						{
							o('//Call the after function that was specified')
							o('variables.spec.tests["#name#"]["#context#"].after(test)')
						}*/
						

						
						tab(1);o('}')//Ending function tab
						nl();
					}

				}

						nl();
					tab();

				//Component Body
				tab(1)
				o('public function afterTests(){')
					tab(2);
					o('var spec = "";');
					o('/*We need to import the spec in order to call the setup function because any functions within the spec')
					o('dont seem to return unless they are loaded within the scope of the caller*/')
					o('include template="#variables.specFilePath#";')
					o('variables.spec = spec')

					//If There is a setup function defined in the spec
					if(structKeyExists(spec,"tearDown"))
					{
						o('//Call the setup function that is defined in the spec')
						o('spec.tearDown();')
					}
					tab(0);tab(1);
					o('}')
					nl();
					
			nl();
			echo('}');//Ending component Tag

			}
		return local.output;
	}

	private function buildEntityTests(required struct spec)
	{
		var entityTester = new entityTester(listLast(spec.class,"."));
		var entityName = entityTester.getEntityName();
		var simpleProps = entityTester.getSimpleProperties();
		
		/* First we want to test the basic methods: entityNew, entitySave, entityDelete
		we will accomplish this by getting all of the simple properties (non relationships and non identities)
		and using those properties to populate the calls
		*/
		
		//Test the entityNew function
		o('public function entityNew_Should_create_new_entity(){')
			tab("+1");
			o('var #entityName#1 = entityNew("#entityName#");')
			for(var prop in simpleProps)
			{
				if(isSimpleValue(prop.specTestValue))
						{
							o('#entityName#1.set#prop.name#("#prop.specTestValue#");')							
						}
						else
						{
							o('#entityName#1.set#prop.name#(#serialize(prop.specTestValue)#);')	
						}
				
			}
			o('entitySave(#entityName#1);')
			o('ORMFlush();')
			o('entityDelete(#entityName#1);')
			o('ORMFlush();')
			tab("-1");
		o('}')

		/*Test Relationships
		Now we want to complete more advanced tests of the relationships
		*/
		local.relationships = entityTester.getRelationships();
		
		for(local.relation in local.relationships)
		{

			local.otherTester = new entityTester(local.relation.cfc);

			if(structKeyExists(local.relation,"singularname")){
				local.otherName = local.relation.singularname;
			} else {
				local.otherName = local.relation.name;
			}						

			local.otherSimpleProps = local.otherTester.getSimpleProperties();

			if(local.relation.fieldtype IS "one-to-many")
			{

				//Get the property that represents the other sie of this relation
				local.otherRelation = local.otherTester.getRelationshipReverseProperty(entityName, "many-to-one");

				o('public function oneToMany_should_add_the_relation_#entityName#_to_#local.otherName#2(){');
					tab('+1');
					o('//Create the first entity')
					o('var #entityName#1 = entityNew("#entityName#");')
					for(var prop in simpleProps)
					{
						if(isSimpleValue(prop.specTestValue))
						{
							o('#entityName#1.set#prop.name#("#prop.specTestValue#");')							
						}
						else
						{
							o('#entityName#1.set#prop.name#(#serialize(prop.specTestValue)#);')
						}
						
					}
					o('entitySave(#entityName#1);')

					o('//Create the second entity')
					o('var #local.otherName#2 = entityNew("#local.relation.cfc#");')
					for(var prop in otherSimpleProps)
					{									
						if(isSimpleValue(prop.specTestValue))
						{
							o('#local.otherName#2.set#prop.name#("#prop.specTestValue#");')										
						}
						else
						{
							o('#local.otherName#2.set#prop.name#(#serialize(prop.specTestValue)#);')
						}
					}
					

					o('//Set the first entity into the second')
					o('#local.otherName#2.set#local.otherRelation.name#(#entityName#1)')

					o('//Add the second entiry to the first')
					o('#entityName#1.add#local.otherName#(#local.otherName#2)')

					o('entitySave(#local.otherName#2);')
					o('ORMFlush()')

					o('//Delete the entities that were created')
					o('entityDelete(#entityName#1)');
					o('entityDelete(#local.otherName#2)')
					o('ORMFlush()');

					tab("-1")
				o('}')
			}
		}

		//writeDump(local.relationships);abort;
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
		
		local.count = arguments.count;
		if(arguments.count CONTAINS "+")
		{
			local.count = variables.lastTab + replace(count,"+","");
		}

		if(arguments.count CONTAINS "-")
		{
			local.count = variables.lastTab - replace(count,"-","");
		}

		var result = "";
		for(var i=1; i LTE local.count; i = i+1)
		{
			local.result = local.result & chr(9);
		}
		variables.lastTab = local.count;
		return echo(local.result);
	}

	private function nl(count=1){
		var result = "";
		for(var i=1; i LTE arguments.count; i = i+1)
		{
			local.result = local.result & chr(10);
		}
		return echo(local.result);
	}

	private function ln(text){
		return echo("//#arguments.text# #chr(10)#");
	}

	private function o(string)
	{
		
		//Remove all Tabs
		local.output = replaceNoCase(arguments.string,chr(9),"","all");
		//Remove all new lines
		//output = replaceNoCase(output,chr(10),"","all");
		//Remove all Windows new lines
		//output = replaceNoCase(output,chr(10)&chr(13),"","all");
		
		nl();
		tab(variables.lastTab);
		local.lineNumber = callStackGet()[2].lineNumber;
		//writeDump(callStackGet());
		//abort;
		if(variables.debugging)
		{
			local.output = local.output & " //#local.lineNumber#";
		}
		return echo(local.output);
	}

	

	
}