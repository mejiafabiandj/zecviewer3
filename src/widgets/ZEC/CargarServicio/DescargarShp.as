package widgets.DANE.CargarServicio
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
	import com.esri.ags.layers.ArcGISTiledMapServiceLayer;
	import com.esri.ags.layers.FeatureLayer;
	import com.esri.ags.layers.Layer;
	import com.as3shplib.ShpWriter;
	
	import flash.net.FileReference;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;

	public class DescargarShp
	{
		public function DescargarShp()
		{
		}
		
		public static function descargar(layer:Layer):void
		{
			if(layer is ArcGISDynamicMapServiceLayer)
			{
				
			}else if(layer is ArcGISTiledMapServiceLayer)
			{
				
			}else if(layer is FeatureLayer)
			{
				
				if((layer as FeatureLayer).graphicProvider.length <= 0)
				{
					Alert.show("La capa seleccionada no contiene elementos para ser guardados, por favor verifique el modo de carga de la capa")
					return;
				}
				var featureSet:FeatureSet = new FeatureSet(((layer as FeatureLayer).graphicProvider as ArrayCollection).toArray());
				featureSet.displayFieldName = (layer as FeatureLayer).layerDetails.displayField;
				featureSet.fields = (layer as FeatureLayer).layerDetails.fields;
				featureSet.geometryType = (layer as FeatureLayer).layerDetails.geometryType;
				featureSet.objectIdFieldName = (layer as FeatureLayer).layerDetails.objectIdField;
				featureSet.spatialReference = (layer as FeatureLayer).layerDetails.spatialReference;
				
				var shpWriter:ShpWriter = new ShpWriter(estandarizar(layer.name), featureSet.geometryType, featureSet.spatialReference.wkid, featureSet.fields);
				shpWriter.write(featureSet.features);
				
				
				if (shpWriter != null) {
					Alert.show("El archivo de ha creado exitosamente, por favor seleccione una ubicación para guardarlo","Guardar Shp",Alert.YES,null,
						function(e:CloseEvent):void
						{
							if(e.detail == Alert.YES)
							{
								var fr:FileReference = new FileReference();
								fr.save(shpWriter.getData(), estandarizar(layer.name) + ".zip");
							}
						}
					);
				}
			}
		}
		
		
		//El nombre del SHP no debe contener caracteres invalidos
		private static function estandarizar(cadenaOriginal:String):String
		{
			if(!cadenaOriginal)
				return "";
			var cadena:String = cadenaOriginal.toUpperCase();
			
			var caracteresEspeciales:ArrayCollection = new ArrayCollection(["Á","É","Í","Ó","Ú","Ä","Ë","Ï","Ö","Ü","À","È","Ì","Ò","Ù","Â","Ê","Î","Ô","Û","Ñ"]);
			var caracteresReemplazos:ArrayCollection = new ArrayCollection(["A","E","I","O","U","A","E","I","O","U","A","E","I","O","U","A","E","I","O","U","N"]);
			
			for(var j:Number = 0 ; j < cadena.length ; j ++)
			{
				if(caracteresEspeciales.contains(cadena.charAt(j)))
				{
					cadena = cadena.replace(cadena.charAt(j) , caracteresReemplazos.getItemAt( caracteresEspeciales.getItemIndex(cadena.charAt(j))) );
				}
			}
			return cadena;
		}
	}
}