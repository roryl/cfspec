<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorA",
	mockObjects:["collaboratorB"],
	tests:{
		getComplexValue:{
			"Should return the complex value from B":{
				with:{
					"collaboratorB.getComplexValue":{mimic:"Should return the complex value from C"}

				},
				then:{
					returns:"isStruct"
				}
			},
			"Should test the after function for a scenario":{
				then:{
					returns:"isStruct"
				},
				after:function(){
					
				}
			}
		},
		getSimpleAndComplexValue:{
			"Should mock out both methods from the collaborator":{
				with:{
					"collaboratorB.getComplexValue":{mimic:"Should return the complex value from C"},
					"collaboratorB.getSimpleValue":{mimic:"Should return the simple value"}
				}
			}
		}

	}
}
</cfscript>