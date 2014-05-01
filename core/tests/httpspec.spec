<cfscript>
	spec = {
		url:"dev.cfspec.com",		
		tests:{
			"?action=main.httpspec":{
				get:{
					"Should return hello":{
						given:{														
							url:"",
							//body:"",
							// formfields:[
							// 	{name="test", value="value1"}
							// ],
							cookies:[
								{name="test", value="value1"}
							]
						},
						then:{
							returns:"isHTML",							
							responseCode:200,
							responseText:"ok",
							errordetail:"",
							charset:"UTF-8",
							header:"",
							httpVersion:"",
							mimetype:"",														
							assert:function(response){

							}
						}					
					}
				},
				// put:{
				// 	"Should return hello":{
				// 		given:{							
				// 			headers:[],
				// 			parameters:[]
				// 		},
				// 		then:{
				// 			returns:"isJson"
				// 		}					
				// 	}
				// }
				
			}
		}
	}
</cfscript>