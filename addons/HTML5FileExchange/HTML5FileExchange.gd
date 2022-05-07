extends Node

signal read_completed
signal load_completed(image)

var js_callback = JavaScript.create_callback(self, "load_handler");
var js_interface;

func _ready():
	if OS.get_name() == "HTML5" and OS.has_feature('JavaScript'):
		_define_js()
		js_interface = JavaScript.get_interface("_HTML5FileExchange");

func _define_js()->void:
	#Define JS script
	JavaScript.eval("""
	var _HTML5FileExchange = {};
	_HTML5FileExchange.upload = function(gd_callback) {
		canceled = true;
		var input = document.createElement('INPUT'); 
		input.setAttribute("type", "file");
		input.setAttribute("accept", "image/png, image/jpeg, image/webp");
		input.click();
		input.addEventListener('change', event => {
			if (event.target.files.length > 0){
				canceled = false;}
			var file = event.target.files[0];
			var reader = new FileReader();
			this.fileType = file.type;
			// var fileName = file.name;
			reader.readAsArrayBuffer(file);
			reader.onloadend = (evt) => { // Since here's it's arrow function, "this" still refers to _HTML5FileExchange
				if (evt.target.readyState == FileReader.DONE) {
					this.result = evt.target.result;
					gd_callback(); // It's hard to retrieve value from callback argument, so it's just for notification
				}
			}
		  });
	}
	""", true)

func load_handler(_args):
	emit_signal("read_completed")
	
func load_image():
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		return

	js_interface.upload(js_callback);

	yield(self, "read_completed")
	
	var imageType = js_interface.fileType;
	var imageData = JavaScript.eval("_HTML5FileExchange.result", true) # interface doesn't work as expected for some reason
	
	var image = Image.new()
	var image_error
	match imageType:
		"image/png":
			image_error = image.load_png_from_buffer(imageData)
		"image/jpeg":
			image_error = image.load_jpg_from_buffer(imageData)
		"image/webp":
			image_error = image.load_webp_from_buffer(imageData)
		var invalidType:
			print("Unsupported file format - %s." % invalidType)
			return
	
	if image_error:
		print("An error occurred while trying to display the image.")
	
	emit_signal("load_completed", image)

func save_image(image:Image, fileName:String = "export.png")->void:
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		return
	
	image.clear_mipmaps()
	var buffer = image.save_png_to_buffer()
	JavaScript.download_buffer(buffer, fileName)
