/**
*
* @file  /C/websites/affiliates/core/utilities/queryStringTest.cfc
* @author  
* @description
*
*/
import ../queryString;
component output="false" extends="mxunit.framework.TestCase"  {

	public function setUp() {
		variables.queryString = new queryString("");
	}

	//TESTING INITIALIZATION
	public function when_Initializing_QueryString_It_Should_Return_QueryString() {
		var meta = getMetaData(variables.queryString);
		assert(meta.name CONTAINS "queryString");
		assertEquals(meta.type,"component");
		
	}

	//TESTING GET()
	public function get_whenProtocolIsSet_ShouldReturnProtocol() {
		variables.queryString.setProtocol("http://");
		assertEquals("http://",variables.queryString.get());

	}

	public function get_whenDomainIsSet_ShouldReturnDomain() {
		variables.queryString.setDomain("www.domain.com");
		assertEquals("www.domain.com",variables.queryString.get());
	}


	//TEST ADD()
	public function add_WhenGivenAVariable_shouldReturnQueryString() {
		variables.queryString.add("testVar");
		var meta = getMetaData(variables.queryString);
		assert(meta.name CONTAINS "queryString");
		assertEquals(meta.type,"component");
	}

	public function add_WhenGivenAVariableAndGetIsCalled_shouldAddTheVariableToTheQueryString() {
		variables.queryString.add("testVar","value");
		assert(variables.queryString.get() CONTAINS "testVar=value");
	}


}