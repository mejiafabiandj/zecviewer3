package widgets.DANE.ReporteEjecutivo.TableroIndicadores
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	
	import r1.deval.D;

	public class Provider
	{
		private var fs_data:FeatureSet;
		private var ac_data:ArrayCollection;
		private var tipo:Number=0;
		private var fieldFilter:String = "";
		private var valueFilter:String = "";
		private var tipoFilterDate:Boolean = false;
		private var banderaFiltrado:Boolean = false;
		
		private var _data:ArrayCollection = new ArrayCollection();
		public function get data():ArrayCollection{	return _data; }
		public function set data(value:ArrayCollection):void{ _data = value; }
		
		private var _filter_data:ArrayCollection = new ArrayCollection();
		public function get filter_data():ArrayCollection{	return _filter_data; }
		public function set filter_data(value:ArrayCollection):void{ _filter_data = value; }
		
		private var _proc_data:ArrayCollection = new ArrayCollection();
		public function get proc_data():ArrayCollection{	return _proc_data; }
		public function set proc_data(value:ArrayCollection):void{ _proc_data = value; }
		
		public function Provider(data:Object)
		{
			if(getQualifiedClassName(data) == getQualifiedClassName(FeatureSet)){
				this.fs_data = data as FeatureSet;
				this.tipo=1;
				this.extract();
			}else{
				if(getQualifiedClassName(data) == getQualifiedClassName(ArrayCollection)){
					this.ac_data = data as ArrayCollection;
					this.tipo=2;
					this.extract();
				}else{
					if(getQualifiedClassName(data) == getQualifiedClassName(Array)){
						this.ac_data = new ArrayCollection(data as Array);
						this.tipo=2;
						this.extract();
					}
				}
			}
		}
		
		public function append(data:Object):void{
			if(getQualifiedClassName(data) == getQualifiedClassName(FeatureSet)){
				var tmp:Object;
				for each (var geo:Graphic in data.features){
					tmp = geo.attributes as Object;
					tmp.graphic = geo;
					this.data.addItem( tmp );
				}
			}else{
				if(getQualifiedClassName(data) == getQualifiedClassName(ArrayCollection)){
					this.data.addAll(data as ArrayCollection);
				}else{
					if(getQualifiedClassName(data) == getQualifiedClassName(Array)){
						this.data.addAll(new ArrayCollection(data as Array));
					}
				}
			}
		}
		
		public function mergeGraphic(fs:FeatureSet, llave:String):void{
			var tmp:Object;
			for each (var geo:Graphic in fs.features){
				for each (var d:Object in this.data){
					if(d.hasOwnProperty(llave) && geo.attributes.hasOwnProperty(llave)){
						if(d[llave]==geo.attributes[llave]){
							d.graphic = geo;
						}
					}
				}
			}
		}
		
		private function replace(s:String, o:Object):String{
			for (var l:String in o) {
				var patron:String="";
				while(patron != s){
					patron = s;
					s = s.replace("["+l+"]", o[l]);
				}
			}
			return s;
		}
		
		private function extract():void{
			switch(this.tipo){
				case 1:{
					var tmp:Object;
					for each (var geo:Graphic in this.fs_data.features){
						tmp = geo.attributes as Object;
						tmp.graphic = geo;
						this.data.addItem( tmp );
					}
					this.data= new ArrayCollection(this.data.source);
					this.fs_data = null;
				}break;
				case 2:{
					this.data = new ArrayCollection(this.ac_data.source);
					this.ac_data = null;
				}break;
			}
		}
		
		public function newsFields(param:Array):void{
			var valor:Object;
			if(param.length>0){
				for each(var o:Object in this.data){
					for each(var f:Object in param){
						valor = D.eval(this.replace(f.valor as String, o));
						o[f.nombre] = valor;
						o.graphic.attributes[f.nombre] = valor;
					}
				}
			}
		}
		
		public function groupBy(fd:String):void{
			if(this.filter_data.length<=0 && !this.banderaFiltrado){
				this.filter_data = new ArrayCollection(this.data.source);
			}
			if(this.proc_data.length<=0){
				this.proc_data=this.filter_data;
			}
			this.proc_data = this._groupBy(this.proc_data,fd);
		}
		
		private function _groupBy(datos:ArrayCollection, fd:String):ArrayCollection{
			var dic : Dictionary = new Dictionary();
			for each(var obj:Object in datos){
				if(obj.hasOwnProperty(fd)){
					if(!dic.hasOwnProperty(obj[fd])){
						dic[obj[fd]]={};
						dic[obj[fd]][fd]=obj[fd];
						dic[obj[fd]]["children"]=[];
						dic[obj[fd]]["total"]=0;
					}
					dic[obj[fd]]["total"]+=1;
					var chd:Object = null;
					for( var prop:String in obj ){
						if(chd==null){
							chd = {};
						}
						if(prop!=fd){
							chd[prop]=obj[prop];
							if(!isNaN(Number(obj[prop]))){// si es numero
								//Se calcula el maximo
								if(dic[obj[fd]].hasOwnProperty("max_"+prop)){
									if(dic[obj[fd]]["max_"+prop]<Number(obj[prop])){
										dic[obj[fd]]["max_"+prop]=Number(obj[prop]);
									}
								}else{
									dic[obj[fd]]["max_"+prop]=Number(obj[prop]);
								}
								//Se calcula el minimo
								if(dic[obj[fd]].hasOwnProperty("min_"+prop)){
									if(dic[obj[fd]]["min_"+prop]>Number(obj[prop])){
										dic[obj[fd]]["min_"+prop]=Number(obj[prop]);
									}
								}else{
									dic[obj[fd]]["min_"+prop]=Number(obj[prop]);
								}
								//Se calcula la sumatoria
								if(dic[obj[fd]].hasOwnProperty("sum_"+prop)){
									dic[obj[fd]]["sum_"+prop]+=Number(obj[prop]);
								}else{
									dic[obj[fd]]["sum_"+prop]=Number(obj[prop]);
								}
								//Se calcula el promedio
								if(dic[obj[fd]].hasOwnProperty("total")&&dic[obj[fd]].hasOwnProperty("sum_"+prop)){
									dic[obj[fd]]["avg_"+prop] = dic[obj[fd]]["sum_"+prop]/dic[obj[fd]]["total"];
								}
							}
						}
					}
					if(chd!=null){
						(dic[obj[fd]]["children"] as Array).push(chd);
					}
				}else{
					if(obj.hasOwnProperty("children")){
						obj["children"] = this._groupBy(new ArrayCollection(obj["children"] as Array), fd).source; 
					}
				}
			}
			var resp:ArrayCollection = new ArrayCollection();
			for each(var o:Object in dic){
				resp.addItem(o);
			}
			if(resp.length<=0){
				resp = datos;
			}
			return resp;
		}
		
		public function distinc(col:Object, lab:String="", indata:ArrayCollection=null):Object {
			var data:ArrayCollection =  new ArrayCollection();
			var dic : Dictionary = new Dictionary();
			
			var value : Object;
			var label : Object;
			
			if(indata != null){
				data = indata;
			}else{
				if(this.filter_data.length<=0){
					this.filter_data= new ArrayCollection(this.data.source);
				}
				data = this.filter_data;
			}
			
			var length : Number = data.length;
			var i:Number;
			var t:Number = 1;
			if(getQualifiedClassName(col) == getQualifiedClassName(Array)){
				for(i = 0; i < length; i++){
					var pdic:Dictionary = dic;
					var reg:Object=data.getItemAt(i);
					for each(var fd:Object in (col as Array)){
						var l:String = this.getValue(data.getItemAt(i),fd.field) as String;
						if(!pdic.hasOwnProperty(l)){
							pdic[l]={ nombre:fd.nombre, field:fd.field, data: l, label:this.getValue(data.getItemAt(i),fd.label), children: new Dictionary() };
						}
						pdic=pdic[l].children;
					}
				}
				return dic;
			}else{
				if(getQualifiedClassName(col) == getQualifiedClassName(String)){
					if(lab=="")
						lab=col.toString();
					for(i = 0; i < length; i++){
						value = this.getValue(data.getItemAt(i), col.toString());
						label = this.getValue(data.getItemAt(i), lab);
						t=1
						if(dic.hasOwnProperty(value)){
							if(dic[value].hasOwnProperty("total")){
								t=dic[value].total+1;
							}
						}
						var g:Graphic = this.getValue(data.getItemAt(i), "graphic") as Graphic;
						dic[value] = { v:value, l:label, t:g.geometry.type, total: t };
						var vt:Number = Number(value);
						if(!isNaN(vt)){
							var maxv:Number = vt;
							var minv:Number = vt;
							if(dic[value].hasOwnProperty("max")){
								maxv = Number(dic[value]["max"]);
							}
							if(dic[value].hasOwnProperty("min")){
								minv = Number(dic[value]["min"]);
							}
							if(vt>maxv){
								maxv = vt;
							}
							if(vt<minv){
								minv = vt;
							}
							dic[value]["max"] = maxv;
							dic[value]["min"] = minv;
						}
					}
					var unique:ArrayCollection = new ArrayCollection();
					for(var prop :String in dic){
						unique.addItem({ label: dic[prop].l, data: dic[prop].v, tipo: dic[prop].t, total:dic[prop].total, max:dic[prop].max, min:dic[prop].min });
					}
					return unique;
				}else{
					return new ArrayCollection();
				}
			}
		}
		
		private function getValue(obj:Object, field:String):Object{
			if(obj.hasOwnProperty(field)){
				return obj[field];
			}else{
				if(obj.hasOwnProperty("children")){
					for each(var h:Object in (obj["children"] as Array)){
						var r:Object = this.getValue(h, field);
						if(r != null){
							return r;
						}
					}
				}else{
					if(obj.hasOwnProperty("attributes")){
						if(obj.attributes.hasOwnProperty(field)){
							return obj.attributes[field];
						}else{
							if(field=="graphic"){
								return obj as Graphic;
							}
						}
					}
				}
				return null;
			}
		}
		
		public function filter(filtros:Object, clear:Boolean=true):void {
			this.banderaFiltrado=true;
			if(clear){
				this.filter_data = new ArrayCollection(this.data.source);
			}
			if(this.filter_data.length<=0){
				this.filter_data = new ArrayCollection(this.data.source);
			}
			this.proc_data=new ArrayCollection();
			var tmp:ArrayCollection= new ArrayCollection();
			if (Object(filtros).hasOwnProperty("field")&&Object(filtros).hasOwnProperty("value")) {
				if(filtros.field != "" && filtros.value != ""){
					this.tipoFilterDate=false;
					if(Object(filtros).hasOwnProperty("tipo")){
						if(filtros.tipo=="F"){
							this.tipoFilterDate=true;
						}
					}
					this.fieldFilter = filtros.field;
					this.valueFilter = filtros.value;
					tmp = this.filter_data;
					tmp.filterFunction = this.filterFunction;
					tmp.refresh();
					this.filter_data = new ArrayCollection();
					for each(var it:Object in tmp){
						this.filter_data.addItem(it);
					}
					if(Object(filtros).hasOwnProperty("filtro")){
						this._filter(filtros.filtro);
					}
				}
			}
		}
		
		private function _filter(filtros:Object):void {
			var tmp:ArrayCollection= new ArrayCollection();
			if (Object(filtros).hasOwnProperty("field")&&Object(filtros).hasOwnProperty("value")) {
				if(filtros.field != "" && filtros.value != ""){
					this.tipoFilterDate=false;
					if(Object(filtros).hasOwnProperty("tipo")){
						if(filtros.tipo=="F"){
							this.tipoFilterDate=true;
						}
					}
					this.fieldFilter = filtros.field;
					this.valueFilter = filtros.value;
					tmp = this.filter_data;
					tmp.filterFunction =  this.filterFunction;
					tmp.refresh();
					this.filter_data = new ArrayCollection();
					for each(var it:Object in tmp){
						this.filter_data.addItem(it);
					}
					if(Object(filtros).hasOwnProperty("filtro")){
						this._filter(filtros.filtro);
					}
				}
			} 
		}
		
		private function filterFunction(item:Object):Boolean {
			if (Object(item).hasOwnProperty(this.fieldFilter)){
				if(this.tipoFilterDate){
					var fechas:Array=this.valueFilter.split('-');
					if(fechas.length==2){
						var desde:Number =  Number(fechas[0]);
						var hasta:Number = Number(fechas[1]);
						var fecha:Number = item[this.fieldFilter] as Number;
						if(desde<=fecha && fecha<=hasta){
							return true;
						}else{
							return false;
						}
					}else{
						return true;
					}
				}else{
					return item[this.fieldFilter] == this.valueFilter;
				}
			}
			return false;
		}
		
		public function toArrayCollection():ArrayCollection{
			if(this.proc_data.length<=0){
				if(this.banderaFiltrado){
					this.proc_data = new ArrayCollection(this.filter_data.source);
				}else{
					this.proc_data = new ArrayCollection(this.data.source);
				}
			}
			return this.proc_data;
		}
		
		public function toGraphicsArray():ArrayCollection{
			var r:ArrayCollection = new ArrayCollection();
			if(this.proc_data.length<=0){
				if(this.banderaFiltrado){
					this.proc_data = new ArrayCollection(this.filter_data.source);
				}else{
					this.proc_data = new ArrayCollection(this.data.source);
				}
			}
			for each(var o:Object in this.proc_data){
				if(o.hasOwnProperty("graphic")){
					r.addItem(o.graphic);
				}
				if(o.hasOwnProperty("children")){
					this._toGraphicsArray(o.children, r);
				}
			}
			return r;
		}
		
		private function _toGraphicsArray(data:Array, r:ArrayCollection):void{
			for each(var o:Object in data){
				if(o.hasOwnProperty("graphic")){
					r.addItem(o.graphic);
				}
				if(o.hasOwnProperty("children")){
					this._toGraphicsArray(o.children, r);
				}
			}
		}
	}
}