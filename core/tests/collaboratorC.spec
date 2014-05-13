<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorC",
	
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