const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const port = 8090;
const publicDirectory = path.resolve(__dirname, '..', 'public');

const server = http.createServer((request, response) => {
  const requestPath = request.url === '/' ? '/zedreply-customer-test.html' : request.url;
  const filePath = path.join(publicDirectory, path.normalize(requestPath));

  if (!filePath.startsWith(publicDirectory) || !fs.existsSync(filePath)) {
    response.writeHead(404);
    response.end('Not found');
    return;
  }

  response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  fs.createReadStream(filePath).pipe(response);
});

server.listen(port, '127.0.0.1');
