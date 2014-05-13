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
			}
		}
	}
</cfscript>