package gov.dane.util
{
	
	import com.esri.ags.Graphic;
	import com.esri.ags.SpatialReference;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.geometry.Polygon;
	import com.esri.ags.geometry.Polyline;
	import com.esri.ags.layers.GraphicsLayer;
	import com.esri.ags.utils.GeometryUtil;
	
	import mx.collections.ArrayCollection;

	public class GeometryUtil
	{
		public function GeometryUtil()
		{
		}
		
		public static function extendGrupo(graficos:ArrayCollection):Extent
		{
			try
			{
				if(!graficos)return null;
				
				var xmin:Number = 0;
				var ymin:Number = 0;
				var xmax:Number = 0;
				var ymax:Number = 0;
				
				if(graficos[0].geometry.extent != null)
				{
					xmin = graficos[0].geometry.extent.xmin;
					ymin = graficos[0].geometry.extent.ymin;
					xmax = graficos[0].geometry.extent.xmax;
					ymax = graficos[0].geometry.extent.ymax;
				}
				else if(graficos[0].geometry is MapPoint)
				{
					xmin = (graficos[0].geometry as MapPoint).x;
					ymin = (graficos[0].geometry as MapPoint).y;
					xmax = (graficos[0].geometry as MapPoint).x;
					ymax = (graficos[0].geometry as MapPoint).y;
				}
				
				for each(var grafico:Graphic in graficos)
				{
					if(grafico.geometry.extent != null)
					{
						if(xmin > grafico.geometry.extent.xmin)
							xmin = grafico.geometry.extent.xmin;
						if(ymin > grafico.geometry.extent.ymin)
							ymin = grafico.geometry.extent.ymin;
						if(xmax < grafico.geometry.extent.xmax)
							xmax = grafico.geometry.extent.xmax;
						if(ymax < grafico.geometry.extent.ymax)
							ymax = grafico.geometry.extent.ymax;
					}
					else if(grafico.geometry is MapPoint)
					{
						if(xmin > (grafico.geometry as MapPoint).x)
							xmin = (grafico.geometry as MapPoint).x;
						if(ymin > (grafico.geometry as MapPoint).y)
							ymin = (grafico.geometry as MapPoint).y;
						if(xmax < (grafico.geometry as MapPoint).x)
							xmax = (grafico.geometry as MapPoint).x;
						if(ymax < (grafico.geometry as MapPoint).y)
							ymax = (grafico.geometry as MapPoint).y;
					}
				}
				
				if(xmin != xmax && ymin != ymax)
				{
					var extent:Extent = new Extent(xmin,ymin,xmax,ymax,(graficos[0].geometry as Geometry).spatialReference);
					return extent;
				}
				else
				{
					return null;
				}
			}
			catch(e:Error)
			{
				return null;
			}
			return null;
		}
		
		public static function WKTToAgsGeometry(graphics:Array,orgWKID:Number):Array{
			
			var resultados:Array = [];
			var x:Number;
			var y:Number;
			var point:MapPoint;
			for each (var wkt:String in graphics)
			{
				if(wkt.indexOf("POINT") == 0)
				{
					x = Number(wkt.substring(wkt.indexOf("(") + 1, wkt.indexOf(" ")));
					y = Number(wkt.substring(wkt.indexOf(" ") + 1, wkt.indexOf(")")));
					point = new MapPoint(x,y,new SpatialReference(orgWKID));
					resultados.push(point);
				}
			}
			
			return resultados;
		}
		
		
		public static function agsGeometryToWKT(graphicsLayer:GraphicsLayer):Array{
			
			var graphics:ArrayCollection = graphicsLayer.graphicProvider as ArrayCollection;
			var wktGraphicsLayer:Array = new Array();
			
			for each (var item:Graphic in graphics)
			{
				switch(item.geometry.type)
				{
					case Geometry.MAPPOINT:
					{
						var p:String = agsMapPointToWKT(item.geometry as MapPoint);
						wktGraphicsLayer.push(agsMapPointToWKT(item.geometry as MapPoint));
						break;
					}
					case Geometry.POLYLINE:
					{
						wktGraphicsLayer.push(agsPolylineToWKT(item.geometry as Polyline));	
						break;
					}
					case Geometry.POLYGON:
					{
						wktGraphicsLayer.push(agsPolygonToWKT(item.geometry as Polygon));
						break;
					}
				}
				
			}
			
			return wktGraphicsLayer;
		}
		
		
		private static function agsMapPointToWKT(mapPoint:MapPoint):String
		{	
			var wkt:String = "POINT("+mapPoint.x+" "+mapPoint.y+")";
			return wkt;
		}
		
		private static function agsPolylineToWKT(polyline:Polyline):String
		{
			var wkt:String = "LINESTRING(";
			var concat:String = "";
			
			if(polyline.paths.length == 1){
				
				var path:ArrayCollection = polyline.paths[0];
				
				for each(var point:MapPoint in path){
					wkt += point.x +" "+ point.y +",";
				}
				
				wkt += ")";
				
			}else if(polyline.paths.length > 1){
				
				
				wkt = "MultiLineString";
				
				for each(var itemPath:Array in polyline.paths)
				{
					wkt += concat+"(";
					for each(var _point:MapPoint in itemPath)
					{
						wkt += _point.x +" "+ _point.y +",";
					}	
					wkt += ")";
					concat = ",";
				}
				
				wkt += ")";
				
			}else{
				wkt = "";
			}
			
			return wkt;
		}
		
		private static function agsPolygonToWKT(polygon:Polygon):String
		{
			
			var wkt:String = "POLYGON(";
			var concat:String = "";
			
			if(polygon.rings.length == 1){
				
				var ring:ArrayCollection = polygon.rings[0];
				
				for each(var point:MapPoint in ring){
					wkt += point.x +" "+ point.y +",";
				}
				
				wkt += ")";
				
			}else if(polygon.rings.length > 1){
				
				wkt = "MultiPolygon";
				
				for each(var itemRing:Array in polygon.rings)
				{
					wkt += concat+"(";
					for each(var _point:MapPoint in itemRing)
					{
						wkt += _point.x +" "+ _point.y +",";
					}	
					wkt += ")";
					concat = ",";
				}
				
				wkt += ")";
				
			}else{
				wkt = "";
			}
			
			return wkt;
			
		}
	}
}