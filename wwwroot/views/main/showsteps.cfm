<cfif structKeyExists(url,"step")>
	<cfdump var="#session.previousSaves[url.step]#">
</cfif>