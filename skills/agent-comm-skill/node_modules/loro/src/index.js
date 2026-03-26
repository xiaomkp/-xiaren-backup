var express = require('express');
var bodyParser = require('body-parser');
var config = require('./../config/config.json');
var data = require('./../data/data.json');
var http = require('http'),
app = express();
var router = express.Router();

router.get('/json/loro/:loro', function (req, res, next) {
    try {
            var loroId = req.params.loro;
            var response = JSON.stringify(data.loros[loroId]);
            res.send(response).end();
    }
    catch (e) {
        console.error("An Exception happend when getting the POST Request, Possible reasons: body not a valid json object");
    }
});

router.get('/json/loros', function (req, res, next) {
    try {
            res.send(data).end();
            //res.send(JSON.stringify(data)).end();
    }
    catch (e) {
        console.error("An Exception happend when getting the POST Request, Possible reasons: body not a valid json object");
    }
});

router.post('/json/loro/:loro', function (req, res, next) {
    try {
            var loroId = req.params.user;
            var response = JSON.stringify(data.loros[loroId]);
            res.send(response).end();
    }
    catch (e) {
        console.error("An Exception happend when getting the POST Request, Possible reasons: body not a valid json object");
    }
});

router.post('/json/loros', function (req, res, next) {
    try {
            res.send(data).end();
    }
    catch (e) {
        console.error("An Exception happend when getting the POST Request, Possible reasons: body not a valid json object");
    }
});


app.use('/', router);

console.log(config.server.port);

http.createServer(app).listen(process.env.PORT || config.server.port);
console.log("Listening on port: " + (process.env.PORT || config.server.port));
