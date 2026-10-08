const { spawn } = require('node:child_process');

spawn(process.execPath, [require('node:path').join(__dirname, 'zedreply-static-server.js')], {
  detached: true,
  stdio: 'ignore',
}).unref();

console.log('');
console.log('Zedreply is running. Click either URL below:');
console.log('Zedreply agent dashboard: http://localhost:3000');
console.log('Zedreply customer test chat: http://localhost:8080/zedreply-customer-test.html');
const links = [
  'Zedreply agent dashboard: http://localhost:3000',
  'Zedreply customer test chat: http://localhost:8080/zedreply-customer-test.html',
];

console.log('');
console.log('Zedreply is running. Click either URL below:');
for (const link of links) console.log(link);
