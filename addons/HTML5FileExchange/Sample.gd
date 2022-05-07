extends TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_UploadButton_pressed():
	HTML5File.load_image()

	var image = yield(HTML5File, "load_completed")

	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	
	texture = tex;

func _on_DownloadButton_pressed():
	var image = texture.get_data()
	HTML5File.save_image(image, "image.png")
