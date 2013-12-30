<cfscript>
//Defines the schema that a spec needs to conform to
schema = {
	children:[
		{
			title:"class",
			description:"A fully qualified path to the component being specified",
			example:'class:"a.fully.qualified.path"',
			types:"string",
			required=true
		},
		{
			title:"factory",
			description:"A function that returns the fully constructed component under test.",
			types:"function/closure",
			required:false,
			example:[{code:'factory:function(){ return new componentUnderTest();}'}]
		},
		{
			title:"mockObjects",
			description:"The objects within the class that we will be overridden with mocks. Each object to be mocked must be within the variables scope. 
						 It is not necessary that the mockable object be passed within the constructor",
			types:"array",
			required:false,
			example:[{code:'mockObjects:["Object1","Object2"]'}]
		},
		{
			title:"setup",
			description:"A function defining custom code to execute at the startup of the test case. This runs only once per spec",
			types="function",
			required:false,
			example:[{code:""}]
		},
		{
			title:"tests",
			description:"Defines the functions that are going to be tested for this specification",
			types:"struct",
			required:true,
			example:[{code:'tests:{//Children}'}],
			children:[
				{
					title:"[The name of the function being tested]",
					description:"The name of the function under test",
					types:"struct",
					required:false,
					example:[{code:"loginUser:{//Children}"}],
					children:[
						{
							title:"[The scenario being run on the function]",
							description:"The context or scenario of the functional test. A function may have multiple code execution paths or return a different value depending on state. One defines all of the scenarios that the function operates under.",
							types:"struct",
							required:false,
							example:[{code:'"Should return false when user is logged out":{//Children}'}],
							children:[
								{
									title:"before",
									description:"This is a closure which can be called to setup information that is not actually apart of the test like inserting fake records into a database. This is a setup for the scenario",
									types:"function",
									required:false,
									example:[{code:'before:function(){//Setup the test with some other conditions}'}]
								},
								{
									title:"given",
									description:"These are the parameters/Arguments that are going to be passed into the function (thus 'Given' to the function). They are passed as an argument collection. The key values should be
												 The argument names",
									types:"struct,function",
									required:false,
									example:[
										{code:'given:{userName="validUser",password="gkeith374"}'},
										{code:'given:function(){return {userName="validUser",password="gkeith374"};}'}
									],
								},
								{
									title:"when",
									description:"These are the variables that represent the 'State' of the object under test for a given scenario. The values specified here will be copied into the respective variables. Usually this will be values in the variables scope, but sometimes values in the request, session, and application scopes may need to exist",
									types:"struct",
									required:false,
									example:[{code:'when:{//Children}'}],
									children:[
										{
											title:"[The scoped variable being created]",
											description:"This is a structure with the key being the variable being mocked, and the value being what will be placed into the variable",
											types:"simpleValue,struct",
											required:true,
											example:[{code:'"application.allowLogin":true,"request.someVariable":"value",request.someStruct:{key:value,key1:value1}'}],
										}
									]
								},
								{
									title:"with",
									description:"Defines the classes and function calls which are the collaborators of the unit under test. A definition here implies a function call which would have its own given, when, with and then.",
									types:"struct",
									required:false,
									example:[{code:'with:{//Children}'}]
								},
								{
									title:"then",
									description:"Defines the result of the unit under test via its expected return value and other arbitrary asserts",
									types:"struct",
									required:true,
									example:[{code:'then:{//Children}'}],
									children:[
										{
											title:"returns",
											description:"Defines the return value that the unit under test should returns. This can be either a literal value to compare equality to or a generic type",
											types:"value,string",
											required:true,
											example:[{code:'returns:false'}]

										},
										{
											title:"assert",
											description:"Allows you to define multiple additional asserts to test other side effects beyond the simple testing of the return statement. Often a function all may have side effects like writing to the database, sending an e-mail etc, and you can test that they work here",
											types:"array",
											required:false,
											example:[{code:'assert:[//Children]'}],
											children:[
												{
													title:"An Array of assert statements",
													description:"Allows you to define an array of asserts. Each assert is tested to be true. If it is not, it errors and displays the message that is defined",
													types:"struct",
													required:true,
													example:[{code:'{value:"testResult IS 1",message:"The value of testResult was not 1 as expected"},{value:"isQuery(testResult)",message:"The value of testResult was not a query as was expected"}'}]
												}
											]
										},
									]
								},
								{
									title:"after",
									description:"This is a closure which can be called to cleanup information after the test, like deleting database information. This is a teardown.",
									types:"function",
									required:false,
									example:[{code:'after:function(){//Code to run after the test completes. This is usually used to clean up data}'}]
								},
							]

							
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