<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorC",
	mockObjects:[],
	tests:{
		getComplexValue:{
			"Should return the complex value":{
				then:{
					returns:"isStruct"
				}
			}
		}
	}
}
</cfscript>