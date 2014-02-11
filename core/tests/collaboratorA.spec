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
			}
		}
	}
}
</cfscript>