import http.server
import socketserver
import os
import urllib.parse as urlparse
import psycopg2
import time

PORT = os.environ['PORT']
DATABASE_URL = os.environ['DATABASE_URL']

parsed = urlparse.urlparse(DATABASE_URL)

class CustomRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.endswith('api'):
            with psycopg2.connect(
                dbname=parsed.path[1:],
                user=parsed.username,
                password=parsed.password,
                host=parsed.hostname,
                port=parsed.port) as connection:

                cursor = connection.cursor()
                cursor.execute("select * from pg_language;")
                query_result = cursor.fetchone()

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()

                fmt = '{{ "timestamp": "{}", "message": "{}" }}'
                self.wfile.write(fmt.format(round(time.time()), str(query_result)).encode("utf-8"))
        else:
            with open('./index.html', 'rb') as f:
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.end_headers()

                self.wfile.write(f.read())
        return

httpd = socketserver.TCPServer(("", int(PORT)), CustomRequestHandler)
print("Python web server listening on port {}...".format(PORT))
httpd.serve_forever()
