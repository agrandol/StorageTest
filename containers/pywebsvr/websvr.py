# Web server to post results
#
from os import path, makedirs, curdir
import errno
from os.path import join as pjoin
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import urlparse
import sys
import tarfile
reload(sys)
sys.setdefaultencoding('utf8')

# Test input:
# url -X POST -H "Content-Type: application/json" -d @testdata.json localhost:8080/hostname/testin.json
# use --data-binary to preserve carriage returns and line feeds.
# curl -X POST -H "Content-Type: text/csv" --data-binary  @testin.csv localhost:8080/hostname/testin.csv

def createdir(writepath):
    print "Creating dir if not exist: %s" % writepath
    if not path.exists(path.dirname(writepath)):
        try:
            makedirs(path.dirname(writepath))
        except OSError as exc: # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise

class StoreHandler(BaseHTTPRequestHandler):
#    store_path = pjoin(curdir, 'results')
    store_path = '/results'

    def make_sure_path_exists(self, path):
        self.getFileName()
        try:
            os.makedirs(self.store_path + "/" + path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise

    def getFileName(self):
        print "self.url % s" % self.path

    def do_GET(self):
        if self.path == '/store.json':
            with open(self.store_path) as fh:
                self.send_response(200)
                self.send_header('Content-type', 'text/json')
                self.end_headers()
                self.wfile.write(fh.read().encode())

    def do_POST(self):
        writepath = self.store_path + "" + self.path
        print "POST resource path: %s" % writepath
        #self.make_sure_path_exists(path)
        #if self.path == '/store.json':
        length = self.headers['content-length']
        print "Content-length: %s" % length
        data = self.rfile.read(int(length))
        #print "Data to write to file %s: %s" % (writepath,data)
        # if smart, I would remove any attempts at reletave path walking, a.k.a ..
        # Create dirs if they don't exist
        createdir(writepath)
        with open(writepath, 'w') as fh:
            fh.write(data)
        self.send_response(200)
	#if (self.rfile.endswith("tgz")):
	#tar = tarfile.open(writepath, "r:gz")
    	#tar.extractall()
    	#tar.close()

server = HTTPServer(('', 8080), StoreHandler)
server.serve_forever()
