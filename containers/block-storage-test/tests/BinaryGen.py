#!/usr/bin/python

import time
import random
from optparse import OptionParser, IndentedHelpFormatter

class NoWrapHelpFormatter(IndentedHelpFormatter):
	def __init__(self, *args, **kwargs):
		IndentedHelpFormatter.__init__(self, *args, **kwargs)
	def format_description(self, description):
		return description

parser = OptionParser(version="$Revision: 1335 $",
	formatter = NoWrapHelpFormatter(),
	description = __doc__,
	usage = "Usage: %prog [options]" )
parser.add_option("-b", "--basis",
	action="store", type="int", dest="basisSize", default=16,
	help="Size of base vectors for random data", metavar='BASIS')
parser.add_option("-s", "--size",
	action="store", type="int", dest="size", default=1024*1024*1024,
	help="Size of data (bytes) to create", metavar='SIZE')
parser.add_option("-o", "--output",
	action="store", dest="output", default='output.dat',
	help="Output file name", metavar='FILE')

(options, args) = parser.parse_args()

class BinGen :
	def __init__(self, basis=16) :
		self.rfd = open("/dev/urandom", "rb")
		self.sources = []
		self.basisSize = basis
		for i in range(0, self.basisSize) :
			self.sources.append(None)

	def review(self) :
		for i in range(0, self.basisSize) :
			if self.sources[i] == None :
				print "%02d None" % (i)
			else :
				print "%02d %d" % (i, len(self.sources[i])) 
				
	def random(self) :
		sel = int(random.uniform(0, self.basisSize-1) + 0.5)
		if self.sources[sel] == None :
			size = 1 << sel
			self.sources[sel] = self.rfd.read(size)
#			print "alloc %d of %d -- %d" % (sel, self.basisSize, len(self.sources[sel]))
		return self.sources[sel]
	
	def generate(self, size, fd) :
		left = size
		try :
			while left > 0 :
				data = self.random()
				have = len(data)
				if have > left :
					fd.write(data[:left])
					left = 0
				else :
					fd.write(data)
					left -= have
		except IOError, e :
			print e
			return
			
gen = BinGen(options.basisSize)
t = open(options.output, "wb")
startTime = time.time()
gen.generate(options.size, t)
duration = time.time() - startTime
t.close()

print "BinaryGen %.6f MB/s\n" % (options.size/(1024*1024) / duration)

# gen.review()
