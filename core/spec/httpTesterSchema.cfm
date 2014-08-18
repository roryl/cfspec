<cfscript>
//Defines the schema that a httpspec needs to conform to
schema = {
	children:[
		{
			title:"url",
			description:"The base URL of the endpoint to be tested",
			example:[
				{code:'class:"domain.com/api/base"'}
			],
			types:"string",
			required=true
		},		
		{
			title:"tests",
			description:"Defines the endpoints that are going to be tested",
			types:"struct",
			required:true,
			example:[{code:'tests:{//Children}'}],
			children:[
				{
					title:"[The resource endpoint being tested]",
					description:"This is the resource, appended to the base URL",
					types:"struct",
					required:false,
					example:[{code:"""/resource"":{//Children}"}],
					children:[
						{
							title:"Setup",
							description:"A function to call to setup all scenarios under this test. It will be called once per scenario before object creation and before the 'before' functions",
							types:"function",
							required:false,
							example:[{code:'setup:function(){//Setup code for each scneario under test}'}]
						},
						{
							title:"[The HTTP Method being tested]",
							description:"This is the HTTP Method that will be tested on the resource",
							types:"struct",
							required:false,
							example:[{code:"GET:{//Children}"}],
							children:[
								{
									title:"[The scenario being run on the method and resource]",
									description:"The context or scenario of the functional test. An API endpoint may have multiple scenarios that are being tested.",
									types:"struct",
									required:false,
									example:[{code:'"Should return false when user is logged out":{//Children}'}],
									children:[]
								}
							]
						}
						
					]
				}
			]
		}

	]
}

</cfscript>