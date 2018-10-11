const express = require('express');
const mysql  =  require('mysql');
const bcryptjs = require('bcryptjs');
const basicAuth = require('basic-auth');
const bodyparser = require('body-parser');
const saltRounds = 10;
const app = express();
const path=require('path');
const multer = require('multer');
//testing
//process.env.NODE_ENV = 'test';
var request = require('supertest');
let chai = require('chai');
let chaiHttp = require('chai-http');
let should = chai.should();
var expect = chai.expect;
chai.use(chaiHttp);




//bodyparser for testing api inputs
app.use(bodyparser.urlencoded({
    extended : false
}));

app.use(bodyparser.json());


const storage =multer.diskStorage({
    destination: './uploads',
    filename : function (reqe,file,cb) {
        cb(null,file.fieldname + '-' + Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({
    storage : storage
}).single('jayjay');
app.post('/test',function (req,res) {
    upload(req,res,(err => {
        if(err)
        {
            throw err;
        }
        else
        {
            console.log("file name")
            console.log(req.file)
            res.send(req.file);
        }
    }))
    //res.send('test');
    //console.log(req.files.filename);
})

//enabling cors
app.use(function (req,res,next) {

    res.header("Access-Control-Allow-Methods","GET,PUT,POST,DELETE,OPTIONS");
    res.header("Access-Control-Allow-Origin","*");
    res.header("Access-Control-Allow-Headers","Origin,X-Requested-With,Content-Type,Accept");
    next();
})

//create the connection
const db =mysql.createConnection({
    host     : 'localhost',
    user     :  'root',
    password : 'Hardik-2010',
    database : 'WebApp'
});

//start the server
app.listen('5000',()=>{
    console.log('Server started on port 5000');
});

//connect to the database
db.connect((err) =>{
    if(err)
    {
        throw err;
    }
    console.log("Database connected");
});

app.post('/register',(req,res) =>{
    if(req.body.username && req.body.password) {
        if (validationemail(req.body.username)) {
            var salt = bcryptjs.genSaltSync(saltRounds);
            var hash = bcryptjs.hashSync(req.body.password, salt);
            let selectsql = `Select username from login WHERE username = '${req.body.username}'`
            db.query(selectsql, function (err, resu) {
                if (err) {
                    throw err;
                }
                if (!resu[0]) {
                    let sql = `INSERT INTO   login (username,password) VALUES ('${req.body.username}','${hash}')`
                    db.query(sql, function (err, result) {
                        if (err) {
                            throw err;
                        }
                        res.send("User Successfully Created");
                    })
                }
                if (resu[0]) {
                    res.send("User already exits");
                }
            })
        }
        else {
            res.send("incorrect username")
        }
    }
    else {
        res.send("enter valid username and password")
    }
});

//get time api
app.get('/time',(req,res) => {
    var credentials = basicAuth(req);
    var salt = bcryptjs.genSaltSync(saltRounds);
    var decrypt = bcryptjs.hashSync(credentials.pass, salt);
    let seesql = `SELECT password from login WHERE username = '${credentials.name}'`
    db.query(seesql, function (err, passauth) {
        if (err) {
            throw err;
        }
        if (bcryptjs.compareSync(credentials.pass,passauth[0].password)) {

            let sql = `SELECT username,password from login WHERE username = '${credentials.name}' and password = '${passauth[0].password}'`;
            db.query(sql, function (err, log) {
                if (err) {
                    throw err;
                }
                if (log[0]) {
                    var date = new Date();
                    var hour = date.getHours();
                    hour = (hour < 10 ? "0" : "") + hour;

                    var min = date.getMinutes();
                    min = (min < 10 ? "0" : "") + min;

                    var seconds = date.getSeconds();
                    seconds = (seconds < 10 ? "0" : "") + seconds;

                    var year = date.getFullYear();

                    var month = date.getMonth() + 1;
                    month = (month < 10 ? "0" : "") + month;

                    var day = date.getDate();
                    day = (day < 10 ? "0" : "") + day - 1;

                    var time = (year + ":" + month + ":" + day + " : " + hour + ":" + min + ":" + seconds);
                    res.send(time);
                }
                if (!log[0]) {
                    res.send("invalid username/password")
                }

            })
        }
        else {
            res.send("invalid credentionals")
        }
    })
})

//Code to validate email
function validationemail(email){
  //  var em = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0,9]{1,3}\.[0,9]{1,3}\])\(([a-zA-Z\0-9]+\.)+[a-zA-Z]{2,}))$/;
    var em= /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return em.test(email);
}

// Code to validate whitespaces and tabs.
function hasWhiteSpace(sr)
{
    reWhiteSpace = /\s/g;
    return reWhiteSpace.test(sr);
}

//Test case for register
// chai.request(app)
//     .post('/register')
//     .send({username: 'rini@gmail.com',password : 'rinimini'})
//     .end(function (err,res) {
//         expect(res).have.status(200);
//         if(err)
//         {
//             console.log(err);
//         }
//         console.log("Test Successfull");
//     })
