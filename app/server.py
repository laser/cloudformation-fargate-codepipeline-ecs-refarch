import http.server
import socketserver
import os
import urllib.parse as urlparse
import psycopg2

PORT = os.environ['PORT']
DATABASE_URL = os.environ['DATABASE_URL']

parsed = urlparse.urlparse(DATABASE_URL)

class CustomRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        with psycopg2.connect(
            dbname=parsed.path[1:],
            user=parsed.username,
            password=parsed.password,
            host=parsed.hostname,
            port=parsed.port) as connection, open('./index.html', 'rb') as f:

            cursor = connection.cursor()
            cursor.execute("select * from pg_language;")
            query_result = cursor.fetchone()

            self.send_response(200)
            self.send_header('X-Database-Stuff', str(query_result))
            self.end_headers()

            self.wfile.write(f.read())
            return

httpd = socketserver.TCPServer(("", int(PORT)), CustomRequestHandler)
print("Python web server listening on port {}...".format(PORT))
httpd.serve_forever()
