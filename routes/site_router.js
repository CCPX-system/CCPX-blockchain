'use strict';
/* global process */
/*******************************************************************************
 * Copyright (c) 2015 IBM Corp.
 *
 * All rights reserved. 
 *
 * Contributors:
 *   David Huffman - Initial implementation
 *******************************************************************************/
var express = require('express');
var router = express.Router();
var setup = require('../setup.js');

//anything in here gets passed to JADE template engine
function build_bag(){
	return {
				setup: setup,								//static vars for configuration settings
				e: process.error,							//send any setup errors
				jshash: process.env.cachebust_js,			//js cache busting hash (not important)
				csshash: process.env.cachebust_css,			//css cache busting hash (not important)
			};
}

// ============================================================================================================================
// Home
// ============================================================================================================================
router.route('/').get(function(req, res){
	res.json({ "message": 'CCPX-webservices' }); 
});

// ============================================================================================================================
// Part 1
// ============================================================================================================================
router.route('/marble_p1').get(function(req, res){
	res.render('part1', {title: 'Marbles Part 1', bag: build_bag()});
});
router.route('/p1/:page?').get(function(req, res){
	res.render('part1', {title: 'Marbles Part 1', bag: build_bag()});
});

// ============================================================================================================================
// Part 2
// ============================================================================================================================
router.route('/p2').get(function(req, res){
	res.render('part2', {title: 'Marbles Part 2', bag: build_bag()});
});
router.route('/p2/:page?').get(function(req, res){
	res.render('part2', {title: 'Marbles Part 2', bag: build_bag()});
});

// ============================================================================================================================
// CCPX-blockchain webservices
// ============================================================================================================================
router.post('/',function(req, res,next){
	res.json({ "message": 'Service got post requested' }); 
});
//webservices for seller about get latest record function
router.post('/getLatRec', function (req, res, next) {  
  	var sellerId = req.body.SELLER_ID;
  	var record_num = req.body.RECORD_NUM;
 	 //Do query
	 var result = [{"USER_A_ID":"krid",
		"SELLER_A_ID":"chinaair",
		"POINT_A":100,
		"USER_B_ID":"florence",
		"SELLER_B_ID":"KFC",
		"POINT_B":50,
		"EX_TIME":"2016-11-18"},
		{"USER_A_ID":"colin",
		"SELLER_A_ID":"chinaair",
		"POINT_A":100,
		"USER_B_ID":"lesley",
		"SELLER_B_ID":"KFC",
		"POINT_B":50,
		"EX_TIME":"2016-11-18"}];
	res.json({
		"respond":100,
		"content":result
	});
});
//webservice for seller about get Intelligent Analysis function
router.post('/getIAExRec',function(req,res,next){
	var sellerId = req.body.SELLER_ID;
	var startTime = req.body.START_TIME;
	var endTime = req.body.END_TIME;
	//Do query
	var result = [{"USER_A_ID":"5","SELLER_A_ID":"5","POINT_A":10,"USER_B_ID":"6","SELLER_B_ID":"6","POINT_B":110,"EX_TIME":"2016/11/07 00:10:00"},
		      {"USER_A_ID":"5","SELLER_A_ID":"6","POINT_A":20,"USER_B_ID":"6","SELLER_B_ID":"5","POINT_B":220,"EX_TIME":"2016/11/07 00:15:00"},
		      {"USER_A_ID":"5","SELLER_A_ID":"5","POINT_A":30,"USER_B_ID":"6","SELLER_B_ID":"9","POINT_B":330,"EX_TIME":"2016/11/07 00:20:00"},
		      {"USER_A_ID":"7","SELLER_A_ID":"5","POINT_A":40,"USER_B_ID":"6","SELLER_B_ID":"23","POINT_B":440,"EX_TIME":"2016/11/07 00:21:00"},
		      {"USER_A_ID":"8","SELLER_A_ID":"5","POINT_A":50,"USER_B_ID":"6","SELLER_B_ID":"19","POINT_B":550,"EX_TIME":"2016/11/07 00:26:00"},
		      {"USER_A_ID":"8","SELLER_A_ID":"5","POINT_A":60,"USER_B_ID":"6","SELLER_B_ID":"13","POINT_B":660,"EX_TIME":"2016/11/07 00:50:00"},
		      {"USER_A_ID":"8","SELLER_A_ID":"5","POINT_A":70,"USER_B_ID":"6","SELLER_B_ID":"8","POINT_B":770,"EX_TIME":"2016/11/07 00:00:00"}];
	res.json({
		"respond":100,
		"content":result
	});
});

//webservice for platform to record the transaction and return the reponse code 
/*router.post('/getTxInfo',function(req,res,next){
	var user_A_id = req.body.USER_A_ID;
	var seller_A_id = req.body.SELLER_A_ID;
	var point_A = req.body.POINT_A;
	var user_B_id = req.body.USER_B_ID;
	var seller_B_id = req.body.SELLER_B_ID;
	var point_B = req.body.POINT_B;
	var exchange_time = req.body.EX_TIME;
	// return the reponse code 
	res.json({
		"respond":100
	});
});*/


//webservice for platform to record the transaction and return the reponse code 
router.post('/getTxInfo',function(req,res,next){
	var user_A_id = req.body.USER_A_ID;
	var seller_A_id = req.body.SELLER_A_ID;
	var point_A = req.body.POINT_A;
	var user_B_id = req.body.USER_B_ID;
	var seller_B_id = req.body.SELLER_B_ID;
	var point_B = req.body.POINT_B;
	var exchange_time = req.body.EX_TIME;
	// return the reponse code 
	res.json({
		"respond":100
	});
});
router.post('/process',function (req,res,next){
	res.json({
		"a_id":req.body.USER_A_ID
	});
	
});


/*router.post('/storeTx',(function(req, res){
	res.json({ 
		"respond": 100,
		"content": req.param('arg') 
	}); 
});
router.post('/showTx',function(req, res){
	res.json({ 
		"respond": 300,
		"content": {
			"seller_ID":req.param('arg'),
			"TX":[
				{"foo":"bar"},
				{"foo":"bar"}
			]
		}
	}); 
});*/

module.exports = router;
