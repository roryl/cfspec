<cfscript>
	spec = {
		class:"cfspec.core.spec.httpTester",
		mockObjects:[""],
		factory:function(){
			return createObject("component","httpTester");
		},		
		tests:{
			setup:function(){
				request.basicHTTPResponse = deserializeJson('{"status_text":"OK","status_code":200,"responseheader":{"status_code":200,"Content-Type":"text\/html;charset=UTF-8","Connection":"close","set-cookie":["CFID=625262b5-05dc-47f5-b9af-7c1b75146e31; Expires=Thu, 05-May-2044 22:08:26 GMT; Path=\/","CFTOKEN=0; Expires=Thu, 05-May-2044 22:08:26 GMT; Path=\/"],"Content-Length":"1144","explanation":"OK","Server":"Apache-Coyote\/1.1","Date":"Wed, 07 May 2014 14:18:04 GMT"},"mimetype":"text\/html","text":true,"filecontent":"\r\n{'auth_password':'','auth_type':'','auth_user':'','cert_cookie':'','cert_flags':'','cert_issuer':'','cert_keysize':'','cert_secretkeysize':'','cert_serialnumber':'','cert_server_issuer':'','cert_server_subject':'','cert_subject':'','cf_template_path':'\/var\/www\/cfspec\/index.cfm','content_length':'0','content_type':'application\/x-www-form-urlencoded; charset=UTF-8','gateway_interface':'','http_accept':'','http_accept_encoding':'gzip','http_accept_language':'','http_connection':'Keep-Alive','http_cookie':'','http_host':'dev.cfspec.com','http_user_agent':'Railo (CFML Engine)','http_referer':'','https':'','https_keysize':'','https_secretkeysize':'','https_server_issuer':'','https_server_subject':'','path_info':'','path_translated':'\/var\/www\/cfspec\/index.cfm','query_string':'action=main.httpspec','remote_addr':'127.0.0.1','remote_host':'127.0.0.1','remote_user':'','request_method':'PUT','script_name':'\/index.cfm','server_name':'dev.cfspec.com','server_port':'80','server_port_secure':'0','server_protocol':'HTTP\/1.1','server_software':'','web_server_api':'','context_path':'','local_addr':'192.168.33.10','local_host':'dev.local.com'}","http_version":"HTTP\/1.1","errordetail":"","charset":"UTF-8","statuscode":"200 OK","header":"HTTP\/1.1 200 OK Date: Wed, 07 May 2014 14:18:04 GMT Server: Apache-Coyote\/1.1 Content-Type: text\/html;charset=UTF-8 Content-Length: 1144 Set-Cookie: CFID=625262b5-05dc-47f5-b9af-7c1b75146e31; Expires=Thu, 05-May-2044 22:08:26 GMT; Path=\/ Set-Cookie: CFTOKEN=0; Expires=Thu, 05-May-2044 22:08:26 GMT; Path=\/ Connection: close "}');
			},
			doAssertStandardHTTPResponses:{
				"Should pass if the mime type is the same":{
					given:function(result){
						return {
							httpResponse:request.basicHTTPResponse,
							context:{
								then:{
									returns:"isHTML",
									mimeType:""
								}
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