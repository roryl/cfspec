/**
*
* 
* @author  Rory Laitila
* @description A collaborator A which will depend on B
*
*/

component output="false" displayname=""  {

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
		return variables.collaboratorB.getComplexValue();
	}
}