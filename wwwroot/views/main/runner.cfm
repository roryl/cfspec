Affiliates Test Suite
<cfscript>
setting requestTimeout="6000";
param name="url.dir" default="/cfspec/tests/cfspec";
application.settings.testrunnerMappingPath = "/var/www";

function getTestFiles(required mapping,required root,required filter){
	output = {};

	files = directoryList(expandPath(arguments.mapping),true,"query",arguments.filter);	
	
	for(i=1;i LTE files.recordCount; i=i+1)
	{
		fullName = files["directory"][i] & "/" & files["name"][i];
		template = replace(files["name"][i],".cfc","");
		finalpath = replace(files["directory"][i],root,"");
		finalpath = replace(finalpath,"/",".","all");
		finalpath = replace(finalpath,"\",".","all");

		output[fullName].path = "#finalPath#.#template#";
	}
	
	return output;
}

if(structKeyExists(url,"compile"))
{
	if(structKeyExists(url,"com"))
	{
		specFile = replace(url.com,".","/","all");
		specFile = replace(specFile,"Tests",".spec");
		specFile = replace(specFile,"/cfspec/tests/","/");
		spec = new cfspec.core.spec.specParser().parseSpec("#specFile#","/cfspec/tests");
	}
	else{
		dirPath = replace(url.dir,"/cfspec/tests/","/cfspec");
		spec = new cfspec.core.spec.specParser().parseAllSpecs(dirPath,"/cfspec/tests");
	}
}
	



if(NOT structKeyExists(application,"tests") OR structKeyExists(url,"reloadFiles"))
{
	//application.tests = {}
	application.tests = getTestFiles("#url.dir#",application.settings.testrunnerMappingPath,"*Tests.cfc");	
}

//Run Unit Specs
if(NOT structKeyExists(application,"specs") OR structKeyExists(url,"reloadFiles"))
{
	application.specs = getTestFiles("#url.dir#",application.settings.testrunnerMappingPath,"*Spec.cfc");	
}

structAppend(application.tests,application.specs);

//Create the test suite
testSuite = createObject("component","/mxunit.framework.TestSuite").TestSuite();

//If a particulat component is passed in:
if(structKeyExists(url,"com"))
{
	if(structKeyExists(url,"test"))
	{
		specFile = replace(url.com,"Tests",".spec");
		specFile = replace(specFile,"/cfspec/tests/","/");
		local.specObject = new cfspec.core.spec.reader.spec(specFile);
		local.tests = local.specObject.getTests().getTestByName(url.test).getUnitTestNames();
		testSuite.add(url.com,arrayToList(local.tests));
	}
	else
	{
		//Add all of the functions in the test
		testSuite.addAll(url.com); 
	}
}
else 
{
	count = 0;
	for(key in application.tests)
	{
		count=count+1;
		testSuite.addAll(application.tests[key].path); //Identical to above	

	
	}
}




if(structKeyExists(url,"testMethod"))
{
	results = testSuite.run(testMethod=url.testMethod);
}
else{
	results = testSuite.run();
}


//Now print the results. Simple\!
writeOutput(results.getResultsOutput('html')); //See next section for other output formats

request.layout = false;

</cfscript>
