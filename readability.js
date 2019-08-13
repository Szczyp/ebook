var fs = require('fs');
var JSDOM = require('jsdom').JSDOM;
var Readability = require('./readability/Readability.js');

var filename = process.argv[2];

var html = fs.readFileSync(filename, 'utf-8');
var doc = new JSDOM(html);
let reader = new Readability(doc.window.document);
let article = reader.parse();

console.log(article.title);
console.log(article.byline || "");
console.log(article.content);
