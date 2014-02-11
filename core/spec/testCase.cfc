/**
*
* 
* @author  
* @description
*
*/

component extends="mxunit.framework.testCase" {

	

	private function booleanRecordCountEQ1(required string SQLString)
	{
		local.result = genericQuery(arguments.SQLString);
		
		if(local.result.recordCount IS 1)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	private function executeSQL(required string SQLString)
	{
		return genericQuery(arguments.SQLString);
	}

	private function genericQuery(required string SQLString){
		
		local.result = true;
		query name="local.result"{
			echo("#arguments.sqlString#");
		}
		return local.result
	}
	
}