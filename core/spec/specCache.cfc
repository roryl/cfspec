/**
*
* @author  Rory Laitila
* @description Gets and puts objects from the cfspec result cache
*
*/

component {
	public function init(){
		
		if(NOT isDefined("application.cfspec.cache"))
		{
			application.cfspec.cache = {};
		}	
		return this;
	}

	public function get(required cacheKey){
		if(structKeyExists(application.cfspec.cache,arguments.cacheKey))
		{
			return application.cfspec.cache[arguments.cacheKey];
		}
	}

	public function put(required cacheKey, required value){
		application.cfspec.cache[arguments.cacheKey] = arguments.value;
	}
}