package widgets.DANE.ReporteEjecutivo.TableroIndicadores
{
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectProxy;

	public class CCofiguracion
	{
		private var config:Array = null;
		
		public function CCofiguracion(config:Object)
		{
			if(getQualifiedClassName(config) == getQualifiedClassName(Array)){
				this.config = config as Array;
			}else{
				if(getQualifiedClassName(config) == getQualifiedClassName(Object)){
					this.config = [config];
				}else{
					if(getQualifiedClassName(config) == getQualifiedClassName(ObjectProxy)){
						this.config = [config];
					}
				}
			}
		}
		
		public function getConfigReport(nombre:String = ""):Object{
			if(this.config!=null){
				for each(var report:Object in this.config){
					if(nombre!=""){
						if(report.hasOwnProperty("nombre")){
							if(report.nombre==nombre){
								return report;
							}
						}
					}else{
						if(report.hasOwnProperty("porDefecto")){
							if(report.porDefecto){
								return report;
							}
						}
					}
				}
				if(this.config.length>0){
					return this.config[0];
				}else{
					return {};
				}
			}else{
				return {};
			}
		}
		
		public function getListReports():Object{
			var r:ArrayCollection = new ArrayCollection();
			var i:Number = 0;
			var index:Number = 0;
			for each(var report:Object in this.config){
				if(report.hasOwnProperty("nombre")){
					r.addItem(report.nombre);
					if(report.hasOwnProperty("porDefecto")){
						if(report.porDefecto){
							index = i;
						}
					}
					i++;
				}
			}
			return {index: index, lista: r};
		}
	}
}