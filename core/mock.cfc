/**
*
* @file  
* @author	Rory Laitila  
* @description 
*
*/

component accessors="true" {

	property name="component";
	property name="meta";
	property name="methodSignatures" type="struct";
	property name="methodReturns" type="struct";
	property name="lastMethodReturnName" hint="stores the last string set in the function call Method()";
	property name="lastMethodReturnState" default="";
	property name="methodCallCounts" type="struct" hint="Holds the number of times a method has been called";
	property name="mockSpec";
	property name="realComponentPath" hint="If the mocked object is a proxy, the real object is hidden which can interfere with introspection. We get the real path and save it for future use";

	

	public function init(required componentPath){
		
		//writeDump("#componentPath#");
		if(NOT isObject(arguments.componentPath)){
			variables.component = createObject("component",arguments.componentPath);	
		}
		else{
			variables.component = arguments.componentPath;
		}

		variables.meta = getMetaData(variables.component);
		variables.methodReturns = {};
		variables.methodSignatures = {};
		variables.lastMethodReturnState = "";
		
		//Set it to the current mocked full name. But this may be overridden when building out the methodSignatures if this mock is a proxy
		variables.realComponentPath=variables.meta.fullName;
		
		buildMethodSignatures();
		
		return this;
	}

	public function onMissingMethod(required missingMethodName,missingMethodArguments)
	{
		
		//Check if the function being called exists, if it does not then we need to throw an error
		if(NOT structKeyExists(methodSignatures,arguments.missingMethodName))
		{
			throw(message="Method #arguments.missingMethodName# does not exist in component #variables.meta.name#",type="Missing Method");
		}
		
		//Check that all of the methods parameters have been passed in
		var methodArguments = methodSignatures[arguments.missingMethodName].parameters;
		for(var i=1; i LTE local.methodArguments.len(); i=i+1)
		{

			//Check the arguments being passed in agains the types. There ae two options: Positional or Names
			if(arePositionalArguments(arguments.missingMethodArguments) or StructIsEmpty(arguments.missingMethodArguments))
			{
				var key = i;
			}
			else //Are Named arguments, we need to test these differently
			{
				var key = local.methodArguments[i].name;
			}

			if(local.methodArguments[i].required)
			{
				if(NOT structKeyExists(arguments.missingMethodArguments,local.key))
				{
					throw(type="Missing Argument",message="Argument #methodArguments[i].name# was required when calling #missingMethodName#() on #variables.meta.name# but was not passed in. Check the argument and make sure it was not a null value");
				}
				
			}
			//writeDump(variables.meta.name);
			//writeDump(missingMethodName);
			//writeDump(methodArguments[i].type);
			//writeDump(missingMethodArguments[key]);
			//writeDump(isType(methodArguments[i].type,missingMethodArguments[key]));



			if(isType(local.methodArguments[i].type,arguments.missingMethodArguments[local.key]) IS false)
			{	
				
				throw(type="Invalid Type",message="Argument #methodArguments[i].name# was of the wrong type when calling #missingMethodName#() on #variables.meta.name#, it must be of type: #methodArguments[i].type#");
			}
		}
		
		//Increment the number of times that we have called this method
		variables.methodCallCounts[arguments.missingMethodName] = variables.methodCallCounts[arguments.missingMethodName] + 1;

		//Finally if the method should specify a return value, we will call it
		if(structKeyExists(variables.methodReturns,arguments.missingMethodName))
		{
			if(isClosure(variables.methodReturns[arguments.missingMethodName]))
			{
				var result = variables.methodReturns[arguments.missingMethodName]();
			}
			else
			{
				var result = variables.methodReturns[arguments.missingMethodName];	
			}

			if(structKeyExists(variables.methodSignatures[arguments.missingMethodName],"returnType"))
			{

				var methodReturnType = variables.methodSignatures[arguments.missingMethodName].returnType
				
				if(isType(local.methodReturnType,result) IS false)
				{
					throw(type="Invalid Type",message="Return type was of the wrong type when calling #missingMethodName#() on #variables.meta.name#, it must be of type: #methodReturnType#");
				}	
			}

			return local.result;
			
		}


		
		
	}

	public function Count(required string methodName)
	{
		return variables.methodCallCounts[arguments.methodName];
	}

	public function method(required string methodName, string state)
	{
		if(NOT structKeyExists(variables.methodSignatures,arguments.methodName))
		{
			throw(message="Method #arguments.MethodName# does not exist in component and so you cannot fake this method #variables.meta.name#",type="Missing Method");
		}
		variables.lastMethodReturnName = arguments.methodName;
		//variables.lastMethodReturnState = arguments.state;
		return this;
	}

	public function returns(required any returnValue)
	{
		if(variables.lastMethodReturnState IS NOT "")
		{
			variables.methodReturns[variables.lastMethodReturnName][variables.lastMethodReturnState] = returnValue;
			//Clear out the last values
			variables.lastMethodReturnName = "";
			variables.lastMethodReturnState = "";
		}
		else
		{
			variables.methodReturns[variables.lastMethodReturnName] = returnValue;	
		}
		
		return this;
	}

	private function setupDependencies()
	{

		variables.component.overrideDependency = function(required string name){
			variables[arguments.name] = new affiliates.core.utilities.raakaTest.mock(variables[arguments.name]);
		}

		for(var item in variables.mockSpec.dependsOn)
		{
			variables.component.overrideDependency(item);

		}

		for(var func in variables.mockSpec.functions)
		{
			var states = variables.mockSpec.functions[func].states;
			for(var state in states)
			{
				variables.component.setMockMethod = function(required function state){
					arguments.state();
				}
				variables.component.setMockMethod(states[state]);
			}
		}
	}

	private function buildMethodSignatures()
	{
		request.end = 0;

		//structAppend(variables.meta.functions);
		var allFunctions = [];
		var workingStruct = {};

		if(structKeyExists(variables.meta,"functions"))
		{
			local.allFunctions = variables.meta.functions;	
		}

		if(structKeyExists(variables.meta,"extends"))
		{
			local.workingStruct = variables.meta.extends;
		}
			
		while(local.workingStruct.name IS NOT "railo-context.Component")
		{
			local.allFunctions = arrayMerge(local.allFunctions,local.workingStruct.functions);
			local.workingStruct = local.workingStruct.extends;
		}

		//Check if this is a proxy object and if so, we want to get the base object and get its methods so that we can check against their signatures
		if(variables.meta.fullname CONTAINS "proxy")
		{
			var proxyMeta = getMetaData(variables.component.object);
			
			var proxyFunctions = [];

			if(structKeyExists(local.proxyMeta,"functions"))
			{
				local.proxyFunctions = local.proxyMeta.functions;
			}
			
			variables.realComponentPath = proxyMeta.fullName;

			local.allFunctions = arrayMerge(local.allFunctions,local.proxyFunctions);
			local.workingStruct = local.proxyMeta.extends;

			while(local.workingStruct.name IS NOT "railo-context.Component")
			{
				local.allFunctions = arrayMerge(local.allFunctions,local.workingStruct.functions);
				local.workingStruct = local.workingStruct.extends;
			}
		}
		
		for(var item in local.allFunctions)
		{
			
			//Create a method signature object. We take the meta data and extract out the function list from an array
			//to a struct with the keys being the function name. This makes it easier to work with as we can do a simmple
			//struct lookup
			
			//structUpdate(variables.methodSignatures,item.name,item);
			variables.methodSignatures[local.item.name] = local.item;
			
			//Set the invocations on this method to 0. We count each invocation of the methods
			variables.methodCallCounts[local.item.name] = 0;

			/* Properties of the class that have generated getters do not have real return types and they will always be set to string. As such we need
			to set them to Any so that any mock overrides will not error for invalid types*/
			if(variables.meta.accessors IS true OR variables.meta.persistent IS true) //Either persistent entities or components with accessors will have this problem
			{

				for(var prop in variables.meta.properties)
				{
					if(NOT (structKeyExists(prop,"getter") AND prop.getter IS false)){
						if(structKeyExists(variables.methodSignatures,"get#prop.name#"))
						{
							variables.methodSignatures["get#prop.name#"].returnType = "any";
						}
					}
				}	
			}
			
			
		}
		
	}

	private function arePositionalArguments(required struct missingMethodArguments)
	{
		for(name in missingMethodArguments)
		{
			if(isNumeric(name))
			{
				return true;
			}
		}
		return false;
	}

	private function isType(required type, required variable)
	{
		switch(arguments.type)
		{
			case "any":
				return true;
			break;

			case "query":
				if(isQuery(arguments.variable))
				{
					return true;
				}
				else{
					return false;
				}

			case "string":

				if(isSimpleValue(arguments.variable))
				{
					return true;
				}
				else{
					return false;
				}
			break;

			case "boolean":
				if(isBoolean(arguments.variable)){
					return true;
				}
				else{
					return false;
				}
			break;

			case "numeric":
				if(isNumeric(arguments.variable)){
					return true;
				}
				else{
					return false;
				}
			break;

			case "array":
				if(isArray(arguments.variable)){
					return true;
				}
				else{
					return false;
				}
			break;

			case "struct":
				if(isStruct(arguments.variable)){
					return true;
				}
				else{
					return false;
				}
			break;

			case "date":
				if(isDate(arguments.variable)){
					return true;
				}
				else{
					return false;
				}
			break;
		}
	}

	public function boolTest(required string test)
	{
		writeDump(test);
		abort;
	}
}