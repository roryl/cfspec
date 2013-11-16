
<cfscript>
/**
 * Formats a JSON string with indents &amp; new lines.
 * v1.0 by Ben Koshy
 * 
 * @param str      JSON string (Required)
 * @return Returns a string of indent-formated JSON 
 * @author Ben Koshy (cf@animex.com) 
 * @version 0, September 16, 2012 
 */
// formatJSON() :: formats and indents JSON string
// based on blog post @ http://ketanjetty.com/coldfusion/javascript/format-json/
// modified for CFScript By Ben Koshy @animexcom
// usage: result = formatJSON('STRING TO BE FORMATTED') OR result = formatJSON(StringVariableToFormat);

public string function formatJSON(str) {
    var fjson = '';
    var pos = 0;
    var strLen = len(arguments.str);
    var indentStr = "&nbsp;&nbsp;&nbsp;&nbsp;"; // Adjust Indent Token If you Like
    var newLine = "<br />"; // Adjust New Line Token If you Like <BR>
    
    for (var i=1; i<=strLen; i++) {
        var char = mid(arguments.str,i,1);
        
        if (char == '}' || char == ']') {
            fjson &= newLine;
            pos = pos - 1;
            
            for (var j=1; j<=pos; j++) {
                fjson &= indentStr;
            }
        }
        
        fjson &= char;    
        
        if (char == '{' || char == '[' || char == ',') {
            fjson &= newLine;
            
            if (char == '{' || char == '[') {
                pos = pos + 1;
            }
            
            for (var k=1; k<=pos; k++) {
                fjson &= indentStr;
            }
        }
    }
    
    return fjson;
}
</cfscript>

<cfinclude template="/cfspec/core/spec/specSchema.cfm">
<style>
 .panel {
 	text-align:left;
 }
</style>
<cfset variables.i = 0>
<cfparam name="url.entryNode" default="">
<cffunction name="drawNodes" output="true">
	<cfargument name="schema">
	<cfargument name="entryNode">
	<cfsavecontent variable="html">
	
	<cfif NOT isArray(arguments.schema)>
		<cfset arguments.schema = [arguments.schema]>
	</cfif>
	<cfloop collection="#arguments.schema#" item="key">
		<cfscript>
			local.title = arguments.schema[key].title;
			local.description = arguments.schema[key].description;
			local.types = arguments.schema[key].types;
			local.example = arguments.schema[key].example;
			local.hasChildren = structKeyExists(arguments.schema[key],"children");
			local.isRequired = ((structKeyExists(arguments.schema[key],"required") AND arguments.schema[key].required IS True)?true :false);
			local.entryNode = arguments.entryNode & "[#key#]";
			
		</cfscript>

			<cfset variables.i = variables.i +1>
		

			<div class="panel panel-default">
			    <div class="panel-heading">
			      <h4 class="panel-title">
			        <a class="accordion-toggle" data-toggle="collapse"  href="##collapse#i#" data-toggle="tooltip" title="They name of the Key for the structure element.">
			          #local.title#
			        </a>
			        <cfif isRequired>
			        	<strong><i>(required)</i></strong>
			        <cfelse>
			        	<i>(optional)</i>
			        </cfif>
			        <a href="/?#CGI.query_String#&entryNode=#local.entryNode#" style="float:right;">Goto Node</a>
			      </h4>
			    </div>
			    <div id="collapse#i#" class="panel-collapse collapse">
			      <div class="panel-body">
			         <ul>
			         	<li><strong>Description:</strong> #local.description#</li>
			         	<li><strong>Data Types:</strong> #local.Types#</li>
			         	<li><strong>Example:</strong><pre style="margin-top:15px">#formatJson(local.example)#</pre></li>
			        
			         <cfif local.hasChildren>
			         	<li><strong>Has Children:</strong>
			         	<cfset drawNodes(arguments.schema[key].children,"#local.entryNode#.children")>
			         	</li>
			         </cfif>
			        </ul>
			      </div>
			    </div>
			</div>
		
		
	</cfloop>
	
	</cfsavecontent>
	<cfoutput>#html#</cfoutput>
</cffunction>



<!---<dass="panel-group" id="accordion">
  <div class="panel panel-default">
    <div class="panel-heading">
      <h4 class="panel-title">
        <a class="accordion-toggle" data-toggle="collapse"  href="#collapseOne">
          class
        </a>
      </h4>
    </div>
    <div id="collapseOne" class="panel-collapse collapse in">
      <div class="panel-body">
        <div class="panel panel-default">
		    <div class="panel-heading">
		      <h4 class="panel-title">
		        <a class="accordion-toggle" data-toggle="collapse"  href="#collapseInnerOne">
		          class
		        </a>
		      </h4>
		    </div>
		    <div id="collapseInnerOne" class="panel-collapse collapse in">
		      <div class="panel-body">
		        
		      </div>
		    </div>
		</div>
      </div>
    </div>
  </div>
  
</div>--->
<h4>Each specification must be a structure and contain the following required keys and may contain additional optional keys:</h4>
<div class="panel-group" id="accordion">

<cfset entryNode = schema.children>
<cfif structKeyExists(url,"entryNode") AND url.entryNode IS NOT "">
	<cfset entryNode = evaluate("schema.children#url.entryNode#")>
</cfif>


<cfset drawNodes(entryNode,url.entryNode)>
</div>

<cfoutput>

</cfoutput>