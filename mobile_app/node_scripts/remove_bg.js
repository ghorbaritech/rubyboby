const Jimp = require('jimp');
const path = require('path');
const fs = require('fs');

async function removeBackground(inputPath, outputPath) {
  console.log(`Processing ${inputPath}...`);
  const image = await Jimp.read(inputPath);
  const width = image.bitmap.width;
  const height = image.bitmap.height;

  // Sample top-left corner to identify background color
  const bgR = image.bitmap.data[0];
  const bgG = image.bitmap.data[1];
  const bgB = image.bitmap.data[2];
  
  console.log(`Sampled background color: RGB(${bgR}, ${bgG}, ${bgB})`);

  image.scan(0, 0, width, height, function(x, y, idx) {
    const r = this.bitmap.data[idx + 0];
    const g = this.bitmap.data[idx + 1];
    const b = this.bitmap.data[idx + 2];

    // Distance metric from sampled background color
    const diffBg = Math.abs(r - bgR) + Math.abs(g - bgG) + Math.abs(b - bgB);
    // General white threshold keying
    const isOffWhite = (r > 242 && g > 242 && b > 242);

    if (diffBg < 45 || isOffWhite) {
      this.bitmap.data[idx + 3] = 0; // Transparent
    }
  });

  // Apply a slight border feather/cleanup if needed, or just save
  await image.writeAsync(outputPath);
  console.log(`Saved transparent image to ${outputPath}`);
}

const args = process.argv.slice(2);
if (args.length < 2) {
  console.error("Usage: node remove_bg.js <input_path> <output_path>");
  process.exit(1);
}

removeBackground(args[0], args[1]).catch(err => {
  console.error(err);
  process.exit(1);
});
