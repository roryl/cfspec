/**
*
* 
* @author  
* @description
*
*/

component extends="testCase" {

	public function func(){

		spec = {
			given:{
				arguments:{
					arg1:true
				}
			},
			when:{
				"session.value":false
			},
			assert:{
				returns:false
			}
		}

		return spec;

	}
}