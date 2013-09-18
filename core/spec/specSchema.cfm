<cfscript>
//Defines the schema that a spec needs to conform to
schema = {
	children:{
		class:{
			description:"A fully qualified path to the component being specified",
			example:"class:""a.fully.qualified.path""",
			types:"string",
			required=true
		},
		mockObjects:{
			description:"The objects within the class that we are going to override with mocks. Each object to be mocked must be within the variables scope. 
						 It is not necessary that the mockable object be passed within the constructor",
			type:"array",
			required:false
		},
		setup:{
			description:"A function defining custom code to execute at the startup of the test of the class",
			type="function",
			required:false
		},
		tests:{
			description:"The functions under test in the class being specified",
			types:"struct",
			required:true,
			children:{
				"any":{
					description:"The name of the function under test",
					type:"struct",
					required:false,
					children:{
						"any":{
							description:"The context of the functional test",
							type:"struct",
							required:false,
							children:{
								given:{
									description:"These are the parameters/Arguments that are going to be passed into the function. They are passed as an argument collection. The key values should be
												 The argument names",
									type:"struct",
									required:true,
								},
								when:{
									description:"These are the variables that represent the 'State' of the object under test for a given context. The values specified here will be copied into the respective variables
											     Usually this will be values in the variables scope, but sometimes values in the request, session, and application scopes may need to exist",
									type:"struct",
									required:true,
									children:{
										"any":{
											description:"The name of the variable to set, like session.varName or request.varName or variables.varName. You can set any valid coldfusion object or value to this variable",
											type:"any",
											required:false
										}
									}
								},
								with:{},
								then:{}
							}
						}
					}
				}
			}
		}

	}
}
</cfscript>