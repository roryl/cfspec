<cfscript>
	spec = {
		class:"cfspec.core.spec.reader.test",
		mockObjects:[""],
		factory:function(){

			specObject = new spec("/cfspec/core/tests/collaboratorTests.spec");
			local.spec = "";
			include template="/cfspec/core/tests/collaboratorTests.spec";
			local.test = local.spec.tests.getSimpleValues;
			return createObject("component","cfspec.core.spec.reader.test").init(specObject,{getSimpleValues:local.test});
		},
		tests:{
			init:{
				"Should return the test":{
					given:function(){
						specObject = new spec("/cfspec/core/tests/collaboratorTests.spec");
						local.spec = "";
						include template="/cfspec/core/tests/collaboratorTests.spec";
						local.test = local.spec.tests.getSimpleValues;
						return {
							spec:specObject,
							test:{getSimpleValues:local.test}
						}
					},
					then:{
						returns:"isObject",
						assert:function(result){								
							assert(isObject(result.getSpec()));
							assert(isStruct(result.getTest()));
							assert(isStruct(result.getScenarios()));
							assert(isSimpleValue(result.getTestName()));
							return true;						
						}																			
					}
				}
			},
			getUnitTestNames:{
				"Should return an array of the test names":{
					then:{
						returns:"isArray"						
					}
				}				
			}
		}
	}
</cfscript>