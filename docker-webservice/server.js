'use strict';
var app = require('express')();
var http = require('http').Server(app);
var bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded()); 


app.get('/', function (req, res) {
  res.send('After long long journey, finally I can deployed this for our CCPX !\nsay congrats to me please T^T');
});

app.post('/testPost',function(req, res){
  res.json({"msg":"Posted requested"});
});

http.listen(8080, function(){
  console.log('listening on *:8080');
  console.log('avaliable services: testGet,testGetWithParam,testPost,testPostWithParam');
});
