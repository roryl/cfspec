/**
*
* 
* @author  Rory Laitila
* @description This component assist us in being a dummy object that one might want to mock. 
*
*/

component {

	public function init(){
		return this;
	}

	public function testFunc(required string var1, required string var2, required string var3)
	{
		return true;
	}
}