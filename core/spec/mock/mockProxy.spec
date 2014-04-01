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
			addMockContext:{
				"Given a function context to mock it adds to the mocked contexts":{
					mxunit:function(){
						local.contextInfo = {
							specPath:"/var/www/cfspec/core/tests/collaboratorA.spec",
						    functionName:"getSimpleAndComplexValue",
						    scenarioNAme:"Should mock out both methods from the collaborator"
						}

						variables.mockProxy.addMockContext(local.contextInfo);

						local.mockContexts = variables.mockProxy.getMockContexts();
						assert(NOT structIsEmpty(local.mockContexts));
					}
				},
				"Given a duplicate context it throws an error":{
					mxunit:function(){
						local.contextInfo = {
							specPath:"/var/www/cfspec/core/tests/collaboratorA.spec",
						    functionName:"getComplexValue",
						    scenarioNAme:"Should return the complex value from B"
						}					

						//Now create the second which should throw an error
						try{
							variables.mockProxy.addMockContext(local.contextInfo);
						}
						catch (any e){
							//Save the error into the local scope so that we can ensure the assertion runs whether an error is thrown or not
							assert(e.message CONTAINS "Mocking out the same function twice is not currently supported");							
						}

						local.mockContexts = variables.mockProxy.getMockContexts();		
																					
						assert(NOT structIsEmpty(local.mockContexts));
						assert(local.mockContexts.len() IS 1);
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
				"Should call the before function for each level of test granularity":{
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
				"Should not call any before functions if none are provided":{
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
			},
			doAsserts:{
				setup:function(){
					makePublic(variables.mockProxy,"doAsserts");
				},
				"Should do nothing if the context does not have any asserts":{
					mxunit:function(){
						//Setup a spec context without any asserts
						local.specContext = {
							given:{},
							then:{returns:true}
						}

						local.result = variables.mockProxy.doAsserts(local.specContext,true,variables.mockProxy);
						assert(isNull(result));
					}
				},
				"Should call the function closure if the assert is a function":{
					mxunit:function(){
						//Setup a spec context without any asserts
						local.specContext = {
							given:{},
							then:{
								returns:true,
								assert:function(){
									//Set a variable into the request scope so that we know that this function is Called
									request.assertCheckWasCalled = true;
									return true;
								}
							}
						}

						result = variables.mockProxy.doAsserts(local.specContext,true,variables.mockProxy);
						assert(isNull(result));
						assert(request.assertCheckWasCalled);

						//Delete the request variable
						structDelete(request,"assertCheckWasCalled");						
					}
				},
				"Should throw an error if the assert function provided does not return true or false":{
					mxunit:function(){
						//Setup a spec context without any asserts
						local.specContext = {
							given:{},
							then:{
								returns:true,
								assert:function(){
									//Do nothing so that the mockProxy returns an error
								}
							}
						}

						try{
							result = variables.mockProxy.doAsserts(local.specContext,true,variables.mockProxy);	
						}
						catch(any e){
							assert(e.message CONTAINS "Your test assertion must return either");
						}
					}
				},
				"Should throw a failure if the assert closure returns false":{
					mxunit:function(){
						//Setup a spec context without any asserts
						local.specContext = {
							given:{},
							then:{
								returns:true,
								assert:function(){
									//return false to make a assert failure
									return false;
								}
							}
						}

						try{
							result = variables.mockProxy.doAsserts(local.specContext,true,variables.mockProxy);	
						}
						catch(any e){
							assert(e.message CONTAINS "The assertion failed");
						}
					}
				},
				"Should call the closure for each assert if given an array of asserts":{
					mxunit:function(){
						//Setup a spec context with an array of assert functions
						local.specContext = {
							given:{},
							then:{
								returns:true,
								assert:[									
									{
										value:function(){
											request.checkThatAssertWasCalled = true;
											return true;
										},
										message:"The custom assertion was called"
									},
									{
										value:function(){
											request.checkThatAssert2WasCalled = true;											
										},
										message:"The custom assertion 2 was called"
									}
								]
							}
						}	

						try {
							result = variables.mockProxy.doAsserts(local.specContext,true,variables.mockProxy);
						}
						catch (any e)
						{
							//Assert that the functions themselves were called
							assert(request.checkThatAssertWasCalled);
							assert(request.checkThatAssert2WasCalled);
							
							//Also assert that the second assert function threw an error because it did not return a value
							assert(e.message CONTAINS "Your test assertion must return either true for success");
						}

						//Delete the request variables so that they do not impact other tests
						structDelete(request,"checkThatAssertWasCalled");
						structDelete(request,"checkThatAssert2WasCalled");																	
					}
				},
				"Should throw the error message for the assert given an array of asserts":{
					mxunit:function(){
						//Setup a spec context with an array of assert functions
						local.specContext = {
							given:{},
							then:{
								returns:true,
								assert:[									
									{
										value:function(){
											request.checkThatAssertWasCalled = true;
											return false;
										},
										message:"The custom assertion was called"
									},
									{
										value:function(){
											request.checkThatAssert2WasCalled = true;	
											return true										
										},
										message:"The custom assertion 2 was called"
									}
								]
							}
						}	

						try {
							result = variables.mockProxy.doAsserts(local.specContext,true,variables.mockProxy);
						}
						catch (any e)
						{							
							//Assert that the functions themselves were called
							assert(request.checkThatAssertWasCalled);

							//Assert that the second assert did not get called because the first one errored, it never got to this
							assert(NOT isDefined('request.checkThatAssert2WasCalled'),"request.checkThatAssert2WasCalled was defined");
							
							//Also assert that the first assert function threw an error with our custom message because it returned false
							assert(e.message CONTAINS "The custom assertion was called");
						}
																	
					}
				}
			},
			doAfter:{
				setup:function(){
					makePublic(variables.mockProxy,"doAfter");
				},
				"Should call the closure and pass the result and object if the closure defines them":{
					mxunit:function(){
						//Create some basic structures which contain a after function that will be tested for
						local.specLevels = [
							{after:function(result,object){
									assert(isDefined('arguments.result') AND arguments.result); 
									assert(isDefined('arguments.object') AND isObject(arguments.object)); 
									request.afterTests=true
								}
							},
							{after:function(result,object){
									assert(isDefined('arguments.result') AND arguments.result); 
									assert(isDefined('arguments.object') AND isObject(arguments.object)); 
									request.afterFunc=true
								}
							},
							{after:function(result,object){
									assert(isDefined('arguments.result') AND arguments.result); 
									assert(isDefined('arguments.object') AND isObject(arguments.object)); 
									request.afterContext=true
								}
							},
						]

						variables.mockProxy.doAfter(specLevels = local.specLevels,
													result = true,
													objectUnderTest = variables.mockProxy,
													depth = 1);

						assert(isDefined('request.afterTests'));
						assert(isDefined('request.afterFunc'));
						assert(isDefined('request.afterContext'));

						//Delete the request variables so that they do not interfere 
						structDelete(request,"afterTests");
						structDelete(request,"afterFunc");
						structDelete(request,"afterContext");

					}
				},
				"Should not set the result of the function into the after arguments if it was not passed in":{
					mxunit:function(){
						//Create some basic structures which contain a after function that will be tested for
						local.specLevels = [
							{after:function(result,object){
									assert(NOT isDefined('arguments.result')); 
									assert(isDefined('arguments.object') AND isObject(arguments.object)); 
									request.afterTests=true
								}
							},
							{after:function(result,object){
									assert(NOT isDefined('arguments.result')); 
									assert(isDefined('arguments.object') AND isObject(arguments.object)); 
									request.afterFunc=true
								}
							},
							{after:function(result,object){
									assert(NOT isDefined('arguments.result')); 
									assert(isDefined('arguments.object') AND isObject(arguments.object)); 
									request.afterContext=true
								}
							},
						]

						variables.mockProxy.doAfter(specLevels = local.specLevels,													
													objectUnderTest = variables.mockProxy,
													depth = 1);

						assert(isDefined('request.afterTests'));
						assert(isDefined('request.afterFunc'));
						assert(isDefined('request.afterContext'));

						//Delete the request variables so that they do not interfere 
						structDelete(request,"afterTests");
						structDelete(request,"afterFunc");
						structDelete(request,"afterContext");

					}
				},
				"Should set the object into the unit test if the after was a struct with a value of unit":{
					mxunit:function(){
						//Create some basic structures which contain a after function that will be tested for
						local.specLevels = [
							{after:{
									unit:function(object){										
										assert(isDefined('arguments.object') AND isObject(arguments.object)); 
										request.afterTests=true
									}
								}
							},
							{after:{
									unit:function(object){										
										assert(isDefined('arguments.object') AND isObject(arguments.object)); 
										request.afterFunc=true
									}
								}
							},
							{after:{
									unit:function(object){										
										assert(isDefined('arguments.object') AND isObject(arguments.object)); 
										request.afterContext=true
									}
								}
							},
						]

						variables.mockProxy.doAfter(specLevels = local.specLevels,													
													objectUnderTest = variables.mockProxy,
													depth = 1);

						assert(isDefined('request.afterTests'));
						assert(isDefined('request.afterFunc'));
						assert(isDefined('request.afterContext'));

						//Delete the request variables so that they do not interfere 
						structDelete(request,"afterTests");
						structDelete(request,"afterFunc");
						structDelete(request,"afterContext");

					}
				}
			},
			doError:{
				setup:function(){
					makePublic(variables.mockProxy,"doError");
				},
				"Should throw an error if the specification expected an error but no error was actually caught":{
					mxunit:function(){
						//Create a specContext with an error to check for being thrown
						local.specContext = {
							given:{},
							then:{
								throws:"Some error it should throw"
							}
						}
						local.error = {};
						local.error.message = "The specification expected an error but did not receive one"
						
						try{
							variables.mockProxy.doError(local.error,local.specContext)
						}
						catch (any e)
						{							
							assert(e.message CONTAINS "The specification expected an error but did not receive one");
						}
					}
				},
				"Should return true if the specification expected a specific error and that error was thrown":{
					mxunit:function(){

						//Create a specContext with an error to check for being thrown
						local.specContext = {
							given:{},
							then:{
								throws:"Some error it should throw"
							}
						}

						//Now we are going to throw a fake error, change its name to our error message and ensure that the doError 
						//checks for this and returns true
						try{
							throw("some error"); //Throw any error, it doesn't matter
						} catch(any e) {
							//Overrite the error message with our test message
							e.message = local.specContext.then.throws;

							//Pass the value of this to doError
							doErrorResultShouldBeTrue = variables.mockProxy.doError(e,local.specContext);

							assert(doErrorResultShouldBeTrue);
						}
					}
				},
				"Should return an error that the throw in the specification did not match the actual error that was returned":{
					mxunit:function(){

						//Create a specContext with an error to check for being thrown
						local.specContext = {
							given:{},
							then:{
								throws:"Some error it should throw"
							}
						}

						//Now we are going to throw a fake error which is different from the error we should expect, and this should be an error
						try{
							throw("some error"); //Throw any error, it doesn't matter
						} catch(any e) {

							try{
								//Now we try the doError function. It should throw an error of "some error", which is different than the specification expected
								doErrorResultShouldBeTrue = variables.mockProxy.doError(e,local.specContext);
							}
							catch(any err)
							{								
								assert(err.message CONTAINS "some error");
							}														
						}
					}
				},
				"Should run the onError in the specification if one was requested and there was an error when running the test":{
					mxunit:function(){
						//Create a specContext with an onError clause which will be run onError of the test
						local.specContext = {
							given:{},
							onError:function(){
								//set a variable into the request scope so that we can check it later
								request.onErrorWasCalled = true;
							},
							//Tell this specificaiton to throw an error so that it will pass when we actually throw the error.
							then:{
								throws:"some error"
							}
						}

						//Now we are going to throw a fake error so that we can test the call of the onError function in the passed in specification
						try{
							throw("some error"); //Throw any error, it doesn't matter
						} catch(any e) {
							//Pass the value of this to doError
							variables.mockProxy.doError(e,local.specContext);
							assert(request.onErrorWasCalled);
						}
					}
				}
			},
			tryFunctionCall:{
				"Should call the mocked function provided to the spec":{
					setup:function(){
						makePublic(variables.mockProxy,"tryFunctionCall");
					},
					mxunit:function(){

						//Get the value from the mocked function that was setup in the tests setup in this spec
						local.result = variables.mockProxy.getComplexValue();
						
						assert(isStruct(local.result));
					}
				}
			}

		}
	}
</cfscript>