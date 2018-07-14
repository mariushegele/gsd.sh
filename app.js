var express = require('express')
var path = require('path')
var http = require('http')
 
var app = express()

app.set('port', (process.argv[2] || 5000))
app.use(express.static(path.join(__dirname, 'public')));


app.get('/', function(req, res) {
    res.sendFile(__dirname + '/alert.html')
})

var server = http.createServer(app)
server.listen(app.get('port'))