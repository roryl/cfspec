/**
*
* @author  Rory Laitila
* @description Takes a specification document, parses it and has method to return data from that spec
*
*/

component accessors="true"  {

	property name="specSchema" setter="false";
	property name="testsService";
	property name="scenariosService";


	public function init(spec){
		//The spec can either be a path or a spec struct. If it is a simple value then we want to include the spec
		
		if(isSimpleValue(arguments.spec))
		{

			if(fileExists(arguments.spec))
			{
				local.spec = "";
				include template="#arguments.spec#";
				variables.specSchema = local.spec;				
			}
			else{
				throw("file not found, #arguments.spec#");
			}
		}
		else
		{
			variables.specSchema = arguments.spec;
		}
		variables.testsService = new tests(spec=this,tests=variables.specSchema.tests);	
		//variables.scenariosService = new scenarios(spec)
		return this;
	}

	public function getClass()
	{			
		return variables.specSchema.class;
	}

	public function getTests()
	{
		return new tests(spec=this,tests=variables.specSchema.tests);
	}

	public function getAllTests(){
		return variables.testsService.getAllTests();
	}



}