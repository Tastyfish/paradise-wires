import sys, os
from PIL import Image
from PIL.ImageDraw import Draw
import errno

if len(sys.argv) < 3:
	exit(1)
	
path = sys.argv[1]
filename = sys.argv[2]

def safe_save(image, dirs, name):
	try:
		os.makedirs(dirs)
	except OSError as exception:
		if exception.errno != errno.EEXIST:
			raise
	image.save(dirs+"/"+name)

# generate ALL MAP TILES
def gen_bigimg_mapall(path, filename):
	base = Image.open(filename)
	
	gen_bigimg_map(path, base)
	for z in range(4, 1, -1):
		gen_special_mapzooms(path, z)

# generate the zoomed out tiles
def gen_special_mapzooms(path, z):
	# figure out output grid size
	size = 32 / 2 ** (5 - z)

	for x in range(0, size):
		for y in range(0, size):
			icon = Image.new("RGBA", (256, 256), "black")
			
			i = Image.open("./{}/{:d}/{:d}/{:d}.png".format(path, z+1, x*2, y*2))
			icon.paste(i.resize((128, 128), Image.ANTIALIAS), (0, 128))
			i = Image.open("./{}/{:d}/{:d}/{:d}.png".format(path, z+1, x*2+1, y*2))
			icon.paste(i.resize((128, 128), Image.ANTIALIAS), (128, 128))
			i = Image.open("./{}/{:d}/{:d}/{:d}.png".format(path, z+1, x*2, y*2+1))
			icon.paste(i.resize((128, 128), Image.ANTIALIAS), (0, 0))
			i = Image.open("./{}/{:d}/{:d}/{:d}.png".format(path, z+1, x*2+1, y*2+1))
			icon.paste(i.resize((128, 128), Image.ANTIALIAS), (128, 0))
			safe_save(icon, "./{}/{:d}/{:d}".format(path, z, x), "{:d}.png".format(y))
	
# generate the 1:1 zoom tiles
def gen_bigimg_map(path, base):
	for x in range(0, 8192, 256):
		for y in range(0, 8192, 256):
			icon = base.crop((x, 8191 - 255 - y, x + 255, 8191 - y))
			safe_save(icon, "./{}/{:d}/{:d}/".format(path, 5, int(x/256)), "{:d}.png".format(int(y/256)))
			
gen_bigimg_mapall(path, filename)