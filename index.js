const getPixels = require('get-pixels');
const crypto = require('crypto');

function bitCount(i) {
	i = i - ((i >>> 1) & 0x55555555);
	i = (i & 0x33333333) + ((i >>> 2) & 0x33333333);
	return (((i + (i >>> 4)) & 0x0F0F0F0F) * 0x01010101) >>> 24;
}

function getImageFromPath(path) {
	return new Promise((resolve, reject) => getPixels(path, (err, pixels) => { err ? reject(err) : resolve(pixels); }))
		.then(pixels => {
			pixels.width = pixels.shape[0];
			pixels.height = pixels.shape[1];
			pixels.channels = pixels.shape[2];
			return pixels;
		});
}

function getRegionPixels(img, x, y, width, height) {
	const result = [];
	for (let j = y; j <= y + height - 1; j++) {
		for (let i = x; i <= x + width - 1; i++) {
			const pixelNdx = j * img.width + i;
			result.push(img.data[4 * pixelNdx]);
			result.push(img.data[4 * pixelNdx + 1]);
			result.push(img.data[4 * pixelNdx + 2]);
			result.push(img.data[4 * pixelNdx + 3]);
		}
	}
	return result;
}

const CanvasPhash = {
	readImage: getImageFromPath,

	getSHA256: function (path) {
		let pixelPromise;
		if (typeof path === 'string') {
			pixelPromise = getImageFromPath(path);
		} else {
			pixelPromise = Promise.resolve(path);
		}
		return pixelPromise.then(pixels => {
			return Promise.resolve(Buffer.from(pixels.data));
		}).then(pixelBuffer => {
			const sha256 = crypto.createHash('sha256');
			sha256.update(pixelBuffer);
			const hash = sha256.digest('base64');
			return hash;
		});
	},

	getImageHash: function (path) {
		let pixelPromise;
		if (typeof path === 'string') {
			pixelPromise = getImageFromPath(path);
		} else {
			pixelPromise = Promise.resolve(path);
		}

		return pixelPromise.then(img => {
			const Mean = { r: [], g: [], b: [], a: 0 };
			for (let blockRow = 0; blockRow < 16; blockRow++) {
				for (let blockCol = 0; blockCol < 16; blockCol++) {
					const blockWidth = Math.floor(img.width / 16);
					const blockHeight = Math.floor(img.height / 16);
					const imageData = getRegionPixels(img, blockWidth * blockCol, blockHeight * blockRow, blockWidth, blockHeight);
					const avg = { r: 0, g: 0, b: 0 };
					for (let pixelNdx = 0; pixelNdx < 256; pixelNdx++) {
						let r, g, b;
						const a = imageData[4 * pixelNdx + 3];
						if (a === 0) {
							r = 0xff;
							g = 0xff;
							b = 0xff;
						} else {
							r = imageData[4 * pixelNdx];
							g = imageData[4 * pixelNdx + 1];
							b = imageData[4 * pixelNdx + 2];
						}
						avg.r += (r - avg.r) / (pixelNdx + 1);
						avg.g += (g - avg.g) / (pixelNdx + 1);
						avg.b += (b - avg.b) / (pixelNdx + 1);
					}
					Mean.r.push(avg.r);
					Mean.g.push(avg.g);
					Mean.b.push(avg.b);
				}
			}

			const Median = { r: 0, g: 0, b: 0 };
			function getMedian(values) {
				values.sort((a, b) => a - b);
				return values[Math.floor(values.length / 2)];
			}
			Median.r = getMedian(Mean.r.slice(0));
			Median.g = getMedian(Mean.g.slice(0));
			Median.b = getMedian(Mean.b.slice(0));

			const buffer = Buffer.alloc(128, 'hex')
			let char = 0;
			for (let blockNdx = 0; blockNdx < 256; blockNdx++) {
				const r = Mean.r[blockNdx];
				const g = Mean.g[blockNdx];
				const b = Mean.b[blockNdx];
				if (r >= Median.r) char |= (0x4 << ((blockNdx % 2) * 4));
				if (g >= Median.g) char |= (0x2 << ((blockNdx % 2) * 4));
				if (b >= Median.b) char |= (0x1 << ((blockNdx % 2) * 4));
				if (blockNdx % 2 === 1) {
					buffer.writeUInt8(char, Math.floor(blockNdx / 2));
					char = 0;
				}
			}
			return buffer;
		});
	},

	getHammingDistance: function (buffer1, buffer2) {
		let hammingDistance = 0;
		for (let n = 0; n < 128; n++) {
			const x = buffer1.readUInt8(n);
			const y = buffer2.readUInt8(n);
			hammingDistance += bitCount(x ^ y);
		}
		return hammingDistance;
	}
};

module.exports = CanvasPhash;
