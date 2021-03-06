/**
*
* 
* @author  Rory Laitila
* @description A collaborator B which will depend on C
*
*/

component output="false" displayname="" accessors="true" {

	property name="collaboratorC";

	public function init(){
		variables.collaboratorC = new collaboratorC();
		return this;
	}

	public function getSimpleValue()
	{		
		writeLog(file="mock",text="CALLED CollaboratorB.getSimpleValue()");
		return variables.collaboratorC.getSimpleValue();
	}

	public function getComplexValue()
	{
		writeLog(file="mock",text="CALLED CollaboratorB.getComplexValue()");
		return variables.collaboratorC.getComplexValue();
	}
}