component output="false" displayname=""  {

	public function init(){
		return this;
	}

	public function returnArgumentString(required theString){
		return arguments.theString;
	}

	public function returnArgumentType(required any theArgument)
	{
		return theArgument;
	}

	public function dependsOnState()
	{
		return request.stateValue;
	}
}