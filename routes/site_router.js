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
	res.json(result);
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
