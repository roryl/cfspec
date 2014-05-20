/**
*
* @file  /C/websites/affiliates/admin/wwwroot/mxunit/doc/tutorial/mytests/MyComponentTest.cfc
* @author  
* @description
*
*/

component extends="mxunit.framework.TestCase"  {

	public void function testAdd()
	{
		mycomponent = createObject("component","MyComponent");
    	expected = 2;
    	actual = mycomponent.add(1,1);
    	assertEquals(expected,actual);
	}

}