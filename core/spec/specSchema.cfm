<cfscript>
//Defines the schema that a spec needs to conform to
schema = {
	children:[
		{
			title:"class",
			description:"A fully qualified path to the component being specified",
			example:'spec = {class:"a.fully.qualified.path"}',
			types:"string",
			required=true
		},
		{
			title:"factory",
			description:"A function that returns the fully constructed component under test.",
			types:"function/closure",
			required:false,
			example:'spec = {factory:function(){ return new componentUnderTest();}}'
		},
		{
			title:"mockObjects",
			description:"The objects within the class that we will be overridden with mocks. Each object to be mocked must be within the variables scope. 
						 It is not necessary that the mockable object be passed within the constructor",
			types:"array",
			required:false,
			example:'spec = { mockObjects:["Object1","Object2"]}'
		},
		{
			title:"setup",
			description:"A function defining custom code to execute at the startup of the test case. This runs only once per spec",
			types="function",
			required:false,
			example:""
		},
		{
			title:"tests",
			description:"Defines the functions that are going to be tested for this specification",
			types:"struct",
			required:true,
			example:'spec = {tests:{functionNameOne:{...},functionNameTwo:{...}}}',
			children:[
				{
					title:"[The name of the function being tested]",
					description:"The name of the function under test",
					types:"struct",
					required:false,
					example:"spec = {tests:{functionNameOne:{//function scenarios}}",
					children:[
						{
							title:"[The scenario being run on the function]",
							description:"The context or scenario of the functional test. A function may have multiple code execution paths or return a different value depending on state. One defines all of the scenarios that the function operates under.",
							types:"struct",
							required:false,
							example:'spec = {tests:{functionNameOne:{"Should return true when user is logged in":{//Scenario settings},"Should return true when user is logged in":{//Scenario settings}}}',
							/*children:{
								given:{
									description:"These are the parameters/Arguments that are going to be passed into the function. They are passed as an argument collection. The key values should be
												 The argument names",
									type:"struct",
									required:true,
									example:"",
								},
								when:{
									description:"These are the variables that represent the 'State' of the object under test for a given context. The values specified here will be copied into the respective variables
											     Usually this will be values in the variables scope, but sometimes values in the request, session, and application scopes may need to exist",
									type:"struct",
									required:true,
									example:"",
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
							}*/
						}
					]
				}
			]
		}

	]
}

</cfscript>