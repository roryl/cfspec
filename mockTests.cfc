/**
*
* 
* @author  Rory Laitila
* @description 
*
*/

component extends="affiliates.core.utilities.raakatest.testCase" {

	public function setup()
	{
		mock = createObject("component","mock");
	}

	function init_givenValidComponentPath_returnsThis()
	{
		result = mock.init("mockTestHelper");
		assert(isObject(result));
		assert(isStruct(result.getMeta()),"init function did not get meta data");
		assert(isStruct(result.getMethodSignatures()),"init function did not build method signatures");
		assert(isStruct(result.getMethodCallCounts()),"init function did not build call count structure");
		assert(isStruct(result.getMethodReturns()),"init function did not set default MethodReturns");
	}

	/**
	* @mxunit:expectedException "expression"
	*/
	function init_givenInvalidComponentPath_returnsExpressionException()
	{
		result = mock.init("mockTestHelpera");
		assert(isObject(result));
	}

	/**
	* @mxunit:expectedException "Missing Method"
	*/
	function onMissingMethod_ifMethodDoesNotExist_throwsException()
	{
		//Initialize the mock proxy with any object that we are going to try a function on
		mock.init("mock");
		//Call a function that we know doesn't exist
		mock.someFunction();
		
	}

	/**
	* @mxunit:expectedException "Missing Argument"
	*/
	function onMissingMethod_givenNoArgumentsButRequiresArguments_ThrowsMissingArgumentException()
	{
		//Initialize the mock on itself so that we have an object to construct a function on
		mock.init("mockTestHelper");

		//Call a function on the mockTestHelper without passing in the correct variables and this should error
		mock.testFunc();
	}

	/**
	* @mxunit:expectedException "Missing Argument"
	*/
	function onMissingMethod_givenPositionalArgumentsButMissingAnArgument_ThrowsMissingArgumentException()
	{
		//Initialize the mock on itself so that we have an object to construct a function on
		mock.init("mockTestHelper");

		//Call a function on the mockTestHelper without passing in the correct variables and this should error
		mock.testFunc("string","string");
	}

	/**
	* @mxunit:expectedException "Missing Argument"
	*/
	function onMissingMethod_givenNamedArgumentButMissingArgument_ThrowsMissingArgumentException()
	{
		//Initialize the mock on itself so that we have an object to construct a function on
		mock.init("mockTestHelper");

		//Call a function on the mockTestHelper without passing in the correct variables and this should error
		mock.testFunc(var1="string",var3="string");
	}

	/**
	* @mxunit:expectedException "Invalid Type"
	*/
	function onMissingMethod_ifArgumentIsNotOFRequiredtype_throwsInvalidTypeException()
	{
		//Initialize the mock on itself so that we have an object to construct a function on
		mock.init("mockTestHelper");

		//Call a function on the mockTestHelper without passing in the correct variables and this should error
		mock.testFunc([],"string","string");
	}

	function Count()
	{
		mock.init("mockTestHelper");
		mock.testFunc("string","string","string");
		assert(mock.Count("testfunc") IS 1);
	}

	function method_givenString()
	{
		mock.init("mockTestHelper");
		result = mock.method("testFunc");
		assert(isObject(result));
		assert(mock.getLastMethodReturnName() IS "testFunc");
	}

	/**
	* @mxunit:expectedException "Missing Method"
	*/
	function method_givenMethodThatDoesntExist()
	{
		mock.init("mockTestHelper");
		mock.method("testfunc2").returns(true);
	}
		
	function return_givenFunctionNameAndValues()
	{
		mock.init("mockTestHelper");
		result = mock.method("testfunc").returns({test="true"});
		assert(isObject(result),"The return method did not return an instance of the mock");
		assert(structKeyExists(mock.getMethodReturns(),"testFunc"));
		assert(mock.testFunc("string","string","string").test);
	}

	public function isType_givenTypeStringAndNotString_returnsFalse()
	{
		makePublic(mock,"isType");
		assertFalse(mock.isType("string",[]));
	}

	public function isType_givenTypeStringAndIsString_returnsTrue()
	{
		makePublic(mock,"isType");
		assert(mock.isType("string","string"));
	}

	public function testMockSpec()
	{
		DAO = new affiliates.core.service.model.emailDAO("affiliates_admin");
		Email = new affiliates.core.service.model.email(DAO=DAO,useProxy=false);

		mockEmail = new mock(email);

		
		

	}


}