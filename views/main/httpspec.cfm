<cfsetting showdebugoutput="false">
<cfscript>	
	response = serialize(CGI);
	writeOutput(response);
	request.layout = false;
</cfscript>