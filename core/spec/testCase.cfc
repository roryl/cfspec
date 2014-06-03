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

	private function executeSQL(required string SQLString, datasource="")
	{
		return genericQuery(arguments.SQLString,arguments.datasource);
	}

	private function genericQuery(required string SQLString, datasource){		
		
		local.result = true;
		if(structKeyExists(arguments,"datasource") AND trim(arguments.datasource) IS NOT "")
		{
			query name="local.result" datasource="#arguments.datasource#"{
				echo("#arguments.sqlString#");
			}
		}
		else
		{
			query name="local.result"{
				echo("#arguments.sqlString#");
			}
		}		
		return local.result;
	}
	
}