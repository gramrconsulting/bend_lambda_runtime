// Fake Lambda Runtime API: serves the events given as args, prints each response.
import http from 'node:http'
const events = process.argv.slice(3)
let next = 0, done = 0
http.createServer((req, res) => {
  if (req.method === 'GET') {
    if (next >= events.length) return // hold the poll, like Lambda between invocations
    res.writeHead(200, { 'Lambda-Runtime-Aws-Request-Id': `id-${next}` })
    return res.end(events[next++])
  }
  let body = ''
  req.on('data', d => body += d)
  req.on('end', () => {
    console.log(req.url, body)
    res.writeHead(202).end()
    if (++done === events.length) process.exit(0)
  })
}).listen(+process.argv[2], '127.0.0.1')
