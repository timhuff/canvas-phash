Promise = require 'bluebird'

Canvas = require 'canvas'
Image = Canvas.Image

fs = require 'fs'
read = Promise.promisify fs.readFile

crypto = require 'crypto'

bitCount = (i)->
	i = i - ((i >>> 1) & 0x55555555);
	i = (i & 0x33333333) + ((i >>> 2) & 0x33333333);
	return (((i + (i >>> 4)) & 0x0F0F0F0F) * 0x01010101) >>> 24;

getImageFromPath = (path)->
	read path
	.then (imageSrc)->
		img = new Image
		img.dataMode = Image.MODE_IMAGE
		img.src = imageSrc
		img

imageHash =
	readImage: getImageFromPath

	getSHA256: (path)->
		if path instanceof Image
			canvasImage = Promise.resolve path
		else
			canvasImage = getImageFromPath path
		canvasImage.then (img)->
			canvas = new Canvas img.width, img.height
			ctx = canvas.getContext '2d'
			ctx.drawImage img, 0, 0, img.width, img.height
			pixelData = ctx.getImageData(0, 0, img.width, img.height).data
			new Buffer pixelData
		.then (pixelData)->
			sha256 = crypto.createHash "sha256"
			sha256.update pixelData
			hash = sha256.digest "base64"
			hash

	getImageHash: (path)->
		if path instanceof Image
			canvasImage = Promise.resolve path
		else
			canvasImage = getImageFromPath path

		canvasImage.then (img)->
			canvas = new Canvas 256, 256
			ctx = canvas.getContext '2d'
			ctx.scale 256 / img.width, 256 / img.height
			ctx.drawImage img, 0, 0, img.width, img.height

			Mean = r:[], g:[], b:[], l:[], a:0
			for blockRow in [0..15]
				for blockCol in [0..15]
					imageData = ctx.getImageData(16*blockCol, 16*blockRow, 16, 16).data
					avg = r:0, g:0, b:0
					for pixelNdx in [0..255]
						a = imageData[4*pixelNdx+3]
						if a == 0
							r = 0xff
							b = 0xff
							g = 0xff
						else
							r = imageData[4*pixelNdx+0]
							b = imageData[4*pixelNdx+1]
							g = imageData[4*pixelNdx+2]
						avg.r += (r - avg.r)/(pixelNdx+1)
						avg.g += (g - avg.g)/(pixelNdx+1)
						avg.b += (b - avg.b)/(pixelNdx+1)
					for color, val of avg
						Mean[color].push val

			Median = {r:0,g:0,b:0}
			getMedian = (values)->
				values.sort  (a,b)-> return a - b
				values[Math.floor values.length/2]
			for color, array of Median
				Median[color] = getMedian Mean[color].slice 0

			buffer = new Buffer 128, 'utf8'

			hexString = ""
			for pixelNdx in [0..255]
				char = 0
				r = Mean.r[pixelNdx]
				g = Mean.g[pixelNdx]
				b = Mean.b[pixelNdx]
				if r >= Median.r
					char |= 0x4
				if g >= Median.g
					char |= 0x2
				if b >= Median.b
					char |= 0x1
				hexString += char.toString(16)

			buffer.write hexString, 0, 128, 'hex'

			buffer

	getHammingDistance: (buffer1, buffer2)->
		Buffer xor = new Buffer 128, 'utf8'
		hammingDistance = 0
		for n in [0..127] by 4
			x = buffer1.readUInt32BE(n)
			y = buffer2.readUInt32BE(n)
			hammingDistance += bitCount(x^y)
		hammingDistance


module.exports = imageHash
