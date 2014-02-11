component output="true" hint="Example FW/1 controller."{


	
	public function init(fw)
		output="false" hint="Constructor, passed in the FW/1 instance."
	{
		variables.fw = arguments.fw;
		return this;
	}
		
	public function default(rc){
		param name="rc.specPath" default="";
		param name="rc.compilePath" default="";

		if(structKeyExists(rc,"submit"))
		{
			if(rc.specPath IS NOT ""){
				if(NOT directoryExists(rc.specPath))
				{
					throw('the spec path directory specified #rc.specPAth# does not exist');
				}
			}
			if(rc.compilePath IS NOT ""){
				if(NOT directoryExists(rc.compilePath))
				{
					//throw('the compile path directory specified #rc.compilePath# does not exist');
				}
			}

			//Do the compile
			rc.FinishedSpecs = new cfspec.core.spec.specParser().parseAllSpecs(rc.specPath,rc.compilePath);			
		}
	}

	public function compile()
	{
		param name="rc.compilePath" default="";
		param name="rc.outputPath" default="";

		if(structKeyExists(rc,"submit"))
		{
			rc.spec = new cfspec.core.spec.specParser().parseAllSpecs(rc.compilePath,rc.outputPath);
		}
	}
	
	
}