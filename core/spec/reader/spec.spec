<cfscript>
	spec = {
		class:"cfspec.core.spec.reader.spec",
		mockObjects:[""],
		factory:function(){
			return createObject("component","cfspec.core.spec.reader.spec").init("/cfspec/core/tests/collaboratorTests.spec").init("/cfspec/core/tests/collaboratorTests.spec");
		},
		tests:{
			init:{
				"Given a spec path it includes the spec path":{
					given:{
						spec:"/cfspec/core/spec/reader/spec.spec"
					},
					then:{
						returns:"isObject",
						assert:function(result){
							return isStruct(result.getSpecSchema());
						}
					}
				},
				"Given a spec struct it sets the spec":{
					given:{
						spec:{
							class:"",
							mockObjects:[""],
							factory:function(){
								//return createObject("component","path");
							},
							tests:{

							}
						}
					},
					then:{
						returns:"isObject",
						assert:function(result){
							return isStruct(result.getSpecSchema());
						}
					}
				},
				"Should throw an error given an invalid path":{
					given:{
						spec:"/this/is/an/invalid/path"
					},
					then:{
						throws:"file not found"
					}
				}
			},
			getClass:{
				"Should return the class name":{					
					then:{
						returns:"isString",
						assert:function(result){							
							return result IS "cfspec.core.tests.collaboratorTests"
						}
					}
				}
			},
			getTests:{
				"Should return the tests service with the given spec":{
					
					then:{
						returns:"isObject"
					}
				}
			},
			getAllTests:{
				"Should return all of the tests from the specification":{					
					with:{
						"testsService.getAllTests":{mimic:"Should return an array of all tests in the specification"}
					},
					then:{
						returns:"isArray"
					}
				}
			}

		}
	}
</cfscript>
