package gov.dane.util
{
	public class Constantes
	{
		public function Constantes()
		{
		}
		
		/**
		 * llave que se utiliza en el evento <code>DATA_PUBLISH</code> del objeto <code>ViewerContainer</code> para abrir un widget y enviar información.
		 * <p>el nombre del widget que se va a abrir y la información opcional, se envian como el elemento 0 de un objeto tipo <code>ArrayCollection</code>
		 * <p>
		 * Ej:<p><b/>
		 * <code>addSharedData( Constantes.OPERACION_ABRIR_WIDGET , new ArrayCollection( [ {label:"Resultados" , data:data ] ) );</code>
		 **/
		public static var OPERACION_ABRIR_WIDGET:String = "abrir widget";
		
		/**
		 * llave que se utiliza en el evento <code>DATA_PUBLISH</code> del objeto <code>ViewerContainer</code>
		 * para informar que un widget ya ha sido abierto luego de un llamado a <H6><code>addSharedData( Constantes.OPERACION_ABRIR_WIDGET , new ArrayCollection( [ {label:"Resultados" , data:data ] ) );</code></H6> 
		 * <p>
		 * el nombre del widget que se abrió, se envia como el elemento 0 de un objeto tipo <code>ArrayCollection</code>
		 * <p>
		 * Ej:<p><b/>
		 * <code>addSharedData( Constantes.WIDGET_ABIERTO , new ArrayCollection( [ "Resultados" ] ) );</code>
		 **/ 
		public static var WIDGET_ABIERTO:String = "widget abierto";
		
		/**
		 * Evento disparado sobre el objeto <code>ViewerContainer</code>
		 * para informar que se va a realizar una consulta a la información raster a partir de una geometría dada
		 * la geometría a consultar que se envia como el <code>data</code> del evento <code>AppEvent</code>
		 * <p>
		 * Ej:<p><b/>
		 * <code>ViewerContainer.dispatchEvent(new AppEvent(Constantes.OPERACION_CONSULTAR_RASTER,graphic));</code>
		 **/
		public static var OPERACION_CONSULTAR_RASTER:String = "consultar raster";
		
		/**
		 * Evento disparado sobre el objeto <code>ViewerContainer</code>
		 * para informar que se va a realizar la configuracion para una consulta a la información raster
		 * el objeto <code>data</code> del evento <code>AppEvent</code> establece si se muestra de forma modal o no
		 * <p>
		 * Ej:<p><b/>
		 * <code>ViewerContainer.dispatchEvent(new AppEvent(Constantes.MOSTRAR_CONFIGURACION_RASTER,true));</code>
		 **/
		public static const MOSTRAR_CONFIGURACION_RASTER:String = "mostrarConfiguracionRaster";
		
		/**
		 * 
		 * <p>
		 * Ej:<p><b/>
		 **/
		public static var OPERACION_INFORMACION:String = "operacion informacion";
		
		/**
		 * Informa del evento para asignar la navegación actual y reflejar los cambios en el widget NavigationWidget
		 **/
		public static var SET_MAP_NAVIGATION:String = "set map navigation";
		
		
		/**
		 * Informa del evento para desplegar las asociaciones de un elemento. disparado desde PupUpRendererSkin
		 **/
		public static var VER_ASOCIACIONES:String = "ver asociaciones";
		
		
		/**
		 * 
		 * <p>
		 * Ej:<p><b/>
		 **/
		public static var OPERACION_LIMPIAR_RESULTADOS_RASTER:String = "operacion limpiar resultados raster";
		
		public static const KEY:String = "4dac0036b0b6fc170679e7f6a94ac925";
		public static const OTHERKEY:String = "e29b6ccaf3288a71729ee54847b1962b";
	}
}