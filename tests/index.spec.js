const phash = require('../index.js');

describe('pHash Tests', () => {
  let img1, img2;

  beforeAll(async () => {
    img1 = await phash.readImage('./tests/Mona_Lisa.jpg');
    img2 = await phash.readImage('./tests/Mona_Lisa_2.jpg');
  });

  test('should compute correct image hashes', async () => {
    expect((await phash.getImageHash(img1)).toString('hex')).toEqual('3333337737333333777777777777777777777766007777777777777707707777777747770730777771770067071033771177074044003373744600777704767765667077774600756116006606000051771500000000007105000000000000110164770000000010000070776644001000006644040000000000000000000000');
    expect((await phash.getImageHash(img2)).toString('hex')).toEqual('7777777777777777777777777777777777777747707777777777777707707777737777770430737731330377070073331033075000103333776600707700736746777077777400776406706606000044660400000040004000000000000001400057000000000001000074770005001000007775050000000000000000000000');
  })
  test('should calculate Hamming distance between image hashes', async () => {
    const imageHash1 = await phash.getImageHash(img1)
    const imageHash2 = await phash.getImageHash(img2)
    const hex1 = imageHash1.toString('hex').split('').map(d => parseInt(d, 16).toString(2).padStart(4, '0')).join('')
    const hex2 = imageHash2.toString('hex').split('').map(d => parseInt(d, 16).toString(2).padStart(4, '0')).join('')
    let correctHd = 0
    for (let i = 0; i < hex1.length; i++) {
      if (hex1[i] !== hex2[i]) {
        correctHd++
      }
    }
    const hd = phash.getHammingDistance(imageHash1, imageHash2);
    expect(hd).toEqual(correctHd);
  });
});
