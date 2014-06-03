<!---
This spec uses all of the setup, tearDown, before and after functions are every level to ensure that all of them are called. 
It saves each call into the request scope so that we can take a look at it afterwards and ensure everything was properly called
--->
<cfscript>

	spec = {
		class:"cfspec.core.tests.fixtures",
		mockObjects:[""],
		factory:function(){			

			return createObject("component","fixtures").init();
		},
		setup:function(){
			request.fixturesCalls.setup_spec = true;
			request.fixturesOrder = [];
			request.fixturesOrder = ["setup_spec"];
		},
		tearDown:function(){
			request.fixturesCalls.teardown_spec = true;
			request.fixturesOrder.append("teardown_spec");
		},	
		tests:{
			
			setup:function(){				
				request.fixturesCalls.setup_all_tests = true;				
				request.fixturesOrder.append("setup_all_tests");				
			},
			before:function(object){						
					request.fixturesCalls.before_all_tests = true;
					request.fixturesOrder.append("before_all_tests");
			},
			after:function(){
						request.fixturesCalls.after_all_tests = true;
						request.fixturesOrder.append("after_all_tests");
			},	
			basicFunction:{
				
				setup:function(){
					request.fixturesCalls.setup_all_scenarios = true;
					request.fixturesOrder.append("setup_all_scenarios");
				},
				before:function(object){						
					request.fixturesCalls.before_all_scenarios = true;
					request.fixturesOrder.append("before_all_scenarios");
				},
				after:function(){
						request.fixturesCalls.after_all_scenarios = true;
						request.fixturesOrder.append("after_all_scenarios");
				},	
				"Look for calls to all of the fixtures":{					
					setup:function(){
						request.fixturesCalls.setup_specific_scenario = true;
						request.fixturesOrder.append("setup_specific_scenario");
					},
					before:function(object){												
						request.fixturesCalls.before_specific_scenario = true;
						request.fixturesOrder.append("before_specific_scenario");
					},
					then:{
						returns:true,
						assert:function(){
							assert(structKeyExists(request.fixturesCalls,"setup_spec"));
							assert(structKeyExists(request.fixturesCalls,"setup_all_tests"));
							assert(structKeyExists(request.fixturesCalls,"setup_all_scenarios"));
							assert(structKeyExists(request.fixturesCalls,"setup_specific_scenario"));
							assert(structKeyExists(request.fixturesCalls,"before_all_tests"));
							assert(structKeyExists(request.fixturesCalls,"before_all_scenarios"));
							assert(structKeyExists(request.fixturesCalls,"before_specific_scenario"));							
							return true;
						}
					},
					after:function(){
						
						request.fixturesCalls.after_specific_scenario = true;
						request.fixturesOrder.append("after_specific_scenario");

						//Assert that they were called in the right order. We are doing the assert
						//here instead of in the normal assertion area because we want to check that the preceding afters are all called						
						assert(request.fixturesOrder[1] IS "setup_spec");
						assert(request.fixturesOrder[2] IS "setup_all_tests");
						assert(request.fixturesOrder[3] IS "setup_all_scenarios");
						assert(request.fixturesOrder[4] IS "setup_specific_scenario");
						assert(request.fixturesOrder[5] IS "before_all_tests");
						assert(request.fixturesOrder[6] IS "before_all_scenarios");
						assert(request.fixturesOrder[7] IS "before_specific_scenario");
						assert(request.fixturesOrder[8] IS "after_all_tests");
						assert(request.fixturesOrder[9] IS "after_all_scenarios");
						assert(request.fixturesOrder[10] IS "after_specific_scenario");						
					}
				}
			},			
			checkBeforeArguments:{
				"Should have the object under test passed in":{
					before:function(object){
						assert(NOT structIsEmpty(arguments));										
						assert(getMetaData(object).fullName IS "cfspec.core.tests.fixtures");
					},
					then:{
						returns:true
					}
				}
			},
			checkAfterArguments:{
				"Should have zero arguments if none are requested":{
					then:{
						returns:true
					},
					after:function(){
						assert(structIsEmpty(arguments));						
					}
				},
				"Should have the result set if requsted":{
					then:{
						returns:true
					},
					after:function(result){
						assert(NOT structIsEmpty(arguments));						
						assert(result IS true);
					}
				},
				"Should have the object under test if requested":{
					then:{
						returns:true
					},
					after:function(object){
						assert(NOT structIsEmpty(arguments));						
						assert(getMetaData(object).fullName IS "cfspec.core.tests.fixtures");
					}
				},
				"Should have both the result and the object if requested":{
					then:{
						returns:true
					},
					after:function(result,object){
						assert(NOT structIsEmpty(arguments));
						assert(result IS true);					
						assert(getMetaData(object).fullName IS "cfspec.core.tests.fixtures");
					}
				}
			},
			factoryScenarioTest:{
				factory:function(){
					request.fixturesCalls.factory_all_scenarios = true;
					request.fixturesOrder = ["factory_all_scenarios"];
					return createObject("component","fixtures").init();
				},	
				"Should call the factory for a scenario if it exists":{
					factory:function(){
						request.fixturesCalls.factory_specific_scenario = true;
						request.fixturesOrder = ["factory_specific_scenario"];
						return createObject("component","fixtures").init();
					},
					then:{
						returns:true,
						assert:function(){
							assert(structKeyExists(request.fixturesCalls,"factory_specific_scenario"));
							return true;
						}
					}
				},
				"Should call the factory for a test if it exists":{					
					then:{
						returns:true,
						assert:function(){
							assert(structKeyExists(request.fixturesCalls,"factory_all_scenarios"));
							request.fixturesOrder = [];
							return true;
						}
					}
				}
			}
		}
	}
</cfscript>