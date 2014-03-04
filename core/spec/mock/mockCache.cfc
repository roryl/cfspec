/**
*
* @author  Rory Laitila
* @description Handles caching results from function calls for mimic tests
*
*/

component output="false" displayname=""  {

	public function init(){
		if(NOT structKeyExists(application,"cfspecCache") OR structKeyExists(url,"flushcache"))
		{
			application.cfspecCache = {}
		}
		return this;
	}

	public function cacheGet(required string key)
	{
		if(structKeyExists(application.cfspecCache,key))
		{
			return application.cfspecCache[arguments.key];
		}
		else
		{
			return false;
		}
	}

	public function cachePut(required any value, required string key)
	{
		application.cfspecCache[arguments.key] = arguments.value;
	}
}