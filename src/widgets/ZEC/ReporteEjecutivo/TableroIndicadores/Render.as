package widgets.DANE.ReporteEjecutivo.TableroIndicadores
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.layers.FeatureLayer;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.renderers.ClassBreaksRenderer;
	import com.esri.ags.renderers.UniqueValueRenderer;
	import com.esri.ags.renderers.supportClasses.ClassBreakInfo;
	import com.esri.ags.renderers.supportClasses.UniqueValueInfo;
	import com.esri.ags.symbols.SimpleFillSymbol;
	import com.esri.ags.symbols.SimpleLineSymbol;
	import com.esri.ags.symbols.SimpleMarkerSymbol;
	import com.esri.ags.utils.GraphicUtil;
	import com.esri.ags.utils.JSON;
	
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.HSBColor;
	import mx.utils.ObjectProxy;
	
	public class Render
	{
		/** 
		 * Arreglo de resultados de consultas geográficas 
		 **/
		private var _features:Array=new Array();
		private function get features():Array{ return _features; }
		private function set features(value:Array):void{ _features = value; }
		
		/**
		 * Objeto IData
		 **/ 
		/*private var _data:IData = new CArcGISData();
		public function get data():IData{ return _data; }
		public function set data(value:IData):void{ _data = value; }*/
		
		public static const TIPO_VARIABLE_DISCRETO:String = "D";
		public static const TIPO_VARIABLE_CONTINUO:String = "C";
		public static const TIPO_VARIABLE_DISCRETO_NUMERICO:String = "DN";
		public static const METODO_CLASIFICACION_INTERVALOS_IGUALES:String = "II";
		public static const METODO_CLASIFICACION_QUANTILES:String = "Q";
		public static const METODO_CLASIFICACION_PUNTOS_NATURALES:String = "PNQ";
		
		/**
		 * Función que grafíca los resultados de la consulta geográfica
		 * params = {
		 * 	fs: FeatureSet,
		 *  token: Object,
		 * 	map: Map,
		 *  idLayer: String,
		 *  onClick: Function
		 * }
		 **/ 
		public function render(provider:Provider, inGraphicsLayer:GraphicsLayer, config:Object, configAlfanumerico:Object):Extent{
			var graphi:Graphic;
			var data:ArrayCollection = provider.toGraphicsArray();
			if(data.length>0){
				var generarSimbologia:Boolean=true;
				if(config.hasOwnProperty("tomarSimbologiaServicio")){
					if(config.tomarSimbologiaServicio){
						generarSimbologia = false;
					}
					/*
					TODO: pendiente por visualizar con la simbología del servicio
					else
					{
						var servicio:HTTPService = new HTTPService();
						servicio.resultFormat = "text";
						servicio.url = configAlfanumerico.url + "?f=json&token=" + configAlfanumerico.key;
						servicio.addEventListener(ResultEvent.RESULT,function(result:ResultEvent):void{
							
							var res:Object = JSON.decode(result.result.toString());
							res;
						});
						servicio.addEventListener(FaultEvent.FAULT,function(fault:*):void{
							fault;
						});
						
						servicio.send();
					}*/
				}
				
				if(generarSimbologia){
					var rangos:ArrayCollection = this.clasificarInfo(provider, config.metodo, config.clases, config.field, config.tipoVariable);
					escalaColores(config.color, rangos);
					if(config.tipoVariable == TIPO_VARIABLE_CONTINUO){
						inGraphicsLayer.renderer = this.generarClassBreaks(config.field, rangos);
					}else if(config.tipoVariable == TIPO_VARIABLE_DISCRETO){
						inGraphicsLayer.renderer = this.generarUniqueValueRenderer(config.field, rangos);
					}else if(config.tipoVariable == TIPO_VARIABLE_DISCRETO_NUMERICO){
						inGraphicsLayer.renderer = this.generarUniqueValueRenderer(config.field, rangos);
					}
				}
				this.features = new Array();
				inGraphicsLayer.clear();
				for each (var reg:Object in data){
					//reg.graphic.addEventListener(MouseEvent.CLICK,  params.onClick);
					//geo.infoWindowRenderer
					inGraphicsLayer.add(reg as Graphic);
					this.features.push(reg as Graphic);
				}
				var graphicsExtent:Extent = GraphicUtil.getGraphicsExtent(this.features);
				if (graphicsExtent)
				{
					return graphicsExtent;
				}
			}else{
				//Alert.show("Mapa: No hay resultados.");
			}
			return null;
		}
		
		private function generarUniqueValueRenderer(field:String, rangos:ArrayCollection):UniqueValueRenderer{
			var r:UniqueValueRenderer=new UniqueValueRenderer();
			r.field = field;
			var lista:Array = [];
			for each(var rango:Object in rangos){
				var item:UniqueValueInfo = new UniqueValueInfo(null, rango.valor);
				switch(rango.tipo){
					case Geometry.MAPPOINT:
						/**TODO*/
						item.symbol = new SimpleMarkerSymbol("circle", 5, rango.color);
						break;
					case Geometry.POLYLINE:
						item.symbol = new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, rango.color, 1, 3);
						break;
					case Geometry.POLYGON:
						item.symbol = new SimpleFillSymbol(
							SimpleFillSymbol.STYLE_SOLID,
							rango.color,
							0.5,new SimpleLineSymbol(
								SimpleLineSymbol.STYLE_SOLID,
								rango.color,
								1,
								1
							)
						);
						break;
				}
				lista.push(item);
			}
			r.infos = lista;
			return r;
		}
		
		private function generarClassBreaks(field:String, rangos:ArrayCollection):ClassBreaksRenderer{
			var r:ClassBreaksRenderer=new ClassBreaksRenderer();
			r.field = field;
			var lista:Array = [];
			for each(var rango:Object in rangos){
				var item:ClassBreakInfo = new ClassBreakInfo();
				item.label=rango.valor;
				item.maxValue=rango.max;
				item.minValue=rango.min;
				switch(rango.tipo){
					case Geometry.MAPPOINT:
						/**TODO*/
						break;
					case Geometry.POLYLINE:
						item.symbol = new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, rango.color, 1, 3);
						break;
					case Geometry.POLYGON:
						item.symbol = new SimpleFillSymbol(
							SimpleFillSymbol.STYLE_SOLID,
							rango.color,
							0.5,new SimpleLineSymbol(
								SimpleLineSymbol.STYLE_SOLID,
								rango.color,
								1,
								1
							)
						);
						break;
				}
				lista.push(item);
			}
			r.infos = lista;
			return r;
		}
		
		private function escalaColores(base:uint, rangos:ArrayCollection):void{
			var hue:Number = HSBColor.convertRGBtoHSB(base).hue;
			var intervalos:Number = rangos.length;
			var i:Number;
			for (i = 0 ; i < intervalos ; i++){
				var hsbColor:HSBColor = new HSBColor(hue, (i+1) * (1) / (intervalos) , 1);
				var color:uint = HSBColor.convertHSBtoRGB(hsbColor.hue,hsbColor.saturation,hsbColor.brightness);
				var elemento:Object = rangos.getItemAt(i) as Object;
				elemento.color = color;
			}
		}
		
		private function clasificarInfo(data:Provider, metodo:String, clases:Number, field:String, tipo:String):ArrayCollection{
			var providerClases:ArrayCollection = new ArrayCollection();
			var i:Number;
			var intervalo:ObjectProxy;
			var valoresUnicos:ArrayCollection = data.distinc(field,"",data.toGraphicsArray()) as ArrayCollection;
			if(tipo == TIPO_VARIABLE_CONTINUO){
				valoresUnicos = new ArrayCollection(valoresUnicos.toArray().sortOn("data", Array.NUMERIC));
				switch(metodo)
				{
					case METODO_CLASIFICACION_INTERVALOS_IGUALES:
					{
						var min:Number = valoresUnicos[0].data;
						var max:Number = valoresUnicos[valoresUnicos.length-1].data;
						var tipo:String = valoresUnicos[0].tipo;
						var a:Number = max - min;
						var b:Number = a/clases;
						var tamanoIntervalo:Number =(max - min) / clases;
						
						if(tamanoIntervalo == 0)
						{
							providerClases.addItem({
								tipo: tipo,
								valor: max
							});
							break;
						}
						
						max = min + tamanoIntervalo;
						
						
						for (i = 0; i < clases; i++)
						{
							intervalo = new ObjectProxy();
							
							intervalo.min = min;
							intervalo.max = max;
							intervalo.tipo = tipo;
							
							min += tamanoIntervalo;
							max = (i != clases-2) ? max + tamanoIntervalo : valoresUnicos[valoresUnicos.length-1].data;
							
							intervalo.valor = intervalo.min + " - " + intervalo.max;
							providerClases.addItem(intervalo);
							
						}
						
					}break;
					case METODO_CLASIFICACION_QUANTILES:
					{
						var elementosPorClase:Number = Math.floor(valoresUnicos.length / clases);
						for (i = 0 ; i < clases ; i++)
						{
							intervalo = new ObjectProxy();
							
							intervalo.min = valoresUnicos[elementosPorClase*i].data;
							intervalo.max = (i != clases-1) ? valoresUnicos[elementosPorClase*(i+1)].data : valoresUnicos[valoresUnicos.length-1].data;
							intervalo.tipo = valoresUnicos[elementosPorClase*i].tipo;
							
							intervalo.valor = intervalo.min + " - " + intervalo.max;
							providerClases.addItem(intervalo);
						}
					}break;
					case METODO_CLASIFICACION_PUNTOS_NATURALES:
					{
						var unicos:ArrayCollection = new ArrayCollection();
						for each(var val:ObjectProxy in valoresUnicos){
							unicos.addItem(val.data);
						}
						var indices:ArrayCollection = getJenksBreaks(unicos,clases);
						for (i = 0; i < clases; i++){
							intervalo = new ObjectProxy();
							
							intervalo.min = (i == 0) ? valoresUnicos[0].data : valoresUnicos[indices[i-1]].data;
							intervalo.max = valoresUnicos[indices[i]].data;
							intervalo.tipo = valoresUnicos[0].tipo;
							
							intervalo.valor = intervalo.min + " - " + intervalo.max;
							providerClases.addItem(intervalo);
						}
					}break;
				}
			}else if(tipo == TIPO_VARIABLE_DISCRETO_NUMERICO){
				valoresUnicos = new ArrayCollection(valoresUnicos.toArray().sortOn("data",Array.NUMERIC));
				for each(var o:Object in  valoresUnicos){
					providerClases.addItem({
						tipo: o.tipo,
						valor: o.data
					});
				}
			}else{
				valoresUnicos = new ArrayCollection(valoresUnicos.toArray().sortOn("data"));
				for each(var o2:Object in  valoresUnicos){
					providerClases.addItem({
						tipo: o2.tipo,
						valor: o2.data
					});
				}
			}
			return providerClases;
		}
		
		private function getJenksBreaks(list:ArrayCollection, numclass:Number):ArrayCollection {
			if(numclass == 0)
				return null; 
			if(numclass == 1)
			{
				return new ArrayCollection([list.length-1]);
			}
			
			var numdata:Number = list.length;
			var mat1:ArrayCollection = new ArrayCollection(new Array(numdata + 1));
			var mat2:ArrayCollection = new ArrayCollection(new Array(numdata + 1));
			var st:ArrayCollection = new ArrayCollection(new Array(numdata));
			var j:Number;
			
			for(j = 1; j <= numdata ; j++)
			{
				mat1[j] = new ArrayCollection(new Array(numclass+ 1));
				mat2[j] = new ArrayCollection(new Array(numclass+ 1));
			}
			
			for (var i:Number = 1; i <= numclass; i++) {
				mat1[1][i] = 1;
				mat2[1][i] = 0;
				for (j = 2; j <= numdata; j++)
					mat2[j][i] = Number.MAX_VALUE;
			}
			
			var v:Number = 0;
			
			for (var l:Number = 2; l <= numdata; l++) {
				var s1:Number = 0;
				var s2:Number = 0;
				var w:Number = 0;
				for (var m:Number = 1; m <= l; m++) {
					var i3:Number = l - m + 1;
					
					var val:Number = list[i3-1];
					
					s2 += val * val;
					s1 += val;
					w++;
					v = s2 - (s1 * s1) / w;
					var i4:Number = i3 - 1;
					if (i4 != 0) {
						for (j = 2; j <= numclass; j++) {
							if (mat2[l][j] >= (v + mat2[i4][j- 1])) {
								mat1[l][j] = i3;
								mat2[l][j] = v + mat2[i4][j -1];
							}
						}
					}
				}
				mat1[l][1] = 1;
				mat2[l][1] = v;
			}
			var k:Number = numdata;
			var kclass:ArrayCollection = new ArrayCollection(new Array(numclass));
			kclass[numclass - 1] = list.length - 1;
			
			for (j = numclass; j >= 2; j--) {
				
				var id:Number =  mat1[k][j] - 2;
				kclass[j - 2] = id;
				k = mat1[k][j] - 1;
				
			}
			return kclass;
		}
	}
}