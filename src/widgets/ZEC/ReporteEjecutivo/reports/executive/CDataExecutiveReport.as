package widgets.DANE.ReporteEjecutivo.reports.executive
{
	import widgets.DANE.ReporteEjecutivo.reports.components.DataGridComponent;
	
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.symbols.SimpleFillSymbol;
	import com.esri.ags.symbols.SimpleLineSymbol;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esri.ags.utils.GraphicUtil;
	
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.Repeater;
	import mx.rpc.AsyncResponder;
	
	
	public class CDataExecutiveReport
	{
		/**
		 * Tipo de fuente de datos
		 **/
		public static const DATA_SOURCE_GEOGRAPHIC_SERVICE:String="DSGS";
		public static const DATA_SOURCE_OLAP_SERVICE:String="DSOS";
		public static const DATA_SOURCE_DATA_TABLE:String="DSDT";

		private var _type:String;
		public function get type():String{ return _type; }
		public function set type(value:String):void{ _type = value; }
		
		/**
		 * Arreglo de DataGridColumn
		 * 	var column:DataGridColumn = new DataGridColumn("C1");
			column.headerText = "Columna 1";
			column.headerWordWrap = true;
			column.width = 120;
			columns.push(column);
		*/ 
		private var _columns:Array=new Array();
		public function get columns():Array{ return _columns; }
		public function set columns(value:Array):void{ _columns = value; }

		/**
		 * Arreglo con información
		 */
		private var _provider:ArrayCollection=new ArrayCollection();;
		public function get provider():ArrayCollection{ return _provider; }
		public function set provider(value:ArrayCollection):void{ _provider = value; }
		
		/**
		 * Arreglo con gráficas estadísticas
		 */
		private var _chartsProvider:ArrayCollection=new ArrayCollection();
		public function get chartsProvider():ArrayCollection{ return _chartsProvider; }
		public function set chartsProvider(value:ArrayCollection):void{ _chartsProvider = value; }
		
		/** 
		 * Arreglo de parametros de consultas 
		 **/
		private var _queries:ArrayCollection = new ArrayCollection();
		public function get queries():ArrayCollection{ return _queries; }
		public function set queries(value:ArrayCollection):void{ _queries = value; }
		
		/**
		 * Número total de consultas solicitadas
		 **/ 
		private var _totalQueries:Number=0;
		public function get totalQueries():Number{ return _totalQueries; }
		public function set totalQueries(value:Number):void{ _totalQueries = value; }

		/** 
		 * Arreglo de resultados de consultas geográficas 
		 **/
		private var _features:Array=new Array();
		public function get features():Array{ return _features; }
		public function set features(value:Array):void{ _features = value; }
		
		/** 
		 * Referencia al mapa de componente
		 **/
		private var _map:Map;
		public function get map():Map{ return _map; }
		public function set map(value:Map):void{ _map = value; }
		
		/** 
		 * Referencia al componente rCharts
		 **/
		private var _rCharts:Repeater;
		public function get rCharts():Repeater{ return _rCharts; }
		public function set rCharts(value:Repeater):void{ _rCharts = value; }
		
		/** 
		 * Referencia al componente DataGrid
		 **/
		private var _cDataGrid:DataGridComponent;
		public function get cDataGrid():DataGridComponent{ return _cDataGrid; }
		public function set cDataGrid(value:DataGridComponent):void{ _cDataGrid = value; }


		/**
		 * Constructor
		 */
		public function CDataExecutiveReport()
		{
			
		}
		
		/**
		 * Función que ejecuta la siguiente consulta en pila
		 */ 
		private function runNextQuery():void{
			if(this.queries.length>0 && map!=null){
				var obj:Object=this.queries.source.pop();
				if(obj.outFields==null){
					obj.outFields=["*"];
				}
				var query:Query = new Query();
				var queryTask:QueryTask = new QueryTask();
				var token:Object = { referenceId:obj.referenceId };
				if(obj.graphic!=null){
					token = { graphic:obj.graphic as Graphic };
					if(obj.spatialRelationship!=""){
						query.spatialRelationship=obj.spatialRelationship;
					}else{
						query.spatialRelationship=Query.SPATIAL_REL_INTERSECTS;
					}
					query.geometry = obj.graphic;
				}
				query.outSpatialReference = map.spatialReference;
				query.outFields = obj.outFields;
				query.returnGeometry = true;
				queryTask.url = obj.url;
				queryTask.showBusyCursor = true;
				if((obj.where as String).length<=0)
					obj.where="1";
				query.where = obj.where;
				queryTask.useAMF = true; //Si se trata de ArcGIS Server inferior a 10, esta propiedad debe estar desactivada
				queryTask.execute(query, new AsyncResponder( querySuccess, function (info:Object, token:Object = null):void{
					Alert.show("Ocurrio un error al realizar la consulta."+info.toString(),"Error");
				}, token));
			}
		}
		
		/**
		 * Función que es llamada al finalizar la consulta en proceso
		 **/
		private function querySuccess(fs:FeatureSet, token:Object = null):void{
			renderFeatureSet(fs,token);
			runNextQuery();
		}
		
		/**
		 * Función que grafíca los resultados de la consulta geográfica
		 **/ 
		private function renderFeatureSet(fs:FeatureSet, token:Object = null):void{
			var outlineSym:SimpleLineSymbol;
			var polySym:SimpleFillSymbol;
			var graphi:Graphic;
			var inGraphicsLayer:GraphicsLayer=map.getLayer("ERL") as GraphicsLayer;
			if(fs.features.length>0){
				for each (var geo:Graphic in fs.features)
				{
					outlineSym = new SimpleLineSymbol("solid",0xffad1d, 0.5, 1);
					polySym = new SimpleFillSymbol("solid", 0xffad1d, 0.25, outlineSym);
					geo.symbol = polySym;
					geo.addEventListener(MouseEvent.CLICK,function(event:MouseEvent):void{
						Alert.show(event.currentTarget.attributes[token.referenceId]);
					});
					//geo.infoWindowRenderer
					inGraphicsLayer.add(geo);
					this.features.push(geo);
				}
				var graphicsExtent:Extent = GraphicUtil.getGraphicsExtent(this.features);
				if (graphicsExtent)
				{
					map.extent = graphicsExtent;
				}
			}else{
				Alert.show("Mapa: No hay resultados.");
			}
		}
		
		/**
		 * Agrega consultas a la pila
		 **/
		public function addQuery(inUrl:String,inOutFields:Array=null,inWhere:String="",inGraphic:Graphic=null,inSpatialRelationship:String="",inReferenceId:String=""):void{
			queries.addItem({
				url:inUrl,
				outFields:inOutFields,
				where:inWhere,
				graphic:inGraphic,
				spatialRelationship:inSpatialRelationship,
				referenceId:inReferenceId
			});
		}
		
		/**
		 * Cargar información
		 **/
		public function loadData(inMap:Map=null,inRCharts:Object=null,inCDataGrid:DataGridComponent=null):void{
			if(inMap!=null)
				map=inMap;
			if(inRCharts!=null){
				rCharts=inRCharts as Repeater;
				rCharts.dataProvider=this.chartsProvider;
			}
			if(inCDataGrid!=null){
				cDataGrid=inCDataGrid;
				cDataGrid.columns=this.columns;
				cDataGrid.provider=this.provider;
			}
			if(queries.length>0 && map!=null)
				runNextQuery();
		}
		
		/**
		 * Cargar información de prueba
		 **/
		public function loadDemo(inMap:Map=null,inRCharts:Object=null,inCDataGrid:DataGridComponent=null):void{
			var column:DataGridColumn = new DataGridColumn("C1");
			column.headerText = "Columna 1";
			column.headerWordWrap = true;
			//column.width = 120;
			columns.push(column);
			
			
			column = new DataGridColumn("C2");
			column.headerText = "Columna 2";
			column.headerWordWrap = true;
			//column.width = 120;
			columns.push(column);
			
			for(var i:Number=0;i<10;i++){
				var atributos:Object=new Object();
				atributos["C1"]="dato c1 fila "+i.toString();
				atributos["C2"]="dato c2 fila "+i.toString();
				provider.addItem(atributos);
			}
			
			var obj:Object={
				data:new ArrayCollection( [
					{ label: "Dato 1", value: 35},
					{ label: "Dato 2", value: 32},
					{ label: "Dato 3", value: 27} ]),
				functionLabel:function(data:Object, field:String, index:Number, percentValue:Number):String {
					var temp:String= (" " + percentValue).substr(0,6);
					return data.label + ": " + '\n' + "Total: " + data.value + '\n' + temp + "%";
				},
				labelPosition:"callout",//callout, inside, insideWithCallout, none, outside
				tipo:"bar_legend",//pie, pie_legend, bar, bar_legend
				legendLabel:"Hola",
				titulo:"Ejemplo barras"
			};
			chartsProvider.addItem(obj);
			obj={
				data:new ArrayCollection( [
					{ label: "Dato 1", value: 25},
					{ label: "Dato 2", value: 32},
					{ label: "Dato 3", value: 47} ]),
				functionLabel:function(data:Object, field:String, index:Number, percentValue:Number):String {
					var temp:String= (" " + percentValue).substr(0,6);
					return data.label + ": " + '\n' + "Total: " + data.value + '\n' + temp + "%";
				},
				tipo:"pie_legend",
				labelPosition:"inside",//callout, inside, insideWithCallout, none, outside
				titulo:"Ejemplo Pie"
			};
			chartsProvider.addItem(obj);
			
			addQuery("http://10.57.48.49:8399/arcgis/rest/services/REUNIDOS/DIVIPOLA_2010/MapServer/1",null,"DPTO like '05'",null,"","NOM_MPIO");

			if(inMap!=null)
				map=inMap;
			if(inRCharts!=null){
				rCharts=inRCharts as Repeater;
				rCharts.dataProvider=this.chartsProvider;
			}
			if(inCDataGrid!=null){
				cDataGrid=inCDataGrid;
				cDataGrid.columns=this.columns;
				cDataGrid.provider=this.provider;
			}
			if(queries.length>0 && map!=null)
				runNextQuery();
		}
	}
}