<cfoutput>

<form>
	Spec File Paths: <input name="specPath" id="specPath" value="#rc.specPath#"><br />
	Output Compile Path: <input name="compilePath" id="compilePath" value="#rc.compilePath#"><br />
	<input type="submit" name="submit" value="Compile!">
	<input type="checkbox" name="reloadFiles" checked="true">
	<cfif structKeyExists(rc,"finishedSpecs")>
		<cfdump var="#rc.finishedSpecs#">
	</cfif>
</form>
</cfoutput>