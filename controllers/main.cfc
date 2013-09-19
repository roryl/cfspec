component output="false" hint="Example FW/1 controller."{


	
	public function init(fw)
		output="false" hint="Constructor, passed in the FW/1 instance."
	{
		variables.fw = arguments.fw;
		return this;
	}
		
	public function default(rc){
		param name="rc.specPath" default="";
		param name="rc.compilePath" default="";

		if(rc.specPath IS NOT ""){
			if(NOT directoryExists(rc.specPath))
			{
				throw('the spec path directory specified #rc.specPAth# does not exist');
			}
		}
		if(rc.compilePath IS NOT ""){
			if(NOT directoryExists(rc.compilePath))
			{
				throw('the compile path directory specified #rc.compilePath# does not exist');
			}
		}
	}
	
	
}