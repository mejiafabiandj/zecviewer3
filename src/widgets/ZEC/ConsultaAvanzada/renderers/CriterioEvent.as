package widgets.DANE.ConsultaAvanzada.renderers
{
	import com.esri.ags.layers.supportClasses.Field;
	
	import flash.events.Event;
	
	public class CriterioEvent extends Event
	{
		
		public static const CRITERIO_CHANGE:String = "criterioChange";
		public static const CRITERIO_STATE_CHANGE:String = "criterioStateChange";
		
		public function CriterioEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false,data:Object = null)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		public var data:Object;
		
		
		/**
		 *  @private
		 */
		override public function clone():Event
		{
			return new CriterioEvent(type, bubbles, cancelable,
				data);
		}
	}
}