<cfscript>
	spec = {
		url:"dev.cfspec.com",		
		tests:{
			"?action=main.httpspec":{
				get:{
					"Should return hello":{
						given:{														
							url:"",
							body:"",
							formfields:[
								{name="test", value="value1"}
							],
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
							httpVersion:"HTTP/1.1",
							mimetype:"text/html",														
							assert:function(response){

							}
						}					
					}
				},
				put:{
					"Should save hello":{
						given:{							
							headers:[],
							parameters:[]
						},
						then:{
							returns:"isJson"
						}					
					}
				}
				
			}
		}
	}
</cfscript>