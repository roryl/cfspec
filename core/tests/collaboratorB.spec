<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorB",
	mockObjects:["collaboratorC"],
	tests:{
		getComplexValue:{
			"Should return the complex value from C":{
				when:{
					"request.someVariable":"someValue"
				},
				with:{
					"collaboratorC.getComplexValue":{mimic:"Should return the complex value"}
				},
				then:{
					returns:"isStruct"
				}
			}
		},
		getSimpleValue:{
			"Should return the simple value":{
				then:{
					returns:"My simple value"
				}
			}
		}
	}
}
</cfscript>