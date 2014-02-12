<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorTests",
	mockObjects:["collaboratorA"],
	tests:{
		getSimpleValues:{
			"Overriding collaborator function call with a value":{
				with:{
					"collaboratorA.getSimpleValue":"My new value"
				},
				then:{
					returns:"My new value"
				}
			},
			"Overriding collaborator with custom closure":{
				with:{
					"collaboratorA.getSimpleValue":function(){
						return "My function value"
					}
				},
				then:{
					returns:"My function value"
				}
			}			
		},
		getComplexValues:{
			"Overriding collaborator with mimic":{
				with:{
					"collaboratorA.getComplexValue":{mimic:"Should return the complex value from B"}
				},
				then:{
					returns:"isStruct"
				}
			}
		},
		getLocalVariable:{
			"Should return the local variable":{
				then:{
					returns:"My local variable"
				}
			},
			"Should override the this scope function":{
				with:{
					"this.getLocalVariable":"My new local variable"
				},
				then:{
					returns:"My new local variable"
				}
			}
		}
	}
}
</cfscript>