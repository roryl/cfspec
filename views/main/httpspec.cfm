<cfsetting showdebugoutput="false">
<cfscript>
	http url="http://dev.cfspec.com?action=main.httpspec";
	
	response = serialize(CGI);
	writeOutput(response);
	request.layout = false;
</cfscript>