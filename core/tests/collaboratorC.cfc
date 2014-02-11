/**
*
* 
* @author  Rory Laitila
* @description A collaborator C which is depended upon by B
*
*/

component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public function getSimpleValue(){
		return "My simple value";
	}

	public function getComplexValue(){
		return {test:"value",test2:"value2",test3:"value3"}
	}
}