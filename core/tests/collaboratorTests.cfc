/**
*
* 
* @author  Rory Laitila
* @description A basic object that will be used to test multi level collaborators
*
*/

component output="false" displayname="" accessors="true"{

	property name="collaboratorA";

	public function init(){
		variables.collaboratorA = new collaboratorA();
		variables.collaboratorC = new collaboratorA();
		variables.localVariable ="My local variable";
		return this;
	}

	public string function getSimpleValues()
	{
		return variables.collaboratorA.getSimpleValue();
	}

	public function getComplexValues(){
		writeLog(file="mock",text="CALLED collaboratorTests.getComplexValue()");
		return variables.collaboratorA.getComplexValue();
	}

	public function getLocalVariable(){
		return variables.localVariable;
	}

	public function getCollaboratorC()
	{

	}


}