<cfscript>
spec = {
	class:"cfspec.core.tests.collaboratorB",
	
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
					returns:"isStruct",					
				}
			},
			"Collaborator with an assert scenario should be called":{
				then:{
					returns:"isStruct",
					assert:function(){
						request.assert_collaborator_b_complex_value = true;
						return true;
					}
				}
			}
		},
		getSimpleValue:{
			"Should return the simple value":{
				then:{
					returns:"My simple value",					
				},
				
			},
			"Collaborator with an assert scenario should be called":{
				then:{
					returns:"My simple value",
					assert:function(){
						request.assert_collaborator_b_simple_value = true;
						return true;
					}
				}
			}

		}
	}
}
</cfscript>