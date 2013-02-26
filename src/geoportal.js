//Define si se hace la carga del swf omitiendo el cache del navegador. Solo se debe dejar habilidato un tiempo corto despues de realizar una actualizacion.
var noCache = false;


var aplicacion = getURLParam("idAplicacion");
var config = "";
if(aplicacion != "")
{
	var hostname = location.hostname;
	var a = hostname.split(".");
	var host = "";
		
	if(a.length > 0)
	{
		if( !isNaN( parseInt(a[0]) ) )
		{
			host = location.hostname;
		}
	}
		
	if(host == "")
	{
		host = location.protocol + "//" + location.host + location.pathname;
		host = host.substring(0, host.lastIndexOf("/") + 1);
	}

	aplicacion = "leocansonaplicacion=" + aplicacion;
	


	/**DGSIGE
	config = "http://10.57.28.26:8030/Geoportal/Geoportal?operacion=obtenerXMLAplicacionleocansonref=" + host + aplicacion;
	//**/
	
	
	/**Systema 47**/
	config = "http://190.25.231.241:8030/Geoportal/Geoportal?operacion=obtenerXMLAplicacionleocansonref=" + host + aplicacion;
	//**/
	
	/**DG_EST19
	config = "http://10.57.28.140:8084/Geoportal/Geoportal?operacion=obtenerXMLAplicacionleocansonref=" + host + aplicacion;
	//**/
}else
{
	var debug = getURLParam("debug");
	if(debug == "true")
	{
		config = prompt ("Codigo?","");
	}
}


function getURLParam( name )
{  
	name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");  
	var regexS = "[\\?&]"+name+"=([^&#]*)";  
	var regex = new RegExp( regexS );  
	var results = regex.exec( window.location.href );  
	if( results == null )    
		return "";  
	else    
		return results[1];
}

function reportHostname(){
    return window.location.hostname.toString(); 
}
function reportProtocol(){
    return window.location.protocol.toString(); 
}
function reportPathname(){
    return window.location.pathname.toString(); 
}

