<cfscript>
	function makePublic(required object, required funcName)
	{
		//Make the assert function public
		arguments.object.override = function(funcName){
			this[arguments.funcName] = variables[arguments.funcName];
		}
		variables.mockProxy.override(arguments.funcName);
	}

	spec = {
		class:"cfspec.core.spec.mock.mockProxy",
		mockObjects:[""],
		factory:function(){
			return createObject("component","mockProxy");
		},
		tests:{
			setup:function(){
				//Create an object that we are going to mockProxy
				local.args = {}
				local.args.object = new cfspec.core.tests.collaboratorA();
				local.args.contextInfo = {
					specPath:"/cfspec/core/tests/collaboratorA.spec",
					functionName:"getComplexValue",
					scenarioName:"Should return the complex value from B"
				};
				local.args.mockDepth = 1;
				local.args.parentName = "root";

				local.mockProxy = createObject("cfspec.core.spec.mock.mockProxyNew");

				local.mockProxy.create(argumentCollection=args);

				//Set the mockproxy object into the variables scope so that we can test it from the mxunit custom tests below
				variables.mockProxy = local.mockProxy;
			},
			assert:{
				setup:function(){
					makePublic(variables.mockProxy,"assert");					
				},
				"Should do nothing if the assert is true":{
					
					mxunit:function(){						
						//Ensure that the return is voic
						assert(isNull(variables.mockProxy.assert(true)));
					}
				},
				"Should throw an error for where the assertion failed":{
					mxunit:function(){
						try {
							variables.mockProxy.assert(false);
						}
						catch(any e){
							assert(e.message CONTAINS "Called from: /var/www/cfspec/core/spec/mock/mockProxy.spec");						
						}
					}
				}
			},
			doGiven:{
				setup:function(){
					makePublic(variables.mockProxy,"doGiven");
				},
				"Should use the basic arguments from the spec if they were provided":{
					mxunit:function(){
						//Setup the spec context with some basic arguments given
						local.args.specContext = {
							given:{
								args1:1,
								args2:2
							}
						};
						local.args.mockDepth = 1;
						local.args.missingMethodArguments = {}

						local.result = variables.mockProxy.doGiven(argumentCollection=local.args);

						assert(isDefined('local.result.args1'));
						assert(local.result.args1 IS 1);
						assert(isDefined('local.result.args2'));
						assert(local.result.args2 IS 2);

						assert(objectEquals(local.result, request.given),"Ensure that the same values are put into the request scope");
						structDelete(request,"given");
					}
				},
				"Should use the closure if the spec describes a closure for the given":{
					mxunit:function(){
						//Setup the spec context with some basic arguments given
						local.args.specContext = {
							given:function(){
								return {
									args1:1,
									args2:2
								}
							}
						};
						local.args.mockDepth = 1;
						local.args.missingMethodArguments = {}

						local.result = variables.mockProxy.doGiven(argumentCollection=local.args);

						//Assert that all of the values were returned
						assert(isDefined('local.result.args1'));
						assert(local.result.args1 IS 1);
						assert(isDefined('local.result.args2'));
						assert(local.result.args2 IS 2);

						assert(objectEquals(local.result, request.given),"Ensure that the same values are put into the request scope");
						structDelete(request,"given");
					}
				},
				"Should return the missing method arguments if the mock depth is greater than 1":{
					mxunit:function(){
						//Setup the spec context with some basic arguments given
						local.args.specContext = {
							given:function(){
								return {
									args1:1,
									args2:2
								}
							}
						};
						local.args.mockDepth = 2;
						local.args.missingMethodArguments = {args2:1,args3:2};

						local.result = variables.mockProxy.doGiven(argumentCollection=local.args);
						
						//Assert that all of the values were returned
						assert(isDefined('local.result.args2'));
						assert(local.result.args2 IS 1);
						assert(isDefined('local.result.args3'));
						assert(local.result.args3 IS 2);

						assert(NOT structKeyExists(request,"given"),"Ensure that the given was not set into the request scope");
					}
				}
			},
			doBefore:{
				setup:function(){
					makePublic(variables.mockProxy,"doBefore");
				},
				"Given befores for each level it calls all of them":{
					mxunit:function(){

						//Create some basic structures which contain a before function that will be tested for
						local.specLevels = [
							{before:function(){request.beforeTests=true}},
							{before:function(){request.beforeFunc=true}},
							{before:function(){request.beforeContext=true}},
						]

						//Set the befores into the doBefore to test them
						variables.mockProxy.doBefore(local.specLevels);

						//Ensure that each request variable was set
						assert(request.beforeTests);
						assert(request.beforeFunc);
						assert(request.beforeContext);

						//Delete the values from the request scope so that they do not impact other tests
						structDelete(request,"beforeTests");
						structDelete(request,"beforeFunc");
						structDelete(request,"beforeContext");

					}
				},
				"Given no befores none of them get called":{
					mxunit:function(){
						//Create some basic empty structures which do not contain before clauses
						local.specLevels = [
							{},
							{},
							{},
						]

						//Set the befores into the doBefore to test them
						variables.mockProxy.doBefore(local.specLevels);

						//Ensure that each request variable was set
						assert(NOT isDefined('request.beforeTests'));
						assert(NOT isDefined('request.beforeFunc'));
						assert(NOT isDefined('request.beforeContext'));
					}
				}
			}

		}
	}
</cfscript>