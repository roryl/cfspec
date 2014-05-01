<cfscript>
	spec = {
		class:"cfspec.core.spec.httpTester",
		mockObjects:[""],
		factory:function(){
			return createObject("component","httpTester");
		},
		tests:{
			doAssertStandardHTTPResponses:{
				"Should pass if the mime type is the same":{
					given:{
						httpResponse:{

						},
						context:{
							then:{
								returns:"isHTML",
								mimeType:""
							}
						}						
					},
					then:{
						returns:"void",
						assert:function(){

						}
					}
				}
			}
		}
	}
</cfscript>