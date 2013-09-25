/**
*
* 
* @author  Rory Laitila
* @description A utility class for assisting with builting out entity tests
*
*/

component {

	public function init(componentPath){
		variables.metaData = getComponentMetaData(arguments.componentPath);
		return this;
	}

	public function getSimpleProperties(){
		var properties = variables.metaData.properties;
		var simpleProps = [];
		for(var prop in properties)
		{	
			if(NOT (structKeyExists(prop,"fieldType") OR (structKeyExists(prop,"insert") AND prop.insert IS false)))
			{
				arrayAppend(simpleProps,prop);
			}

		}
		return simpleProps;
	}

	public function getEntityName(){
		return listLast(metaData.fullName,".");
	}
}