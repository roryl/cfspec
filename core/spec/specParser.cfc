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
		var componentUnderTestFullPath = listDeleteAt(filePath,listLen(filePath,"."),".");
		
		var componentUnderTestFileName = listGetAt(componentUnderTestFullPath,listLen(filePath,"/"),"/");
		
		componentUnderTestDirectoryPath = listDeleteAt(filePath,listLen(filePath,"/"),"/");
		
		
		if(structKeyExists(arguments,"outputPath"))
		{
			finalCompilePath = expandPath(outputPath) & componentUnderTestDirectoryPath;
		}
		else{
			finalCompilePath = expandPath(componentUnderTestDirectoryPath);	
		}

		//Create the directory and all directories if they do not exist
		if(NOT directoryExists(finalCompilePath))
		{
			directoryCreate(finalCompilePath,true);	
		}
		
		finalCompilePath = finalCompilePath & "/#componentUnderTestFileName#ParsedTests.cfc";
		
		variables.specFilePath=arguments.filePath;
		include template="#variables.specFilePath#";
		return _parseSpec(spec,finalCompilePath);
	}

	public function parseAllSpecs(required specDirectory, required root, required outputPath)
	{
		if(structKeyExists(url,"reloadFiles") OR NOT structKeyExists(application,"specFiles"))
		{
			application.specFiles = getSpecFiles("/affiliates","/var/www","*.spec");	
		}
		

		for(var file in application.specFiles)
		{
			try{
				parseSpec(application.specFiles[file].path,"/affiliates/tests");	
			}
			catch(any e)
			{
				writeDump(e);
			}
			
		}
		
		return application.specFiles;
	}

	private function getSpecFiles(required mapping,required root,required filter){
		var output = {};

		files = directoryList(expandPath(arguments.mapping),true,"query",arguments.filter);	
		
		for(i=1;i LTE files.recordCount; i=i+1)
		{
			template = replace(files["name"][i],".cfc","");
			finalpath = replace(files["directory"][i],root,"");
			//finalpath = replace(finalpath,"/",".","all");
			//finalpath = replace(finalpath,"\",".","all");

			output[template].path = "#finalPath#/#template#";
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
		lineNumber = callStackGet()[3].lineNumber;
		//writeDump(callStackGet());
		//abort;
		if(variables.debugging)
		{
			output = output & " //#lineNumber#";
		}
		return echo(output);
	}

	

	
}