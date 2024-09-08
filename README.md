# canvas-phash

> Note: This project is no longer actively maintained. Updates have been made to this repo since the last npm package was published and the following README content needs to be updated. A new version might be published to npm when I have more time.

## Introduction

This is an implementation of a perceptual image hash, ~~using Canvas~~ written in 100% javascript/coffeescript. The algorithm used is described in [
Block Mean Value Based Image Perceptual Hashing](http://ieeexplore.ieee.org/xpl/login.jsp?tp=&arnumber=4041692&url=http%3A%2F%2Fieeexplore.ieee.org%2Fxpls%2Fabs_all.jsp%3Farnumber%3D4041692) and discussed in [this StackOverflow question](http://stackoverflow.com/questions/14377854/block-mean-value-hashing-method).

## Difference From `phash`

I found the [phash](https://www.npmjs.com/package/phash) package to be a little error prone with respect to file I/O. This package, while the API is very similar, is different in some key ways.

- `phash` binds directly to the [pHash library](http://www.phash.org/). `canvas-phash` is a direct implementation, written in coffeescript.
- `phash` is callback-based while `canvas-phash` is promise-based (specifically, it uses [bluebird](https://github.com/petkaantonov/bluebird) for promise management).
- `phash` generally takes longer to compute the hash of an image but is faster at finding the hamming distance between two hashes.
- The hash output by `phash` is an integer, expressed as a string. The hash output by `canvas-phash` is a 128-byte `Buffer`.
- Comparing the two libraries on the basis of the correlation between hamming distance and "perceived difference" had mixed results. `phash` was better at some things, `canvas-phash` was better at others.

## Performance

I ran some preliminary tests to check the performance against `phash` and found it's fairly comparable.

### Computing A Hash

The time taken ranged from just under 75ms to 150ms. For my tests, it generally took `phash` about 1-2 times longer to compute a hash as it took `canvas-phash`.

### Finding the Hamming Distance

Typical time taken ranged from 0.2ms to 0.3ms. For my tests, it generally took `canvas-phash` about 2-3 times longer to find the hamming distance of two hashes. When comparing against a large collection of images, this is potentially significant. That being said, this library has not been optimized. Also, the actual hash created is 128 bytes long and takes up about 2-3 times more space.

## API

- `getImageHash` - Accepts 1 parameter, the path of the image. Returns a promise with eventual value equal to the "Block Mean Value Based" pHash.
- `getHammingDistance` - Accepts 2 parameters, two instances of `Buffer` of length 128 (this is what is returned from `getImageHash`)
- `getSHA256` - This computes the SHA256 hash of the pixel data. The only parameter is setup like that of `getImageHash`. This is useful for fast checks of exact matches. Ignores metadata.
- `readImage` - Reads an image at the specified path and returns an object with properties: `data`, the byte array, `width`, the width of the image, and `height`, the height of the image.

## Example Usage

(Another example exists in the repo)

```coffee
phash = require 'canvas-phash'

Promise = require 'bluebird'
Promise.all([
	phash.getImageHash 'image.jpg'
	phash.getImageHash 'otherImage.jpg'
])
.spread (hash1, hash2)->
	dist = phash.getHammingDistance hash1, hash2
```

In the previous example, Promise.all is used to make the code readable. `require`ing `bluebird` is not necessary to use this package. The typical use-case would be to compute the hash of a single image via `phash.getImageHash('image.jpg').then (hash)->` and compare that against a list of pre-existing hashes for close matches.
