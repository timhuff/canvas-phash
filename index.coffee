Promise = require 'bluebird'

getPixels = require 'get-pixels'
getPixels = Promise.promisify getPixels

fs = require 'fs'
read = Promise.promisify fs.readFile

crypto = require 'crypto'

bitCount = (i)->
	i = i - ((i >>> 1) & 0x55555555);
	i = (i & 0x33333333) + ((i >>> 2) & 0x33333333);
	return (((i + (i >>> 4)) & 0x0F0F0F0F) * 0x01010101) >>> 24;

getImageFromPath = (path)->
	getPixels path
	.then (pixels)->
		pixels.width = pixels.shape[0]
		pixels.height = pixels.shape[1]
		pixels.channels = pixels.shape[2]
		pixels

getRegionPixels = (img, x, y, width, height)->
	result = []
	for j in [y..y+height-1]
		for i in [x..x+width-1]
			pixelNdx = j*img.width+i
			result.push img.data[4*pixelNdx]
			result.push img.data[4*pixelNdx+1]
			result.push img.data[4*pixelNdx+2]
			result.push img.data[4*pixelNdx+3]
	result

CanvasPhash =
	readImage: getImageFromPath

	getSHA256: (path)->
		getPixels path
		.then (pixels)->
			Promise.resolve new Buffer pixels.data
		.then (pixelBuffer)->
			sha256 = crypto.createHash "sha256"
			sha256.update pixelBuffer
			hash = sha256.digest "base64"
			hash

	getImageHash: (path)->
		getImageFromPath path
		.then (img)->
			Mean = r:[], g:[], b:[], a:0
			for blockRow in [0..15]
				for blockCol in [0..15]
					blockWidth = Math.floor img.width / 16
					blockHeight = Math.floor img.height / 16
					imageData = getRegionPixels img, blockWidth*blockCol, blockHeight*blockRow, blockWidth, blockHeight
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
			for blockNdx in [0..255]
				char = 0
				r = Mean.r[blockNdx]
				g = Mean.g[blockNdx]
				b = Mean.b[blockNdx]
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


module.exports = CanvasPhash

Promise.all [
	CanvasPhash.getImageHash './failure.png'
	CanvasPhash.getImageHash './failure2.png'
]
.spread (result, result2)->
	console.log result+''
	CanvasPhash.getHammingDistance result, result2
.then (dist)->
	console.log dist



# sha256: XSTaHGWrLFp9F1DitplqnHxU+HWjuvkQZoHVBnE8U3g=
# phash: wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
