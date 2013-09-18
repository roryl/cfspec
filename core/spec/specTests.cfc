component extends="mxunit.framework.testCase" {

	public function checkLogin_Should_return_false(){
		var test = new affiliates.public.core.controllers.members()

		test.mockOverride = function(variableName){variables[#arguments.variableName#] = new affiliates.core.utilities.raakatest.mock(variables[#arguments.variableName#]);}

		test.MockOverride("emailService");
		test.MockOverride("emailerService");
		test.MockOverride("couponAlertsService");
		test.MockOverride("priceAlertsService");
		test.override = function(variableName,value){
										if(listFirst(arguments.variableName,".") IS "request")
										{
											var remainder = listDeleteAt(arguments.variableName,1,".");
											request[remainder] = arguments.value
										}
										else
										{
											#arguments.variableName# = arguments.value;	
										}
										
									}

		test.override("session.isLoggedIn",false)
		coll = {};

		test.checkLogin(argumentCollection=coll);

	}

	public function signup_Should_display_error_template(){
		var test = new affiliates.public.core.controllers.members()

		test.mockOverride = function(variableName){variables[#arguments.variableName#] = new affiliates.core.utilities.raakatest.mock(variables[#arguments.variableName#]);}

		test.MockOverride("emailService");
		test.MockOverride("emailerService");
		test.MockOverride("couponAlertsService");
		test.MockOverride("priceAlertsService");
		test.override = function(variableName,value){
										if(listFirst(arguments.variableName,".") IS "request")
										{
											var remainder = listDeleteAt(arguments.variableName,1,".");
											request[remainder] = arguments.value
										}
										else
										{
											#arguments.variableName# = arguments.value;	
										}
										
									}

		test.override("request.currentStore",1)
		test.mockFunction = function(mockObject,mockFunction,value){
										variables[arguments.mockObject].method(arguments.mockFunction).returns(arguments.value);
									}
		test.mockFunction("emailService","checkEmailExists","true");
		test.mockFunction("emailService","createNewTempPassword","testpassword");
		coll = {'rc':{'price':'$12.99','email':'roryl@nhtcomputer.com','submitted':'true','storeName':'dev.testsite.com','pid':'12345','returnUrl':'dev.testsite.com/test'}};

		test.signup(argumentCollection=coll);

	}

	public function signup_Should_signup_the_user(){
		var test = new affiliates.public.core.controllers.members()

		test.mockOverride = function(variableName){variables[#arguments.variableName#] = new affiliates.core.utilities.raakatest.mock(variables[#arguments.variableName#]);}

		test.MockOverride("emailService");
		test.MockOverride("emailerService");
		test.MockOverride("couponAlertsService");
		test.MockOverride("priceAlertsService");
		test.override = function(variableName,value){
										if(listFirst(arguments.variableName,".") IS "request")
										{
											var remainder = listDeleteAt(arguments.variableName,1,".");
											request[remainder] = arguments.value
										}
										else
										{
											#arguments.variableName# = arguments.value;	
										}
										
									}

		test.override("request.currentStore",1)
		test.mockFunction = function(mockObject,mockFunction,value){
										variables[arguments.mockObject].method(arguments.mockFunction).returns(arguments.value);
									}
		test.mockFunction("emailService","checkEmailExists","true");
		test.mockFunction("emailService","createNewTempPassword","testpassword");
		coll = {'rc':{'price':'$12.99','email':'roryl@nhtcomputer.com','submitted':'true','storeName':'dev.testsite.com','pid':'12345','returnUrl':'dev.testsite.com/test'}};

		test.signup(argumentCollection=coll);

	}


	
}