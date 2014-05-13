<cfoutput>
  <form role="form" method="post" action="">
    <div class="form-group">
      <label for="compilePath">Spec File Path</label>
      <input class="form-control" id="compilePath" name="compilePath" placeholder="Enter system directory or CF Mapping" value="#rc.compilePath#">
    </div>
    <div class="form-group">
      <label for="outputPath">Output Path</label>
      <input class="form-control" id="outputPath" name="outputPath" placeholder="/cfspec/tests" value="#rc.outputPath#">
    </div>  
    <button name="submit" type="submit" class="btn btn-default">Submit</button>
  </form>
</cfoutput>
</cfoutput>
<cfdump var="#rc.spec#">