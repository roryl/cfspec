<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorTests",
	mockObjects:["collaboratorA"],
	tests:{
		getSimpleValues:{
			"Overriding collaborator with simple value":{
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
		}
	}
}
</cfscript>