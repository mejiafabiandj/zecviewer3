package widgets.DANE.Herramientas
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.ICipher;
	import com.hurlant.crypto.symmetric.IPad;
	import com.hurlant.crypto.symmetric.PKCS5;
	import com.hurlant.util.Hex;
	
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;

	public class encriptar
	{
		public function encriptar()
		{
		}
		
		public static function encrypt(encryptionKey:String, mensaje:String):String{
			
			var kdata:ByteArray = Hex.toArray(encryptionKey);
			var data:ByteArray = Hex.toArray(Hex.fromString((mensaje)));
			var name:String = "simple-aes-ecb";
			var pad:IPad = new PKCS5();
			var mode:ICipher = Crypto.getCipher(name, kdata, pad);
			pad.setBlockSize(mode.getBlockSize());
			mode.encrypt(data);

			return Hex.fromArray(data);			
		}
		
		public static function decrypt(encryptionKey:String, mensajeEncriptado:String):String{
			
			var mensaje:String = '';
			
			if(mensajeEncriptado!= ''){
				
				var kdata:ByteArray = Hex.toArray(encryptionKey);
				var data:ByteArray = Hex.toArray(mensajeEncriptado);
				var name:String = "simple-aes-ecb";
				var pad:IPad = new PKCS5();
				var mode:ICipher = Crypto.getCipher(name, kdata, pad);
				pad.setBlockSize(mode.getBlockSize());
				mode.decrypt(data);
				
				if(data != null){
					mensaje= Hex.toString(Hex.fromArray(data));
				}
				
			} else {
				Alert.show("Empty text to decrypt!");
			}
			
			return mensaje;
		}
	}
		
}