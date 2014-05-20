<cfscript>
	spec = {
		url:"dev.cfspec.com",		
		tests:{
			"?action=main.httpspec":{
				get:{
					"Should return hello":{
						before:function(){
							request.doSomething = true;							
						},
						given:{														
							url:"",							
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
								assert(true);
								assert(request.doSomething);
								return true;
							}
						},
						after:function(response){
							assert(request.doSomething);
							assert(isStruct(arguments.response));
						}					
					}
				},
				put:{
					"Should save hello":{
						given:{
							//body:"",
							// formfields:[
							// 	{name="test", value="value1"}
							// ],						
							headers:[],
							parameters:[]
						},
						then:{
							returns:"isJson"
						}					
					}
				}
				
			},
			"?action=main.httpspec&test={test}":{
				get:{
					"Should switch out the variable in the URL with a path":{
						given:{
							path:{
								test:"value"
							}
						},
						then:{
							returns:"isHTML"
						}
					}
				}
			}
		}
	}
</cfscript>