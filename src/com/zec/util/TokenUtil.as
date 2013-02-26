package gov.dane.util
{
	import com.esri.viewer.ConfigData;
	import com.esri.viewer.ViewerContainer;
	
	import mx.collections.ArrayCollection;

	public class TokenUtil
	{
		public function TokenUtil()
		{
		}
		
		/**
		 * Busca el token asociado a un servidor al interior del archivo XML de configuración principal, en la etiqueta
		 * <code>data/tokens/token</code>
		 **/
		public static function buscarToken(serviceUrl:String,configData:ConfigData = null):String
		{
			if(!serviceUrl)
			{
				return null;
			}
			if(!configData)
			{
				configData = ViewerContainer.getInstance().configData;
			}
			var tk:String;
			if(configData.data && configData.data.tokens)
			{
				if(configData.data.tokens.token is ArrayCollection)
				{
					for each(var token:Object in configData.data.tokens.token)
					{
						if(serviceUrl.lastIndexOf(token.url) != -1)
						{
							tk = token.token;
							break;
						}
					}
				}else if(configData.data.tokens.token && configData.data.tokens.token.url)
				{
					if(serviceUrl.lastIndexOf(configData.data.tokens.token.url) != -1)
					{
						tk = configData.data.tokens.token.token;
					}
				}
			}
			return tk;
		}
	}
}