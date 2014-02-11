<cfscript>
	spec = {
		class:"cfspec.core.tests.genericClass",
		mockObjects:[],
		tests:{
			returnArgumentString:{
				"Test a basic Given and Then clauses":{
					given:{
						theString:"My String"
					},
					then:{
						returns:"My String"
					}
				}
			},
			dependsOnState:{
				"Test a function call which depends on the state being set":{
					when:{
						"request.stateValue":"My state is set"
					},
					then:{
						returns:"My state is set"
					}
				}
			},
			returnArgumentType:{
				"Should return and assert a query type":{
					given:{
						theArgument:queryNew("test,query,columns")
					},
					then:{
						returns:"isQuery"
					}
				},
				"Should return and assert a struct type":{
					given:{
						theArgument:{}
					},
					then:{
						returns:"isStruct"
					}
				},
				"Should return and assert a boolean type":{
					given:{
						theArgument:true
					},
					then:{
						returns:"isBoolean"
					}
				},
				"Should return and assert a array type":{
					given:{
						theArgument:[]
					},
					then:{
						returns:"isArray"
					}
				},
				"Should return and assert a object type":{
					given:function(){
						object = new cfspec.core.tests.genericClass()
						return {theArgument:object}
					},
					then:{
						returns:"isObject"
					}
				}
			},
		}
	}
</cfscript>