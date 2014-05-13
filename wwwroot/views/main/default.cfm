<cfoutput>

<form>
	Spec File Paths: <input name="specPath" id="specPath" value="#rc.specPath#"><br />
	Output Compile Path: <input name="compilePath" id="compilePath" value="#rc.compilePath#"><br />
	<input type="submit" name="submit" value="Compile!">
	<input type="checkbox" name="reloadFiles" #((isDefined('form.checkbox'))?'checked="true"':'')#>	
</form>
<cfif structKeyExists(rc,"specFiles")>	
	<cfloop array="#rc.specFiles#" item="file" index="i">
	  <cfset com = replace(file.path,".spec","Tests")>
	  <cfset allTests = new cfspec.core.spec.reader.spec(file.path).getAllTests()>
	  <a href="/?action=main.runner&dir=#rc.compilePath#&com=#rc.compilePath##com#&compile" target="_blank">#file.file#</a><br />
	  <cfloop array="#allTests#" item="test" index="i">
	    -----<a href="/?action=main.runner&dir=#rc.compilePath#&com=#rc.compilePath##com#&test=#test.getTestName()#&compile" target="_blank">#test.getTestName()#</a><br />
	  </cfloop>
	</cfloop>
</cfif>
</cfoutput>