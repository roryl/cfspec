/**
*
* 
* @author  Rory Laitila
* @description A utility class for assisting with builting out entity tests
*
*/

component {

	public function init(entity){
		variables.metaData = getComponentMetaData(entityNew(arguments.entity));
		return this;
	}

	public function getSimpleProperties(){
		var properties = variables.metaData.properties;
		var simpleProps = [];
		for(var prop in properties)
		{				
			if(NOT structKeyExists(prop,"fieldType"))
			{
				if(structKeyExists(prop,"insert") AND prop.insert IS NOT "false")
				{					
					arrayAppend(simpleProps,prop);
				}
				else if(NOT structKeyExists(prop,"insert"))
				{
					arrayAppend(simpleProps,prop);
				}
			}

		}
		return simpleProps;
	}

	public function getRelationships()
	{
		local.properties = variables.metaData.properties;
		local.relationships = [];
		for(local.prop in local.properties)
		{
			if(structKeyExists(local.prop,"fieldtype") AND local.prop.fieldtype IS NOT "id" AND NOT structKeyExists(local.prop, "specskiptest"))
			{
				arrayAppend(local.relationships,local.prop);
			}
		}
		return relationships;
	}

	public function getEntityName(){
		return listLast(variables.metaData.fullName,".");
	}

	public function getRelationshipReverseProperty(required entityName, required fieldType){
		local.relationships = getRelationships();
		for(local.relation IN local.relationships)
		{
			if(local.relation.cfc IS arguments.entityName AND local.relation.fieldType IS arguments.fieldType)
			{
				return local.relation;
			}
		}		
	}
}