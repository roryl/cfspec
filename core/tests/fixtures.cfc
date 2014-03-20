/**
*
* 
* @author  Rory Laitila
* @description This is a basic component that will be used to verify that the test fixtures (before, setup, after, teardown, etc) are called. We have some
* empty functions which serve as hooks to run a specification. The actual assets and tests are in the fixtures.spec
*
*/

component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public function basicFunction()
	{
		return true;
	}	

	public function checkBeforeArguments(){
		return true;
	}

	public function checkAfterArguments(){
		return true;
	}

	public function factoryScenarioTest(){
		return true;
	}

}