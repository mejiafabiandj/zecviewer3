package widgets.DANE.ValidacionGeorreferenciacion
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.events.QueryEvent;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.layers.Layer;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequestMethod;
	
	import gov.dane.util.TokenUtil;
	
	import mx.collections.ArrayCollection;
	import mx.managers.CursorManager;
	import mx.rpc.AsyncResponder;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	
	[Event(name="executeComplete", type="com.esri.ags.events.QueryEvent")]

	[Event(name="fault", type="mx.rpc.events.FaultEvent")]
	
	public class Validador extends EventDispatcher
	{
		
		/**
		 * Nombre del atributo donde se almacena el valor de la georreferenciación
		 **/
		public static const ATTRIBUTO_GEORREFERENCIACION_VALIDA:String = "GEORREFERENCIACION_VALIDA";
		
		/**
		 * Valor que se asigna cuando la georreferenciacion del elemento es correcta
		 **/
		public static const VALOR_GEORREFERENCIACION_VALIDA:String = "SI";
		
		/**
		 * Valor que se asigna cuando la georreferenciacion del elemento NO es correcta
		 **/
		public static const VALOR_GEORREFERENCIACION_NO_VALIDA:String = "NO";
		
		
		
		/**
		 * Nombre del atributo donde se almacena el valor de la georreferenciación
		 **/
		public static const ATTRIBUTO_TITULO_GEORREFERENCIACION:String = "Resultado Georreferenciación";
		
		/**
		 * Valor que se asigna cuando la georreferenciacion del elemento es correcta
		 **/
		public static const TITULO_GEORREFERENCIACION_VALIDA:String = "<font color='#00BB33'><b>Georreferenciación Válida</b></font>";
		
		/**
		 * Valor que se asigna cuando la georreferenciacion del elemento NO es correcta
		 **/
		public static const TITULO_GEORREFERENCIACION_NO_VALIDA:String = "<font color='#BC1C14'><b>Georreferenciación Inválida</b></font>";
		
		
		
		public var proxyUrl:String;
		
		private var query:Query = new Query();
		private var queryTask:QueryTask = new QueryTask();
		
		private var resultsGraphicsProvider:Array  = [];
		
		public function Validador()
		{
			queryTask.showBusyCursor = true;
			queryTask.method = URLRequestMethod.POST;
			
			query.spatialRelationship = Query.SPATIAL_REL_WITHIN;
		}
		
		public function validar(capaAValidar:Layer, atributoAValidar:Object, vigencia:Object, capaMarco:Object, atributoMarco:Object):void
		{
			CursorManager.setBusyCursor();
			
			if(capaAValidar.className == "GraphicsLayer" || capaAValidar.className == "FeatureLayer")
			{
				resultsGraphicsProvider = [];
				
				queryTask.token = TokenUtil.buscarToken(vigencia.url);
				queryTask.proxyURL = vigencia.useproxy ? proxyUrl: null;
				queryTask.useAMF = vigencia.useAMF;
				queryTask.url = vigencia.url + "/" + capaMarco.id;
				
				for each(var feature:Graphic in (capaAValidar as GraphicsLayer).graphicProvider)
				{
					query.geometry = feature.geometry;
					query.returnGeometry = false;
					query.outFields = [atributoMarco.name];
					query.where = atributoMarco.name + " = " + feature.attributes[atributoAValidar.name];
					
					queryTask.execute(query, new AsyncResponder(query_executeCompleteHandler,query_faultHandler,{feature:feature, layer:capaAValidar}));
				}
			}
		}
		
		private function query_executeCompleteHandler(featureSet:FeatureSet, token:Object = null):void
		{
			var gra:Graphic;
			var attributes:Object = token.feature.attributes;
			if(featureSet.features.length > 0)
			{
				attributes[ATTRIBUTO_GEORREFERENCIACION_VALIDA] = VALOR_GEORREFERENCIACION_VALIDA;
				attributes[ATTRIBUTO_TITULO_GEORREFERENCIACION] = TITULO_GEORREFERENCIACION_VALIDA;
			}else
			{
				attributes[ATTRIBUTO_GEORREFERENCIACION_VALIDA] = VALOR_GEORREFERENCIACION_NO_VALIDA;
				attributes[ATTRIBUTO_TITULO_GEORREFERENCIACION] = TITULO_GEORREFERENCIACION_NO_VALIDA;
			}
			
			gra = new Graphic(token.feature.geometry,null,attributes);
			
			resultsGraphicsProvider.push(gra);
			
			if(resultsGraphicsProvider.length == token.layer.graphicProvider.length)
			{
				CursorManager.removeBusyCursor();
				dispatchEvent(new QueryEvent("executeComplete",resultsGraphicsProvider.length, new FeatureSet(resultsGraphicsProvider)));
			}
		}
		
		private function query_faultHandler(event:Fault, token:Object = null):void
		{
			var gra:Graphic;
			var attributes:Object = token.feature.attributes;
			attributes[ATTRIBUTO_GEORREFERENCIACION_VALIDA] = VALOR_GEORREFERENCIACION_NO_VALIDA;
			attributes[ATTRIBUTO_TITULO_GEORREFERENCIACION] = TITULO_GEORREFERENCIACION_NO_VALIDA;
			
			gra = new Graphic(token.feature.geometry,null,attributes);
			
			resultsGraphicsProvider.push(gra);
			
			if(resultsGraphicsProvider.length == token.layer.graphicProvider.length)
			{
				dispatchEvent(new QueryEvent("executeComplete",resultsGraphicsProvider.length, new FeatureSet(resultsGraphicsProvider)));
				dispatchEvent(new FaultEvent("fault",false,false,event));
			}
		}
	}
}