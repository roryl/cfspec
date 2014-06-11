<cfscript>
	spec = {
		class:"cfspec.core.spec.httpTester",
		mockObjects:[""],
		factory:function(){
			return createObject("component","httpTester");
		},		
		tests:{
			setup:function(){
				request.basicHTTPResponse = evaluate("{'status_text':'OK','status_code':200,'responseheader':{'status_code':200,'Content-Type':'text/html;charset=UTF-8','Connection':'close','set-cookie':['CFID=7c5e375b-93a8-4530-bfa4-9f80a51237fb; Expires=Wed, 11-May-2044 23:54:17 GMT; Path=/','CFTOKEN=0; Expires=Wed, 11-May-2044 23:54:17 GMT; Path=/'],'Content-Length':'1144','explanation':'OK','Server':'Apache-Coyote/1.1','Date':'Tue, 13 May 2014 16:03:54 GMT'},'mimetype':'text/html','text':true,'filecontent':' {''auth_password'':'''',''auth_type'':'''',''auth_user'':'''',''cert_cookie'':'''',''cert_flags'':'''',''cert_issuer'':'''',''cert_keysize'':'''',''cert_secretkeysize'':'''',''cert_serialnumber'':'''',''cert_server_issuer'':'''',''cert_server_subject'':'''',''cert_subject'':'''',''cf_template_path'':''/var/www/cfspec/index.cfm'',''content_length'':''0'',''content_type'':''application/x-www-form-urlencoded; charset=UTF-8'',''gateway_interface'':'''',''http_accept'':'''',''http_accept_encoding'':''gzip'',''http_accept_language'':'''',''http_connection'':''Keep-Alive'',''http_cookie'':'''',''http_host'':''dev.cfspec.com'',''http_user_agent'':''Railo (CFML Engine)'',''http_referer'':'''',''https'':'''',''https_keysize'':'''',''https_secretkeysize'':'''',''https_server_issuer'':'''',''https_server_subject'':'''',''path_info'':'''',''path_translated'':''/var/www/cfspec/index.cfm'',''query_string'':''action=main.httpspec'',''remote_addr'':''127.0.0.1'',''remote_host'':''127.0.0.1'',''remote_user'':'''',''request_method'':''PUT'',''script_name'':''/index.cfm'',''server_name'':''dev.cfspec.com'',''server_port'':''80'',''server_port_secure'':''0'',''server_protocol'':''HTTP/1.1'',''server_software'':'''',''web_server_api'':'''',''context_path'':'''',''local_addr'':''192.168.33.10'',''local_host'':''dev.local.com''}','http_version':'HTTP/1.1','errordetail':'','charset':'UTF-8','statuscode':'200 OK','header':'HTTP/1.1 200 OK Date: Tue, 13 May 2014 16:03:54 GMT Server: Apache-Coyote/1.1 Content-Type: text/html;charset=UTF-8 Content-Length: 1144 Set-Cookie: CFID=7c5e375b-93a8-4530-bfa4-9f80a51237fb; Expires=Wed, 11-May-2044 23:54:17 GMT; Path=/ Set-Cookie: CFTOKEN=0; Expires=Wed, 11-May-2044 23:54:17 GMT; Path=/ Connection: close '}");
			},
			init:{
				"Should patch the spec if a patch was supplied":{
					given:{
						specPath:"/cfspec/core/tests/httpspec.spec",
						method:"GET",
						resource:"?action=main.httpspec",
						scenario:"Should return hello",
						patch:{"given.url":"test"}
					},
					then:{
						returns:"isObject",
						assert:function(result, object){
							local.spec = object.getSpec()
						    assert(local.spec.tests[request.given.resource][request.given.method][request.given.scenario].given.url IS "test");
						    return true;
						}
					}
				},
			},
			getCookiesAsStruct:{
				"Should return a struct of the cookies from a given header":{
					given:{
						cookiesData:[
							"CFID=70147e17-7875-43a0-a970-cb226e78c37b; Expires=Wed, 01-Jun-2044 22:40:01 GMT; Path=/",
							"CFTOKEN=0; Expires=Wed, 01-Jun-2044 22:40:01 GMT; Path=/",
							"JSESSIONID=45F2936BBF44463073E8A583D8CCE93C; Path=/; HttpOnly"
						]
					},
					then:{
						returns:"isStruct",
						assert:function(result){
							assert(result.cfid.value IS "70147e17-7875-43a0-a970-cb226e78c37b");
							assert(result.CFTOKEN.value IS "0");
							assert(result.JSESSIONID.value IS "45F2936BBF44463073E8A583D8CCE93C");
							return true;
						}
					}
				}
			},
			doAssertStandardHTTPResponses:{
				"Should THEN call the basic responses as a text match":{
					given:function(result){
						return {
							httpResponse:request.basicHTTPResponse,
							context:{
								then:{
									returns:"isHTML",
									mimeType:"text/html",
									responseCode:200,
									responseText:"OK",
									errorDetail:"",
									charSet:"UTF-8",
									httpVersion:"HTTP/1.1",							
								}
							}
						}						
					},					
					then:{
						returns:"void",						
					}
				},				
			},
			doAsserts:{
				"Should call the assert function passing in the response variable":{
					given:function(result){
						return {
							response:request.basicHTTPResponse,
							specContext:{
								then:{
									assert:function(response){
										return false;
									}
								}
							} 
						}
					},
					then:{
						throws:"The assertion failed"
					}
				}
			},
			doAssertReturns:{
				"Should test for a json string if given a json string":{
					given:{
						httpFileContent:"{test:'test'}",
						responseType:"isJson"
					},
					then:{
						returns:true
					}
				},
				"Should fail for a json string which is not really json":{
					given:{
						httpFileContent:"test",
						responseType:"isJson"
					},
					then:{
						returns:false
					}
				},
				"Should test for an HTML string if given a json string":{
					given:{
						httpFileContent:"<html><body></body></html>",
						responseType:"isHTML"
					},
					then:{
						returns:true
					}
				}
			}
		}
	}
</cfscript>