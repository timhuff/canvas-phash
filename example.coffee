
phash = require './index.coffee'

Promise = require 'bluebird'

Canvas = require 'canvas'
Image = Canvas.Image
fs = require 'fs'

img1 = new Image
img1.dataMode = Image.MODE_IMAGE
img1.src = fs.readFileSync './tests/image1.jpg'

img2 = './tests/image2.jpg'

init = process.hrtime()
Promise.join phash.getImageHash(img1),
	phash.getImageHash(img2),
	(buffer1, buffer2)->
		time = process.hrtime(init)
		console.log "Hashing time: #{time[0]}s #{time[1]}ns"
		init = process.hrtime()
		hd = phash.getHammingDistance buffer1, buffer2
		time = process.hrtime(init)
		console.log "Hamming time: #{time[0]}s #{time[1]}ns"
		console.log "Hamming distance: #{hd}"

phash.getSHA256 img1
.then (sha256)->
	console.log "img1 SHA256: #{sha256}"

phash.getSHA256 img2
.then (sha256)->
	console.log "img2 SHA256: #{sha256}"
