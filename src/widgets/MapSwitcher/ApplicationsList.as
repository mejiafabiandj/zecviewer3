package widgets.MapSwitcher
{
	import mx.core.ClassFactory;
	
	import spark.components.List;
	
	public class ApplicationsList extends List
	{
		public function ApplicationsList()
		{
			super();
			
			this.itemRendererFunction = rendererFunction;
		}
		
		private function rendererFunction(item:Object):ClassFactory
		{
			if (item.sub)
			{
				return new ClassFactory(ApplicationsListGroupRenderer);
			}
			else
			{
				return new ClassFactory(ApplicationsListItemRenderer);
			}
		}
	}
}