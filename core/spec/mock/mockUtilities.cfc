/**
*
* 
* @author  Rory Laitila
* @description Contains a number of utility functions which will be copied into the scope of components being mocked
*
*/

component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public function executeSQL(required string SQLString, datasource="")
	{
		return genericQuery(arguments.SQLString,arguments.datasource);
	}

	public function genericQuery(required string SQLString, datasource){		
		
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