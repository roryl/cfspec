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
				with:{
					"collaboratorB.getComplexValue":{mimic:"Should return the complex value from C"}

				},
				then:{
					returns:"isStruct"
				},
				after:function(){
					
				}
			}
		},
		getMyOwnValue:{
			"Should return my own value":{
				then:{
					returns:"My own value"
				}
			}
		},
		getSimpleAndComplexValue:{
			"Should mock out both methods from the collaborator":{
				with:{
					"this.getMyOwnValue":{mimic:"Should return my own value"},
					"collaboratorB.getComplexValue":{mimic:"Should return the complex value from C"},
					// "collaboratorB.getSimpleValue":{mimic:"Should return the simple value"}
				}
			},
			// "Should test collaborator assert fixture":{
			// 	with:{
			// 		"this.getMyOwnValue":{mimic:"Should return my own value"},
			// 		"collaboratorB.getSimpleValue":{mimic:"Collaborator with an assert scenario should be called"},
			// 		"collaboratorB.getComplexValue":{mimic:"Collaborator with an assert scenario should be called"},
			// 	},
			// 	then:{
			// 		returns:true,
			// 		assert:function(object){
			// 			assert(structKeyExists(request,"assert_collaborator_b_simple_value"));
			// 			assert(structKeyExists(request,"assert_collaborator_b_complex_value"));
			// 			return true;
			// 		}
			// 	},
			// 	after:function(object){
			// 		writeDump(object.getCollaboratorB());
			// 		//abort;
			// 	}
			// }
		}

	}
}
</cfscript>