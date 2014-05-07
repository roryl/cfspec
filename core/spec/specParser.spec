<cfscript>
	spec = {
		class:"cfspec.core.spec.specParser",
		mockObjects:[""],
		factory:function(){
			return createObject("component","specParser");
		},
		tests:{
			getSpecFiles:{
				"Should get the spec files":{
					given:{
						mapping:"/affiliates",
						ignore:["%.git%","%WEB-INF%","%.svn%","%deploy%","%docs%","%tests%","%.vagrant%","%assets%","%mxunit%","%buglog%","%libraries%","%dynatree-1.2.0%","%highcharts%","%reportalytics%"],
						filter:"%.spec%"
					},
					then:{
						returns:"isArray",
						assert:function(result){
							
							assert(result.len() GT 1);
							return true;
						}

					}
				}
			},
			getDirectoryFiles:{
				"Should get the recursed directory files ignoring and filtering":{
					before:function(){
						request.startTime = getTickCount();
						request.timeForDirectory = queryNew("path,time");
					},
					given:{
						path:"/var/www/affiliates",
						ignore:["%.git%","%WEB-INF%","%.svn%","%deploy%","%docs%","%tests%","%.vagrant%","%assets%","%mxunit%","%buglog%","%libraries%","%dynatree-1.2.0%","%highcharts%","%reportalytics%"],
						filter:"%.spec%"
					},
					then:{
						returns:"isQuery",
						assert:function(result){
							// writeDump(result);
							// writeDump(request.timeForDirectory.sort("time","DESC"));
							// abort;
							// writeDump(result);
							// abort;
							return true;
						}

					}
				},
				"Should ignore WEBINF":{
					before:function(){
						request.startTime = getTickCount();
						request.timeForDirectory = queryNew("path,time");
					},
					given:{
						path:"/var/www/affiliates/public/",
						ignore:["%WEB-INF%"],
						filter:"%.spec%"
					},
					then:{
						returns:"isQuery",
						assert:function(result){
							//writeDump(request.timeForDirectory.sort("time","DESC"));
							//abort;
							// writeDump(result);
							// abort;
							return true;
						}

					}
				}


			}
		}
	}
</cfscript>