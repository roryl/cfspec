/**
*
* 
* @author  Rory Laitila
* @description A collaborator A which will depend on B
*
*/

component output="false" displayname="" accessors="true" {

	property name="collaboratorB";

	public function init(){
		variables.collaboratorB = new collaboratorB();
		return this;
	}

	public function getSimpleValue()
	{
		return variables.collaboratorB.getSimpleValue();
	}

	public function getComplexValue()
	{
		writeLog(file="mock",text="CALLED CollaboratorA.getComplexValue()");
		return variables.collaboratorB.getComplexValue();
	}

	public function getSimpleAndComplexValue()
	{
		variables.collaboratorB.getSimpleValue();
		variables.collaboratorB.getComplexValue();
	}
}