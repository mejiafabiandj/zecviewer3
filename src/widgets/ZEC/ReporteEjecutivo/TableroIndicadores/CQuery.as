package widgets.DANE.ReporteEjecutivo.TableroIndicadores
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.SpatialReference;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esri.ags.utils.JSON;
	import com.esri.ags.utils.JSONUtil;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.messaging.channels.StreamingAMFChannel;
	import mx.rpc.AsyncResponder;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;

	public class CQuery
	{
		public static const MAX_ROW_PER_REQUEST:Number = 1000;
		private var returnGeometry:Boolean = true;
		/** 
		 * Arreglo de ids a obtener
		 **/
		private var _Ids:ArrayCollection = new ArrayCollection();
		public function get Ids():ArrayCollection{ return _Ids; }
		public function set Ids(value:ArrayCollection):void{ _Ids = value; }
		
		private var _config:Object = new ArrayCollection();
		public function get config():Object{ return _config; }
		public function set config(value:Object):void{ _config = value; }
		
		private var _data:Provider = null;
		
		public var callback:Function;
		private var merge:Boolean;

		public function CQuery(config:Object, callback:Function, returnGeometry:Boolean = true, data:Provider = null, merge:Boolean = false){
			this.config = config;
			this.returnGeometry = returnGeometry;
			this.callback = callback;
			if(data!=null){
				this._data=data;
			}
			this.merge = merge;
			getListIds();
		}
		
		private function validateConfig():Boolean{
			if(this.config.hasOwnProperty("where")){
				if((this.config.where as String).length<=0){
					this.config.where="1=1";
				}
			}else{
				this.config.where="1=1";
			}
			if(this.config.hasOwnProperty("outFields")){
				if(this.config.outFields.length<=0){
					this.config.fields = ["*"];
				}else{
					var campos:Array = [];
					for each(var o:Object in this.config.outFields){
						if(o is String){
							campos.push(o);
						}					
					}
					this.config.fields = campos;
				}
			}else{
				this.config.fields = ["*"];
			}
			if(this.config.graphic!=null){
				if((this.config.spatialRelationship as String).length<=0){
					this.config.spatialRelationship = Query.SPATIAL_REL_INTERSECTS;
				}
			}
			if(!this.config.hasOwnProperty("outSpatialReference")){
				this.config.outSpatialReference = null;
			}
			if(!this.config.hasOwnProperty("llave")){
				this.config.llave = "";
			}
			if(!this.config.hasOwnProperty("url")){
				return false;
			}
			if(!this.config.hasOwnProperty("key")){
				return false;
			}
			return true;
		}
		
		private function getListIds():void{
			if(this.validateConfig()){
				
				var servicio:HTTPService = new HTTPService();
				servicio.resultFormat = "text";
				servicio.url = this.config.url + "/query?where=" + this.config.where + "&token=" + this.config.key + "&f=json&returnIdsOnly=true";
				servicio.addEventListener(ResultEvent.RESULT, function(result:ResultEvent):void{
					var ob:Object = JSONUtil.decode(result.result.toString());
					if(ob && ob.objectIds)
					{
						SuccessIds(ob.objectIds);
					}else
					{
						Alert.show("No hay resultados para mostrar.","Error");
					}
				});
				servicio.addEventListener(FaultEvent.FAULT, function(fault:FaultEvent):void{
					Alert.show("Ocurrio un error al realizar la consulta.\n" + fault.message,"Error");
				});
				
				servicio.send();
				
				/*
				var q:Query = new Query();
				var qt:QueryTask = new QueryTask();
				var token:Object = {};
				q.where = this.config.where;
				qt.url = this.config.url;
				qt.token = this.config.key;
				qt.showBusyCursor = true;
				qt.useAMF = true; //Si se trata de ArcGIS Server inferior a 10, esta propiedad debe estar desactivada
				qt.executeForIds(q, new AsyncResponder(SuccessIds , function (info:Object, token:Object = null):void{
					
				}));*/
			}else{
				Alert.show("Error CQuery, configuración incompleta.", "Error");
			}
		}
		
		private function SuccessIds(lista:Object, token:Object = null):void{
			var i:Number=0;
			for(i=0; i<(lista as Array).length; i+=CQuery.MAX_ROW_PER_REQUEST){
				this.Ids.addItem((lista as Array).slice(i, i+CQuery.MAX_ROW_PER_REQUEST));
			}
			this.runQuery();
		}
		
		/**
		 * Función que ejecuta la siguiente consulta en pila
		 */ 
		public function runQuery():void{
			var oids:Array = this.Ids.source.pop();
			if(oids!=null){
				var token:Object = { };
				var query:Query = new Query();
				var queryTask:QueryTask = new QueryTask();
				if(this.config.graphic!=null){
					query.geometry = (this.config.graphic as Graphic).geometry;
					query.spatialRelationship = this.config.spatialRelationship;
				}
				query.outSpatialReference = this.config.outSpatialReference as SpatialReference;
				query.outFields = this.config.fields;
				query.returnGeometry = this.returnGeometry;
				query.where = this.config.where;
				query.objectIds = oids;
				queryTask.url = this.config.url;
				queryTask.token = this.config.key;
				queryTask.showBusyCursor = true;
				queryTask.useAMF = true; //Si se trata de ArcGIS Server inferior a 10, esta propiedad debe estar desactivada
				queryTask.execute(query, new AsyncResponder( querySuccess, function (info:Object, token:Object = null):void{
					Alert.show("Ocurrio un error al realizar la consulta."+info.toString(),"Error");
				}, token));
			}else{
				this.callback(this._data);
			}
		}
		
		/**
		 * Función que es llamada al finalizar la consulta en proceso
		 **/
		private function querySuccess(fs:FeatureSet, token:Object = null):void{
			if(this._data == null){
				this._data = new Provider(fs);
			}else{
				if(this.merge){
					this._data.mergeGraphic(fs,this.config.llave);
				}else{
					this._data.append(fs);
				}
			}
			this.runQuery();
		}
		
	}
}