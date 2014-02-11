/**
*
* 
* @author  Rory Laitila
* @description A basic object that will be used to test multi level collaborators
*
*/

component output="false" displayname=""  {

	public function init(){
		variables.collaboratorA = new collaboratorA();
		return this;
	}

	public function getSimpleValues()
	{
		return variables.collaboratorA.getSimpleValue();
	}

	public function getComplexValues(){
		return variables.collaboratorA.getComplexValue();
	}


}