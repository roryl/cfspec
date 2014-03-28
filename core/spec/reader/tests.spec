<cfscript>
	spec = {
		class:"cfspec.core.spec.reader.tests",
		mockObjects:[""],
		factory:function(){
			specObject = new spec("/cfspec/core/tests/collaboratorTests.spec");
			local.spec = "";
			include template="/cfspec/core/tests/collaboratorTests.spec";
			local.tests = local.spec.tests;
			return createObject("component","cfspec.core.spec.reader.tests").init(specObject=specObject,tests=local.tests);
		},
		tests:{
			init:{
				"Should return the tests":{
					given:function(){
						specObject = new spec("/cfspec/core/tests/collaboratorTests.spec");
						local.spec = "";
						include template="/cfspec/core/tests/collaboratorTests.spec";
						local.tests = local.spec.tests;
						return {
							specObject:specObject,
							tests:local.tests
						}
					},
					then:{
						returns:"isObject",
						assert:function(result){
							return isObject(result.getSpecObject()) AND isStruct(result.getTests());
						}
					}
				}
			},
			getTestByName:{
				"Should return a test object representing the test":{					
					given:{
						name:"getSimpleValues"
					},
					then:{
						returns:"isObject",
						assert:function(result){
							return getMetaData(result).fullname IS "cfspec.core.spec.reader.test";
						}
					}			
				}
			},
			getAllTests:{
				"Should return an array of all tests in the specification":{
					then:{
						returns:"isArray"
					}
				}
			}
		}
	}
</cfscript>