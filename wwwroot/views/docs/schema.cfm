<cfscript>

import "cfspec.libraries.querystring.querystring";
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

<cfif structKeyExists(url,"httptester")>
	<cfinclude template="/cfspec/core/spec/httpTesterSchema.cfm">	
<cfelse>
	<cfinclude template="/cfspec/core/spec/specSchema.cfm">	
</cfif>


<style>
 .panel {
 	text-align:left;
 }
</style>
<cfset variables.i = 0>
<cfparam name="url.entryNode" default="">

<cffunction name="buildExample" output="false">
	<cfargument name="lastNode">
	<cfargument name="exampleIndex" default="1">
	<cfscript>
		local.nodeList = arguments.lastNode
		local.exampleIndex = arguments.exampleIndex;
		//Starting from the last node, add the example to the previous example
		previousExample = "";
		finalExample = "";
		
		//If it is the first time this function is called, the node list will be empty, so we set it to the first array 
		//from the spec
		if(local.nodeList IS "")
		{
			local.nodeList = "[1]";
		}

		for(var i = listLen(local.nodeList,"."); i GTE 1; i=i-1)
		{
			//writeDump(local.nodeList);
			//writeDump(i);
			evaluate("currentExample = variables.schema.children#local.nodeList#.example[#local.exampleIndex#].code");
			//writeDump(currentExample);
			finalExample = replaceNoCase(currentExample,"//Children",previousExample);
			//writeDump(finalExample);
			previousExample = finalExample;
			local.nodeList = listDeleteAt(local.nodeList,listLen(local.nodeList,"."),".");
			//Set the exampleIndex back to 1 because we only want this to apply to the first example. All 
			//parent examples should always use the first
			local.exampleIndex = 1;
		}
		//Root example
		rootExample = "spec = {//Children}";
		finalExample = replaceNoCase(rootExample,"//Children",finalExample);
		

		//evaluate("writeDump(variables.schema.children#arguments.lastNode#)");
		return trim(finalExample);
	</cfscript>		
</cffunction>

<cffunction name="drawNodes" output="true">
	<cfargument name="schema">
	<cfargument name="entryNode">
	<cfset querystring = new queryString(CGI.QUERY_STRING)>
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
			
			if(structKeyExists(request,"isFirstEntryNode"))
			{
				local.entryNode = arguments.entryNode & "[#key#]";
			}
			else
			{
				local.entryNode = arguments.entryNode;
			}
			request.isFirstEntryNode = true;
			
			
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
			        

			        <cfif listLen(local.entryNode,".") GT 0>
			        	<cfset local.parentNode = listDeleteAt(local.entryNode,listLen(local.entryNode,"."),".")>
			        <cfelse>
			        	<cfset local.parentNode = local.entryNode>
			        </cfif>
			       
			        <div style="float:right;">
			        <a href="/#queryString.setValue("entryNode",local.parentNode).get()#"><span class="glyphicon glyphicon-circle-arrow-left"></span></a> 
			        <a href="/#queryString.setValue("entryNode",local.entryNode).get()#">Goto Node</a>
			        </div>
			      </h4>
			    </div>
			    <div id="collapse#i#" class="panel-collapse collapse">
			      <div class="panel-body">
			         <ul>
			         	<li><strong>Description:</strong> #local.description#</li>
			         	<li><strong>Data Types:</strong> #local.Types#</li>
			         	<li><strong>Examples:</strong><br />
			       		<cftry>
				       		<div style="padding-left:15px;">
					         	<cfloop from="1" to="#arrayLen(local.example)#" index="index2">
					         		<cfset workingExample = local.example[index2]>
					         		<cfset local.exampleCode = workingExample.code>
					         		<div style="margin-top:10px;"><strong>Example #index2#</strong>
						         		<cfif structKeyExists(workingExample,"title")>
						         		:#workingExample.title#
						         		</cfif>
						         		<cfif structKeyExists(workingExample,"type")>
						         		using the type of <i>#workingExample.type#</i>
						         		</cfif>
					         		</div>
					         		<cfif structKeyExists(workingExample,"description")>
						         	<div><b>Description:</b> #workingExample.description#</div>
						         		
						         	</cfif>
					         		
					         		<pre style="margin-top:15px">#formatJson(local.exampleCode)#</pre>
					         		<cfset exampleId = createUUID()>
						         	<pre id="full#exampleId#"style="margin-top:15px; display:none">#formatJson(buildExample(local.entryNode,index2))#</pre>
									<a href="Javascript:$('##full#exampleId#').toggle();">Show/Hide Full Example</a>
					         	</cfloop>
					         	<cfcatch type="any">
					       				<cfdump var="#local.example#" abort="true">
					       			</cfcatch>
					       		</cftry>
				       		</div>
			         	</li>
			        	
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