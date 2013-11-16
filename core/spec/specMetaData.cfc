/**
*
* 
* @author  Rory Laitila
* @description Creates and manages meta data about the specs being run. Useful for reporting purposes
*
*/

component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public function new(){
		if(NOT structKeyExists(request,"cfspecMetaData"))
		{
			request.cfspecMetaData = queryNew("id,parentClass,class,given,whenScope,whenVariable,withFunction,isMimic,then,elapsed");
		}
		
		return this;
	}

	public function add(required class, given="",whenScope="",whenVariable="",withFunction="",isMimic="",then="",elapsed=""){
		if(NOT structKeyExists(request,"lastClass"))
		{
			request.lastClass = "root";
		}
		

		request.cfspecMetaData.addRow([request.cfspecMetaData.recordCount + 1,
									   request.lastClass,
		                               arguments.class,
		                               arguments.given,
		                               arguments.whenScope,
		                               arguments.whenVariable,
		                               arguments.withFunction,
		                               arguments.isMimic,
		                               arguments.then,
		                               arguments.elapsed]);

		request.lastClass = arguments.class;

		return this;
	}


}