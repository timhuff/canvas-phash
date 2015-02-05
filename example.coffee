
phash = require './index'

Promise = require 'bluebird'

img1 = './tests/image5.jpg'
img2 = './tests/image12.jpg'

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
