(function () {
/*! jQuery v1.7.1 jquery.com | jquery.org/license */
(function(a,b){function cy(a){return f.isWindow(a)?a:a.nodeType===9?a.defaultView||a.parentWindow:!1}function cv(a){if(!ck[a]){var b=c.body,d=f("<"+a+">").appendTo(b),e=d.css("display");d.remove();if(e==="none"||e===""){cl||(cl=c.createElement("iframe"),cl.frameBorder=cl.width=cl.height=0),b.appendChild(cl);if(!cm||!cl.createElement)cm=(cl.contentWindow||cl.contentDocument).document,cm.write((c.compatMode==="CSS1Compat"?"<!doctype html>":"")+"<html><body>"),cm.close();d=cm.createElement(a),cm.body.appendChild(d),e=f.css(d,"display"),b.removeChild(cl)}ck[a]=e}return ck[a]}function cu(a,b){var c={};f.each(cq.concat.apply([],cq.slice(0,b)),function(){c[this]=a});return c}function ct(){cr=b}function cs(){setTimeout(ct,0);return cr=f.now()}function cj(){try{return new a.ActiveXObject("Microsoft.XMLHTTP")}catch(b){}}function ci(){try{return new a.XMLHttpRequest}catch(b){}}function cc(a,c){a.dataFilter&&(c=a.dataFilter(c,a.dataType));var d=a.dataTypes,e={},g,h,i=d.length,j,k=d[0],l,m,n,o,p;for(g=1;g<i;g++){if(g===1)for(h in a.converters)typeof h=="string"&&(e[h.toLowerCase()]=a.converters[h]);l=k,k=d[g];if(k==="*")k=l;else if(l!=="*"&&l!==k){m=l+" "+k,n=e[m]||e["* "+k];if(!n){p=b;for(o in e){j=o.split(" ");if(j[0]===l||j[0]==="*"){p=e[j[1]+" "+k];if(p){o=e[o],o===!0?n=p:p===!0&&(n=o);break}}}}!n&&!p&&f.error("No conversion from "+m.replace(" "," to ")),n!==!0&&(c=n?n(c):p(o(c)))}}return c}function cb(a,c,d){var e=a.contents,f=a.dataTypes,g=a.responseFields,h,i,j,k;for(i in g)i in d&&(c[g[i]]=d[i]);while(f[0]==="*")f.shift(),h===b&&(h=a.mimeType||c.getResponseHeader("content-type"));if(h)for(i in e)if(e[i]&&e[i].test(h)){f.unshift(i);break}if(f[0]in d)j=f[0];else{for(i in d){if(!f[0]||a.converters[i+" "+f[0]]){j=i;break}k||(k=i)}j=j||k}if(j){j!==f[0]&&f.unshift(j);return d[j]}}function ca(a,b,c,d){if(f.isArray(b))f.each(b,function(b,e){c||bE.test(a)?d(a,e):ca(a+"["+(typeof e=="object"||f.isArray(e)?b:"")+"]",e,c,d)});else if(!c&&b!=null&&typeof b=="object")for(var e in b)ca(a+"["+e+"]",b[e],c,d);else d(a,b)}function b_(a,c){var d,e,g=f.ajaxSettings.flatOptions||{};for(d in c)c[d]!==b&&((g[d]?a:e||(e={}))[d]=c[d]);e&&f.extend(!0,a,e)}function b$(a,c,d,e,f,g){f=f||c.dataTypes[0],g=g||{},g[f]=!0;var h=a[f],i=0,j=h?h.length:0,k=a===bT,l;for(;i<j&&(k||!l);i++)l=h[i](c,d,e),typeof l=="string"&&(!k||g[l]?l=b:(c.dataTypes.unshift(l),l=b$(a,c,d,e,l,g)));(k||!l)&&!g["*"]&&(l=b$(a,c,d,e,"*",g));return l}function bZ(a){return function(b,c){typeof b!="string"&&(c=b,b="*");if(f.isFunction(c)){var d=b.toLowerCase().split(bP),e=0,g=d.length,h,i,j;for(;e<g;e++)h=d[e],j=/^\+/.test(h),j&&(h=h.substr(1)||"*"),i=a[h]=a[h]||[],i[j?"unshift":"push"](c)}}}function bC(a,b,c){var d=b==="width"?a.offsetWidth:a.offsetHeight,e=b==="width"?bx:by,g=0,h=e.length;if(d>0){if(c!=="border")for(;g<h;g++)c||(d-=parseFloat(f.css(a,"padding"+e[g]))||0),c==="margin"?d+=parseFloat(f.css(a,c+e[g]))||0:d-=parseFloat(f.css(a,"border"+e[g]+"Width"))||0;return d+"px"}d=bz(a,b,b);if(d<0||d==null)d=a.style[b]||0;d=parseFloat(d)||0;if(c)for(;g<h;g++)d+=parseFloat(f.css(a,"padding"+e[g]))||0,c!=="padding"&&(d+=parseFloat(f.css(a,"border"+e[g]+"Width"))||0),c==="margin"&&(d+=parseFloat(f.css(a,c+e[g]))||0);return d+"px"}function bp(a,b){b.src?f.ajax({url:b.src,async:!1,dataType:"script"}):f.globalEval((b.text||b.textContent||b.innerHTML||"").replace(bf,"/*$0*/")),b.parentNode&&b.parentNode.removeChild(b)}function bo(a){var b=c.createElement("div");bh.appendChild(b),b.innerHTML=a.outerHTML;return b.firstChild}function bn(a){var b=(a.nodeName||"").toLowerCase();b==="input"?bm(a):b!=="script"&&typeof a.getElementsByTagName!="undefined"&&f.grep(a.getElementsByTagName("input"),bm)}function bm(a){if(a.type==="checkbox"||a.type==="radio")a.defaultChecked=a.checked}function bl(a){return typeof a.getElementsByTagName!="undefined"?a.getElementsByTagName("*"):typeof a.querySelectorAll!="undefined"?a.querySelectorAll("*"):[]}function bk(a,b){var c;if(b.nodeType===1){b.clearAttributes&&b.clearAttributes(),b.mergeAttributes&&b.mergeAttributes(a),c=b.nodeName.toLowerCase();if(c==="object")b.outerHTML=a.outerHTML;else if(c!=="input"||a.type!=="checkbox"&&a.type!=="radio"){if(c==="option")b.selected=a.defaultSelected;else if(c==="input"||c==="textarea")b.defaultValue=a.defaultValue}else a.checked&&(b.defaultChecked=b.checked=a.checked),b.value!==a.value&&(b.value=a.value);b.removeAttribute(f.expando)}}function bj(a,b){if(b.nodeType===1&&!!f.hasData(a)){var c,d,e,g=f._data(a),h=f._data(b,g),i=g.events;if(i){delete h.handle,h.events={};for(c in i)for(d=0,e=i[c].length;d<e;d++)f.event.add(b,c+(i[c][d].namespace?".":"")+i[c][d].namespace,i[c][d],i[c][d].data)}h.data&&(h.data=f.extend({},h.data))}}function bi(a,b){return f.nodeName(a,"table")?a.getElementsByTagName("tbody")[0]||a.appendChild(a.ownerDocument.createElement("tbody")):a}function U(a){var b=V.split("|"),c=a.createDocumentFragment();if(c.createElement)while(b.length)c.createElement(b.pop());return c}function T(a,b,c){b=b||0;if(f.isFunction(b))return f.grep(a,function(a,d){var e=!!b.call(a,d,a);return e===c});if(b.nodeType)return f.grep(a,function(a,d){return a===b===c});if(typeof b=="string"){var d=f.grep(a,function(a){return a.nodeType===1});if(O.test(b))return f.filter(b,d,!c);b=f.filter(b,d)}return f.grep(a,function(a,d){return f.inArray(a,b)>=0===c})}function S(a){return!a||!a.parentNode||a.parentNode.nodeType===11}function K(){return!0}function J(){return!1}function n(a,b,c){var d=b+"defer",e=b+"queue",g=b+"mark",h=f._data(a,d);h&&(c==="queue"||!f._data(a,e))&&(c==="mark"||!f._data(a,g))&&setTimeout(function(){!f._data(a,e)&&!f._data(a,g)&&(f.removeData(a,d,!0),h.fire())},0)}function m(a){for(var b in a){if(b==="data"&&f.isEmptyObject(a[b]))continue;if(b!=="toJSON")return!1}return!0}function l(a,c,d){if(d===b&&a.nodeType===1){var e="data-"+c.replace(k,"-$1").toLowerCase();d=a.getAttribute(e);if(typeof d=="string"){try{d=d==="true"?!0:d==="false"?!1:d==="null"?null:f.isNumeric(d)?parseFloat(d):j.test(d)?f.parseJSON(d):d}catch(g){}f.data(a,c,d)}else d=b}return d}function h(a){var b=g[a]={},c,d;a=a.split(/\s+/);for(c=0,d=a.length;c<d;c++)b[a[c]]=!0;return b}var c=a.document,d=a.navigator,e=a.location,f=function(){function J(){if(!e.isReady){try{c.documentElement.doScroll("left")}catch(a){setTimeout(J,1);return}e.ready()}}var e=function(a,b){return new e.fn.init(a,b,h)},f=a.jQuery,g=a.$,h,i=/^(?:[^#<]*(<[\w\W]+>)[^>]*$|#([\w\-]*)$)/,j=/\S/,k=/^\s+/,l=/\s+$/,m=/^<(\w+)\s*\/?>(?:<\/\1>)?$/,n=/^[\],:{}\s]*$/,o=/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,p=/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,q=/(?:^|:|,)(?:\s*\[)+/g,r=/(webkit)[ \/]([\w.]+)/,s=/(opera)(?:.*version)?[ \/]([\w.]+)/,t=/(msie) ([\w.]+)/,u=/(mozilla)(?:.*? rv:([\w.]+))?/,v=/-([a-z]|[0-9])/ig,w=/^-ms-/,x=function(a,b){return(b+"").toUpperCase()},y=d.userAgent,z,A,B,C=Object.prototype.toString,D=Object.prototype.hasOwnProperty,E=Array.prototype.push,F=Array.prototype.slice,G=String.prototype.trim,H=Array.prototype.indexOf,I={};e.fn=e.prototype={constructor:e,init:function(a,d,f){var g,h,j,k;if(!a)return this;if(a.nodeType){this.context=this[0]=a,this.length=1;return this}if(a==="body"&&!d&&c.body){this.context=c,this[0]=c.body,this.selector=a,this.length=1;return this}if(typeof a=="string"){a.charAt(0)!=="<"||a.charAt(a.length-1)!==">"||a.length<3?g=i.exec(a):g=[null,a,null];if(g&&(g[1]||!d)){if(g[1]){d=d instanceof e?d[0]:d,k=d?d.ownerDocument||d:c,j=m.exec(a),j?e.isPlainObject(d)?(a=[c.createElement(j[1])],e.fn.attr.call(a,d,!0)):a=[k.createElement(j[1])]:(j=e.buildFragment([g[1]],[k]),a=(j.cacheable?e.clone(j.fragment):j.fragment).childNodes);return e.merge(this,a)}h=c.getElementById(g[2]);if(h&&h.parentNode){if(h.id!==g[2])return f.find(a);this.length=1,this[0]=h}this.context=c,this.selector=a;return this}return!d||d.jquery?(d||f).find(a):this.constructor(d).find(a)}if(e.isFunction(a))return f.ready(a);a.selector!==b&&(this.selector=a.selector,this.context=a.context);return e.makeArray(a,this)},selector:"",jquery:"1.7.1",length:0,size:function(){return this.length},toArray:function(){return F.call(this,0)},get:function(a){return a==null?this.toArray():a<0?this[this.length+a]:this[a]},pushStack:function(a,b,c){var d=this.constructor();e.isArray(a)?E.apply(d,a):e.merge(d,a),d.prevObject=this,d.context=this.context,b==="find"?d.selector=this.selector+(this.selector?" ":"")+c:b&&(d.selector=this.selector+"."+b+"("+c+")");return d},each:function(a,b){return e.each(this,a,b)},ready:function(a){e.bindReady(),A.add(a);return this},eq:function(a){a=+a;return a===-1?this.slice(a):this.slice(a,a+1)},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},slice:function(){return this.pushStack(F.apply(this,arguments),"slice",F.call(arguments).join(","))},map:function(a){return this.pushStack(e.map(this,function(b,c){return a.call(b,c,b)}))},end:function(){return this.prevObject||this.constructor(null)},push:E,sort:[].sort,splice:[].splice},e.fn.init.prototype=e.fn,e.extend=e.fn.extend=function(){var a,c,d,f,g,h,i=arguments[0]||{},j=1,k=arguments.length,l=!1;typeof i=="boolean"&&(l=i,i=arguments[1]||{},j=2),typeof i!="object"&&!e.isFunction(i)&&(i={}),k===j&&(i=this,--j);for(;j<k;j++)if((a=arguments[j])!=null)for(c in a){d=i[c],f=a[c];if(i===f)continue;l&&f&&(e.isPlainObject(f)||(g=e.isArray(f)))?(g?(g=!1,h=d&&e.isArray(d)?d:[]):h=d&&e.isPlainObject(d)?d:{},i[c]=e.extend(l,h,f)):f!==b&&(i[c]=f)}return i},e.extend({noConflict:function(b){a.$===e&&(a.$=g),b&&a.jQuery===e&&(a.jQuery=f);return e},isReady:!1,readyWait:1,holdReady:function(a){a?e.readyWait++:e.ready(!0)},ready:function(a){if(a===!0&&!--e.readyWait||a!==!0&&!e.isReady){if(!c.body)return setTimeout(e.ready,1);e.isReady=!0;if(a!==!0&&--e.readyWait>0)return;A.fireWith(c,[e]),e.fn.trigger&&e(c).trigger("ready").off("ready")}},bindReady:function(){if(!A){A=e.Callbacks("once memory");if(c.readyState==="complete")return setTimeout(e.ready,1);if(c.addEventListener)c.addEventListener("DOMContentLoaded",B,!1),a.addEventListener("load",e.ready,!1);else if(c.attachEvent){c.attachEvent("onreadystatechange",B),a.attachEvent("onload",e.ready);var b=!1;try{b=a.frameElement==null}catch(d){}c.documentElement.doScroll&&b&&J()}}},isFunction:function(a){return e.type(a)==="function"},isArray:Array.isArray||function(a){return e.type(a)==="array"},isWindow:function(a){return a&&typeof a=="object"&&"setInterval"in a},isNumeric:function(a){return!isNaN(parseFloat(a))&&isFinite(a)},type:function(a){return a==null?String(a):I[C.call(a)]||"object"},isPlainObject:function(a){if(!a||e.type(a)!=="object"||a.nodeType||e.isWindow(a))return!1;try{if(a.constructor&&!D.call(a,"constructor")&&!D.call(a.constructor.prototype,"isPrototypeOf"))return!1}catch(c){return!1}var d;for(d in a);return d===b||D.call(a,d)},isEmptyObject:function(a){for(var b in a)return!1;return!0},error:function(a){throw new Error(a)},parseJSON:function(b){if(typeof b!="string"||!b)return null;b=e.trim(b);if(a.JSON&&a.JSON.parse)return a.JSON.parse(b);if(n.test(b.replace(o,"@").replace(p,"]").replace(q,"")))return(new Function("return "+b))();e.error("Invalid JSON: "+b)},parseXML:function(c){var d,f;try{a.DOMParser?(f=new DOMParser,d=f.parseFromString(c,"text/xml")):(d=new ActiveXObject("Microsoft.XMLDOM"),d.async="false",d.loadXML(c))}catch(g){d=b}(!d||!d.documentElement||d.getElementsByTagName("parsererror").length)&&e.error("Invalid XML: "+c);return d},noop:function(){},globalEval:function(b){b&&j.test(b)&&(a.execScript||function(b){a.eval.call(a,b)})(b)},camelCase:function(a){return a.replace(w,"ms-").replace(v,x)},nodeName:function(a,b){return a.nodeName&&a.nodeName.toUpperCase()===b.toUpperCase()},each:function(a,c,d){var f,g=0,h=a.length,i=h===b||e.isFunction(a);if(d){if(i){for(f in a)if(c.apply(a[f],d)===!1)break}else for(;g<h;)if(c.apply(a[g++],d)===!1)break}else if(i){for(f in a)if(c.call(a[f],f,a[f])===!1)break}else for(;g<h;)if(c.call(a[g],g,a[g++])===!1)break;return a},trim:G?function(a){return a==null?"":G.call(a)}:function(a){return a==null?"":(a+"").replace(k,"").replace(l,"")},makeArray:function(a,b){var c=b||[];if(a!=null){var d=e.type(a);a.length==null||d==="string"||d==="function"||d==="regexp"||e.isWindow(a)?E.call(c,a):e.merge(c,a)}return c},inArray:function(a,b,c){var d;if(b){if(H)return H.call(b,a,c);d=b.length,c=c?c<0?Math.max(0,d+c):c:0;for(;c<d;c++)if(c in b&&b[c]===a)return c}return-1},merge:function(a,c){var d=a.length,e=0;if(typeof c.length=="number")for(var f=c.length;e<f;e++)a[d++]=c[e];else while(c[e]!==b)a[d++]=c[e++];a.length=d;return a},grep:function(a,b,c){var d=[],e;c=!!c;for(var f=0,g=a.length;f<g;f++)e=!!b(a[f],f),c!==e&&d.push(a[f]);return d},map:function(a,c,d){var f,g,h=[],i=0,j=a.length,k=a instanceof e||j!==b&&typeof j=="number"&&(j>0&&a[0]&&a[j-1]||j===0||e.isArray(a));if(k)for(;i<j;i++)f=c(a[i],i,d),f!=null&&(h[h.length]=f);else for(g in a)f=c(a[g],g,d),f!=null&&(h[h.length]=f);return h.concat.apply([],h)},guid:1,proxy:function(a,c){if(typeof c=="string"){var d=a[c];c=a,a=d}if(!e.isFunction(a))return b;var f=F.call(arguments,2),g=function(){return a.apply(c,f.concat(F.call(arguments)))};g.guid=a.guid=a.guid||g.guid||e.guid++;return g},access:function(a,c,d,f,g,h){var i=a.length;if(typeof c=="object"){for(var j in c)e.access(a,j,c[j],f,g,d);return a}if(d!==b){f=!h&&f&&e.isFunction(d);for(var k=0;k<i;k++)g(a[k],c,f?d.call(a[k],k,g(a[k],c)):d,h);return a}return i?g(a[0],c):b},now:function(){return(new Date).getTime()},uaMatch:function(a){a=a.toLowerCase();var b=r.exec(a)||s.exec(a)||t.exec(a)||a.indexOf("compatible")<0&&u.exec(a)||[];return{browser:b[1]||"",version:b[2]||"0"}},sub:function(){function a(b,c){return new a.fn.init(b,c)}e.extend(!0,a,this),a.superclass=this,a.fn=a.prototype=this(),a.fn.constructor=a,a.sub=this.sub,a.fn.init=function(d,f){f&&f instanceof e&&!(f instanceof a)&&(f=a(f));return e.fn.init.call(this,d,f,b)},a.fn.init.prototype=a.fn;var b=a(c);return a},browser:{}}),e.each("Boolean Number String Function Array Date RegExp Object".split(" "),function(a,b){I["[object "+b+"]"]=b.toLowerCase()}),z=e.uaMatch(y),z.browser&&(e.browser[z.browser]=!0,e.browser.version=z.version),e.browser.webkit&&(e.browser.safari=!0),j.test(" ")&&(k=/^[\s\xA0]+/,l=/[\s\xA0]+$/),h=e(c),c.addEventListener?B=function(){c.removeEventListener("DOMContentLoaded",B,!1),e.ready()}:c.attachEvent&&(B=function(){c.readyState==="complete"&&(c.detachEvent("onreadystatechange",B),e.ready())});return e}(),g={};f.Callbacks=function(a){a=a?g[a]||h(a):{};var c=[],d=[],e,i,j,k,l,m=function(b){var d,e,g,h,i;for(d=0,e=b.length;d<e;d++)g=b[d],h=f.type(g),h==="array"?m(g):h==="function"&&(!a.unique||!o.has(g))&&c.push(g)},n=function(b,f){f=f||[],e=!a.memory||[b,f],i=!0,l=j||0,j=0,k=c.length;for(;c&&l<k;l++)if(c[l].apply(b,f)===!1&&a.stopOnFalse){e=!0;break}i=!1,c&&(a.once?e===!0?o.disable():c=[]:d&&d.length&&(e=d.shift(),o.fireWith(e[0],e[1])))},o={add:function(){if(c){var a=c.length;m(arguments),i?k=c.length:e&&e!==!0&&(j=a,n(e[0],e[1]))}return this},remove:function(){if(c){var b=arguments,d=0,e=b.length;for(;d<e;d++)for(var f=0;f<c.length;f++)if(b[d]===c[f]){i&&f<=k&&(k--,f<=l&&l--),c.splice(f--,1);if(a.unique)break}}return this},has:function(a){if(c){var b=0,d=c.length;for(;b<d;b++)if(a===c[b])return!0}return!1},empty:function(){c=[];return this},disable:function(){c=d=e=b;return this},disabled:function(){return!c},lock:function(){d=b,(!e||e===!0)&&o.disable();return this},locked:function(){return!d},fireWith:function(b,c){d&&(i?a.once||d.push([b,c]):(!a.once||!e)&&n(b,c));return this},fire:function(){o.fireWith(this,arguments);return this},fired:function(){return!!e}};return o};var i=[].slice;f.extend({Deferred:function(a){var b=f.Callbacks("once memory"),c=f.Callbacks("once memory"),d=f.Callbacks("memory"),e="pending",g={resolve:b,reject:c,notify:d},h={done:b.add,fail:c.add,progress:d.add,state:function(){return e},isResolved:b.fired,isRejected:c.fired,then:function(a,b,c){i.done(a).fail(b).progress(c);return this},always:function(){i.done.apply(i,arguments).fail.apply(i,arguments);return this},pipe:function(a,b,c){return f.Deferred(function(d){f.each({done:[a,"resolve"],fail:[b,"reject"],progress:[c,"notify"]},function(a,b){var c=b[0],e=b[1],g;f.isFunction(c)?i[a](function(){g=c.apply(this,arguments),g&&f.isFunction(g.promise)?g.promise().then(d.resolve,d.reject,d.notify):d[e+"With"](this===i?d:this,[g])}):i[a](d[e])})}).promise()},promise:function(a){if(a==null)a=h;else for(var b in h)a[b]=h[b];return a}},i=h.promise({}),j;for(j in g)i[j]=g[j].fire,i[j+"With"]=g[j].fireWith;i.done(function(){e="resolved"},c.disable,d.lock).fail(function(){e="rejected"},b.disable,d.lock),a&&a.call(i,i);return i},when:function(a){function m(a){return function(b){e[a]=arguments.length>1?i.call(arguments,0):b,j.notifyWith(k,e)}}function l(a){return function(c){b[a]=arguments.length>1?i.call(arguments,0):c,--g||j.resolveWith(j,b)}}var b=i.call(arguments,0),c=0,d=b.length,e=Array(d),g=d,h=d,j=d<=1&&a&&f.isFunction(a.promise)?a:f.Deferred(),k=j.promise();if(d>1){for(;c<d;c++)b[c]&&b[c].promise&&f.isFunction(b[c].promise)?b[c].promise().then(l(c),j.reject,m(c)):--g;g||j.resolveWith(j,b)}else j!==a&&j.resolveWith(j,d?[a]:[]);return k}}),f.support=function(){var b,d,e,g,h,i,j,k,l,m,n,o,p,q=c.createElement("div"),r=c.documentElement;q.setAttribute("className","t"),q.innerHTML="   <link/><table></table><a href='/a' style='top:1px;float:left;opacity:.55;'>a</a><input type='checkbox'/>",d=q.getElementsByTagName("*"),e=q.getElementsByTagName("a")[0];if(!d||!d.length||!e)return{};g=c.createElement("select"),h=g.appendChild(c.createElement("option")),i=q.getElementsByTagName("input")[0],b={leadingWhitespace:q.firstChild.nodeType===3,tbody:!q.getElementsByTagName("tbody").length,htmlSerialize:!!q.getElementsByTagName("link").length,style:/top/.test(e.getAttribute("style")),hrefNormalized:e.getAttribute("href")==="/a",opacity:/^0.55/.test(e.style.opacity),cssFloat:!!e.style.cssFloat,checkOn:i.value==="on",optSelected:h.selected,getSetAttribute:q.className!=="t",enctype:!!c.createElement("form").enctype,html5Clone:c.createElement("nav").cloneNode(!0).outerHTML!=="<:nav></:nav>",submitBubbles:!0,changeBubbles:!0,focusinBubbles:!1,deleteExpando:!0,noCloneEvent:!0,inlineBlockNeedsLayout:!1,shrinkWrapBlocks:!1,reliableMarginRight:!0},i.checked=!0,b.noCloneChecked=i.cloneNode(!0).checked,g.disabled=!0,b.optDisabled=!h.disabled;try{delete q.test}catch(s){b.deleteExpando=!1}!q.addEventListener&&q.attachEvent&&q.fireEvent&&(q.attachEvent("onclick",function(){b.noCloneEvent=!1}),q.cloneNode(!0).fireEvent("onclick")),i=c.createElement("input"),i.value="t",i.setAttribute("type","radio"),b.radioValue=i.value==="t",i.setAttribute("checked","checked"),q.appendChild(i),k=c.createDocumentFragment(),k.appendChild(q.lastChild),b.checkClone=k.cloneNode(!0).cloneNode(!0).lastChild.checked,b.appendChecked=i.checked,k.removeChild(i),k.appendChild(q),q.innerHTML="",a.getComputedStyle&&(j=c.createElement("div"),j.style.width="0",j.style.marginRight="0",q.style.width="2px",q.appendChild(j),b.reliableMarginRight=(parseInt((a.getComputedStyle(j,null)||{marginRight:0}).marginRight,10)||0)===0);if(q.attachEvent)for(o in{submit:1,change:1,focusin:1})n="on"+o,p=n in q,p||(q.setAttribute(n,"return;"),p=typeof q[n]=="function"),b[o+"Bubbles"]=p;k.removeChild(q),k=g=h=j=q=i=null,f(function(){var a,d,e,g,h,i,j,k,m,n,o,r=c.getElementsByTagName("body")[0];!r||(j=1,k="position:absolute;top:0;left:0;width:1px;height:1px;margin:0;",m="visibility:hidden;border:0;",n="style='"+k+"border:5px solid #000;padding:0;'",o="<div "+n+"><div></div></div>"+"<table "+n+" cellpadding='0' cellspacing='0'>"+"<tr><td></td></tr></table>",a=c.createElement("div"),a.style.cssText=m+"width:0;height:0;position:static;top:0;margin-top:"+j+"px",r.insertBefore(a,r.firstChild),q=c.createElement("div"),a.appendChild(q),q.innerHTML="<table><tr><td style='padding:0;border:0;display:none'></td><td>t</td></tr></table>",l=q.getElementsByTagName("td"),p=l[0].offsetHeight===0,l[0].style.display="",l[1].style.display="none",b.reliableHiddenOffsets=p&&l[0].offsetHeight===0,q.innerHTML="",q.style.width=q.style.paddingLeft="1px",f.boxModel=b.boxModel=q.offsetWidth===2,typeof q.style.zoom!="undefined"&&(q.style.display="inline",q.style.zoom=1,b.inlineBlockNeedsLayout=q.offsetWidth===2,q.style.display="",q.innerHTML="<div style='width:4px;'></div>",b.shrinkWrapBlocks=q.offsetWidth!==2),q.style.cssText=k+m,q.innerHTML=o,d=q.firstChild,e=d.firstChild,h=d.nextSibling.firstChild.firstChild,i={doesNotAddBorder:e.offsetTop!==5,doesAddBorderForTableAndCells:h.offsetTop===5},e.style.position="fixed",e.style.top="20px",i.fixedPosition=e.offsetTop===20||e.offsetTop===15,e.style.position=e.style.top="",d.style.overflow="hidden",d.style.position="relative",i.subtractsBorderForOverflowNotVisible=e.offsetTop===-5,i.doesNotIncludeMarginInBodyOffset=r.offsetTop!==j,r.removeChild(a),q=a=null,f.extend(b,i))});return b}();var j=/^(?:\{.*\}|\[.*\])$/,k=/([A-Z])/g;f.extend({cache:{},uuid:0,expando:"jQuery"+(f.fn.jquery+Math.random()).replace(/\D/g,""),noData:{embed:!0,object:"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000",applet:!0},hasData:function(a){a=a.nodeType?f.cache[a[f.expando]]:a[f.expando];return!!a&&!m(a)},data:function(a,c,d,e){if(!!f.acceptData(a)){var g,h,i,j=f.expando,k=typeof c=="string",l=a.nodeType,m=l?f.cache:a,n=l?a[j]:a[j]&&j,o=c==="events";if((!n||!m[n]||!o&&!e&&!m[n].data)&&k&&d===b)return;n||(l?a[j]=n=++f.uuid:n=j),m[n]||(m[n]={},l||(m[n].toJSON=f.noop));if(typeof c=="object"||typeof c=="function")e?m[n]=f.extend(m[n],c):m[n].data=f.extend(m[n].data,c);g=h=m[n],e||(h.data||(h.data={}),h=h.data),d!==b&&(h[f.camelCase(c)]=d);if(o&&!h[c])return g.events;k?(i=h[c],i==null&&(i=h[f.camelCase(c)])):i=h;return i}},removeData:function(a,b,c){if(!!f.acceptData(a)){var d,e,g,h=f.expando,i=a.nodeType,j=i?f.cache:a,k=i?a[h]:h;if(!j[k])return;if(b){d=c?j[k]:j[k].data;if(d){f.isArray(b)||(b in d?b=[b]:(b=f.camelCase(b),b in d?b=[b]:b=b.split(" ")));for(e=0,g=b.length;e<g;e++)delete d[b[e]];if(!(c?m:f.isEmptyObject)(d))return}}if(!c){delete j[k].data;if(!m(j[k]))return}f.support.deleteExpando||!j.setInterval?delete j[k]:j[k]=null,i&&(f.support.deleteExpando?delete a[h]:a.removeAttribute?a.removeAttribute(h):a[h]=null)}},_data:function(a,b,c){return f.data(a,b,c,!0)},acceptData:function(a){if(a.nodeName){var b=f.noData[a.nodeName.toLowerCase()];if(b)return b!==!0&&a.getAttribute("classid")===b}return!0}}),f.fn.extend({data:function(a,c){var d,e,g,h=null;if(typeof a=="undefined"){if(this.length){h=f.data(this[0]);if(this[0].nodeType===1&&!f._data(this[0],"parsedAttrs")){e=this[0].attributes;for(var i=0,j=e.length;i<j;i++)g=e[i].name,g.indexOf("data-")===0&&(g=f.camelCase(g.substring(5)),l(this[0],g,h[g]));f._data(this[0],"parsedAttrs",!0)}}return h}if(typeof a=="object")return this.each(function(){f.data(this,a)});d=a.split("."),d[1]=d[1]?"."+d[1]:"";if(c===b){h=this.triggerHandler("getData"+d[1]+"!",[d[0]]),h===b&&this.length&&(h=f.data(this[0],a),h=l(this[0],a,h));return h===b&&d[1]?this.data(d[0]):h}return this.each(function(){var b=f(this),e=[d[0],c];b.triggerHandler("setData"+d[1]+"!",e),f.data(this,a,c),b.triggerHandler("changeData"+d[1]+"!",e)})},removeData:function(a){return this.each(function(){f.removeData(this,a)})}}),f.extend({_mark:function(a,b){a&&(b=(b||"fx")+"mark",f._data(a,b,(f._data(a,b)||0)+1))},_unmark:function(a,b,c){a!==!0&&(c=b,b=a,a=!1);if(b){c=c||"fx";var d=c+"mark",e=a?0:(f._data(b,d)||1)-1;e?f._data(b,d,e):(f.removeData(b,d,!0),n(b,c,"mark"))}},queue:function(a,b,c){var d;if(a){b=(b||"fx")+"queue",d=f._data(a,b),c&&(!d||f.isArray(c)?d=f._data(a,b,f.makeArray(c)):d.push(c));return d||[]}},dequeue:function(a,b){b=b||"fx";var c=f.queue(a,b),d=c.shift(),e={};d==="inprogress"&&(d=c.shift()),d&&(b==="fx"&&c.unshift("inprogress"),f._data(a,b+".run",e),d.call(a,function(){f.dequeue(a,b)},e)),c.length||(f.removeData(a,b+"queue "+b+".run",!0),n(a,b,"queue"))}}),f.fn.extend({queue:function(a,c){typeof a!="string"&&(c=a,a="fx");if(c===b)return f.queue(this[0],a);return this.each(function(){var b=f.queue(this,a,c);a==="fx"&&b[0]!=="inprogress"&&f.dequeue(this,a)})},dequeue:function(a){return this.each(function(){f.dequeue(this,a)})},delay:function(a,b){a=f.fx?f.fx.speeds[a]||a:a,b=b||"fx";return this.queue(b,function(b,c){var d=setTimeout(b,a);c.stop=function(){clearTimeout(d)}})},clearQueue:function(a){return this.queue(a||"fx",[])},promise:function(a,c){function m(){--h||d.resolveWith(e,[e])}typeof a!="string"&&(c=a,a=b),a=a||"fx";var d=f.Deferred(),e=this,g=e.length,h=1,i=a+"defer",j=a+"queue",k=a+"mark",l;while(g--)if(l=f.data(e[g],i,b,!0)||(f.data(e[g],j,b,!0)||f.data(e[g],k,b,!0))&&f.data(e[g],i,f.Callbacks("once memory"),!0))h++,l.add(m);m();return d.promise()}});var o=/[\n\t\r]/g,p=/\s+/,q=/\r/g,r=/^(?:button|input)$/i,s=/^(?:button|input|object|select|textarea)$/i,t=/^a(?:rea)?$/i,u=/^(?:autofocus|autoplay|async|checked|controls|defer|disabled|hidden|loop|multiple|open|readonly|required|scoped|selected)$/i,v=f.support.getSetAttribute,w,x,y;f.fn.extend({attr:function(a,b){return f.access(this,a,b,!0,f.attr)},removeAttr:function(a){return this.each(function(){f.removeAttr(this,a)})},prop:function(a,b){return f.access(this,a,b,!0,f.prop)},removeProp:function(a){a=f.propFix[a]||a;return this.each(function(){try{this[a]=b,delete this[a]}catch(c){}})},addClass:function(a){var b,c,d,e,g,h,i;if(f.isFunction(a))return this.each(function(b){f(this).addClass(a.call(this,b,this.className))});if(a&&typeof a=="string"){b=a.split(p);for(c=0,d=this.length;c<d;c++){e=this[c];if(e.nodeType===1)if(!e.className&&b.length===1)e.className=a;else{g=" "+e.className+" ";for(h=0,i=b.length;h<i;h++)~g.indexOf(" "+b[h]+" ")||(g+=b[h]+" ");e.className=f.trim(g)}}}return this},removeClass:function(a){var c,d,e,g,h,i,j;if(f.isFunction(a))return this.each(function(b){f(this).removeClass(a.call(this,b,this.className))});if(a&&typeof a=="string"||a===b){c=(a||"").split(p);for(d=0,e=this.length;d<e;d++){g=this[d];if(g.nodeType===1&&g.className)if(a){h=(" "+g.className+" ").replace(o," ");for(i=0,j=c.length;i<j;i++)h=h.replace(" "+c[i]+" "," ");g.className=f.trim(h)}else g.className=""}}return this},toggleClass:function(a,b){var c=typeof a,d=typeof b=="boolean";if(f.isFunction(a))return this.each(function(c){f(this).toggleClass(a.call(this,c,this.className,b),b)});return this.each(function(){if(c==="string"){var e,g=0,h=f(this),i=b,j=a.split(p);while(e=j[g++])i=d?i:!h.hasClass(e),h[i?"addClass":"removeClass"](e)}else if(c==="undefined"||c==="boolean")this.className&&f._data(this,"__className__",this.className),this.className=this.className||a===!1?"":f._data(this,"__className__")||""})},hasClass:function(a){var b=" "+a+" ",c=0,d=this.length;for(;c<d;c++)if(this[c].nodeType===1&&(" "+this[c].className+" ").replace(o," ").indexOf(b)>-1)return!0;return!1},val:function(a){var c,d,e,g=this[0];{if(!!arguments.length){e=f.isFunction(a);return this.each(function(d){var g=f(this),h;if(this.nodeType===1){e?h=a.call(this,d,g.val()):h=a,h==null?h="":typeof h=="number"?h+="":f.isArray(h)&&(h=f.map(h,function(a){return a==null?"":a+""})),c=f.valHooks[this.nodeName.toLowerCase()]||f.valHooks[this.type];if(!c||!("set"in c)||c.set(this,h,"value")===b)this.value=h}})}if(g){c=f.valHooks[g.nodeName.toLowerCase()]||f.valHooks[g.type];if(c&&"get"in c&&(d=c.get(g,"value"))!==b)return d;d=g.value;return typeof d=="string"?d.replace(q,""):d==null?"":d}}}}),f.extend({valHooks:{option:{get:function(a){var b=a.attributes.value;return!b||b.specified?a.value:a.text}},select:{get:function(a){var b,c,d,e,g=a.selectedIndex,h=[],i=a.options,j=a.type==="select-one";if(g<0)return null;c=j?g:0,d=j?g+1:i.length;for(;c<d;c++){e=i[c];if(e.selected&&(f.support.optDisabled?!e.disabled:e.getAttribute("disabled")===null)&&(!e.parentNode.disabled||!f.nodeName(e.parentNode,"optgroup"))){b=f(e).val();if(j)return b;h.push(b)}}if(j&&!h.length&&i.length)return f(i[g]).val();return h},set:function(a,b){var c=f.makeArray(b);f(a).find("option").each(function(){this.selected=f.inArray(f(this).val(),c)>=0}),c.length||(a.selectedIndex=-1);return c}}},attrFn:{val:!0,css:!0,html:!0,text:!0,data:!0,width:!0,height:!0,offset:!0},attr:function(a,c,d,e){var g,h,i,j=a.nodeType;if(!!a&&j!==3&&j!==8&&j!==2){if(e&&c in f.attrFn)return f(a)[c](d);if(typeof a.getAttribute=="undefined")return f.prop(a,c,d);i=j!==1||!f.isXMLDoc(a),i&&(c=c.toLowerCase(),h=f.attrHooks[c]||(u.test(c)?x:w));if(d!==b){if(d===null){f.removeAttr(a,c);return}if(h&&"set"in h&&i&&(g=h.set(a,d,c))!==b)return g;a.setAttribute(c,""+d);return d}if(h&&"get"in h&&i&&(g=h.get(a,c))!==null)return g;g=a.getAttribute(c);return g===null?b:g}},removeAttr:function(a,b){var c,d,e,g,h=0;if(b&&a.nodeType===1){d=b.toLowerCase().split(p),g=d.length;for(;h<g;h++)e=d[h],e&&(c=f.propFix[e]||e,f.attr(a,e,""),a.removeAttribute(v?e:c),u.test(e)&&c in a&&(a[c]=!1))}},attrHooks:{type:{set:function(a,b){if(r.test(a.nodeName)&&a.parentNode)f.error("type property can't be changed");else if(!f.support.radioValue&&b==="radio"&&f.nodeName(a,"input")){var c=a.value;a.setAttribute("type",b),c&&(a.value=c);return b}}},value:{get:function(a,b){if(w&&f.nodeName(a,"button"))return w.get(a,b);return b in a?a.value:null},set:function(a,b,c){if(w&&f.nodeName(a,"button"))return w.set(a,b,c);a.value=b}}},propFix:{tabindex:"tabIndex",readonly:"readOnly","for":"htmlFor","class":"className",maxlength:"maxLength",cellspacing:"cellSpacing",cellpadding:"cellPadding",rowspan:"rowSpan",colspan:"colSpan",usemap:"useMap",frameborder:"frameBorder",contenteditable:"contentEditable"},prop:function(a,c,d){var e,g,h,i=a.nodeType;if(!!a&&i!==3&&i!==8&&i!==2){h=i!==1||!f.isXMLDoc(a),h&&(c=f.propFix[c]||c,g=f.propHooks[c]);return d!==b?g&&"set"in g&&(e=g.set(a,d,c))!==b?e:a[c]=d:g&&"get"in g&&(e=g.get(a,c))!==null?e:a[c]}},propHooks:{tabIndex:{get:function(a){var c=a.getAttributeNode("tabindex");return c&&c.specified?parseInt(c.value,10):s.test(a.nodeName)||t.test(a.nodeName)&&a.href?0:b}}}}),f.attrHooks.tabindex=f.propHooks.tabIndex,x={get:function(a,c){var d,e=f.prop(a,c);return e===!0||typeof e!="boolean"&&(d=a.getAttributeNode(c))&&d.nodeValue!==!1?c.toLowerCase():b},set:function(a,b,c){var d;b===!1?f.removeAttr(a,c):(d=f.propFix[c]||c,d in a&&(a[d]=!0),a.setAttribute(c,c.toLowerCase()));return c}},v||(y={name:!0,id:!0},w=f.valHooks.button={get:function(a,c){var d;d=a.getAttributeNode(c);return d&&(y[c]?d.nodeValue!=="":d.specified)?d.nodeValue:b},set:function(a,b,d){var e=a.getAttributeNode(d);e||(e=c.createAttribute(d),a.setAttributeNode(e));return e.nodeValue=b+""}},f.attrHooks.tabindex.set=w.set,f.each(["width","height"],function(a,b){f.attrHooks[b]=f.extend(f.attrHooks[b],{set:function(a,c){if(c===""){a.setAttribute(b,"auto");return c}}})}),f.attrHooks.contenteditable={get:w.get,set:function(a,b,c){b===""&&(b="false"),w.set(a,b,c)}}),f.support.hrefNormalized||f.each(["href","src","width","height"],function(a,c){f.attrHooks[c]=f.extend(f.attrHooks[c],{get:function(a){var d=a.getAttribute(c,2);return d===null?b:d}})}),f.support.style||(f.attrHooks.style={get:function(a){return a.style.cssText.toLowerCase()||b},set:function(a,b){return a.style.cssText=""+b}}),f.support.optSelected||(f.propHooks.selected=f.extend(f.propHooks.selected,{get:function(a){var b=a.parentNode;b&&(b.selectedIndex,b.parentNode&&b.parentNode.selectedIndex);return null}})),f.support.enctype||(f.propFix.enctype="encoding"),f.support.checkOn||f.each(["radio","checkbox"],function(){f.valHooks[this]={get:function(a){return a.getAttribute("value")===null?"on":a.value}}}),f.each(["radio","checkbox"],function(){f.valHooks[this]=f.extend(f.valHooks[this],{set:function(a,b){if(f.isArray(b))return a.checked=f.inArray(f(a).val(),b)>=0}})});var z=/^(?:textarea|input|select)$/i,A=/^([^\.]*)?(?:\.(.+))?$/,B=/\bhover(\.\S+)?\b/,C=/^key/,D=/^(?:mouse|contextmenu)|click/,E=/^(?:focusinfocus|focusoutblur)$/,F=/^(\w*)(?:#([\w\-]+))?(?:\.([\w\-]+))?$/,G=function(a){var b=F.exec(a);b&&(b[1]=(b[1]||"").toLowerCase(),b[3]=b[3]&&new RegExp("(?:^|\\s)"+b[3]+"(?:\\s|$)"));return b},H=function(a,b){var c=a.attributes||{};return(!b[1]||a.nodeName.toLowerCase()===b[1])&&(!b[2]||(c.id||{}).value===b[2])&&(!b[3]||b[3].test((c["class"]||{}).value))},I=function(a){return f.event.special.hover?a:a.replace(B,"mouseenter$1 mouseleave$1")};
f.event={add:function(a,c,d,e,g){var h,i,j,k,l,m,n,o,p,q,r,s;if(!(a.nodeType===3||a.nodeType===8||!c||!d||!(h=f._data(a)))){d.handler&&(p=d,d=p.handler),d.guid||(d.guid=f.guid++),j=h.events,j||(h.events=j={}),i=h.handle,i||(h.handle=i=function(a){return typeof f!="undefined"&&(!a||f.event.triggered!==a.type)?f.event.dispatch.apply(i.elem,arguments):b},i.elem=a),c=f.trim(I(c)).split(" ");for(k=0;k<c.length;k++){l=A.exec(c[k])||[],m=l[1],n=(l[2]||"").split(".").sort(),s=f.event.special[m]||{},m=(g?s.delegateType:s.bindType)||m,s=f.event.special[m]||{},o=f.extend({type:m,origType:l[1],data:e,handler:d,guid:d.guid,selector:g,quick:G(g),namespace:n.join(".")},p),r=j[m];if(!r){r=j[m]=[],r.delegateCount=0;if(!s.setup||s.setup.call(a,e,n,i)===!1)a.addEventListener?a.addEventListener(m,i,!1):a.attachEvent&&a.attachEvent("on"+m,i)}s.add&&(s.add.call(a,o),o.handler.guid||(o.handler.guid=d.guid)),g?r.splice(r.delegateCount++,0,o):r.push(o),f.event.global[m]=!0}a=null}},global:{},remove:function(a,b,c,d,e){var g=f.hasData(a)&&f._data(a),h,i,j,k,l,m,n,o,p,q,r,s;if(!!g&&!!(o=g.events)){b=f.trim(I(b||"")).split(" ");for(h=0;h<b.length;h++){i=A.exec(b[h])||[],j=k=i[1],l=i[2];if(!j){for(j in o)f.event.remove(a,j+b[h],c,d,!0);continue}p=f.event.special[j]||{},j=(d?p.delegateType:p.bindType)||j,r=o[j]||[],m=r.length,l=l?new RegExp("(^|\\.)"+l.split(".").sort().join("\\.(?:.*\\.)?")+"(\\.|$)"):null;for(n=0;n<r.length;n++)s=r[n],(e||k===s.origType)&&(!c||c.guid===s.guid)&&(!l||l.test(s.namespace))&&(!d||d===s.selector||d==="**"&&s.selector)&&(r.splice(n--,1),s.selector&&r.delegateCount--,p.remove&&p.remove.call(a,s));r.length===0&&m!==r.length&&((!p.teardown||p.teardown.call(a,l)===!1)&&f.removeEvent(a,j,g.handle),delete o[j])}f.isEmptyObject(o)&&(q=g.handle,q&&(q.elem=null),f.removeData(a,["events","handle"],!0))}},customEvent:{getData:!0,setData:!0,changeData:!0},trigger:function(c,d,e,g){if(!e||e.nodeType!==3&&e.nodeType!==8){var h=c.type||c,i=[],j,k,l,m,n,o,p,q,r,s;if(E.test(h+f.event.triggered))return;h.indexOf("!")>=0&&(h=h.slice(0,-1),k=!0),h.indexOf(".")>=0&&(i=h.split("."),h=i.shift(),i.sort());if((!e||f.event.customEvent[h])&&!f.event.global[h])return;c=typeof c=="object"?c[f.expando]?c:new f.Event(h,c):new f.Event(h),c.type=h,c.isTrigger=!0,c.exclusive=k,c.namespace=i.join("."),c.namespace_re=c.namespace?new RegExp("(^|\\.)"+i.join("\\.(?:.*\\.)?")+"(\\.|$)"):null,o=h.indexOf(":")<0?"on"+h:"";if(!e){j=f.cache;for(l in j)j[l].events&&j[l].events[h]&&f.event.trigger(c,d,j[l].handle.elem,!0);return}c.result=b,c.target||(c.target=e),d=d!=null?f.makeArray(d):[],d.unshift(c),p=f.event.special[h]||{};if(p.trigger&&p.trigger.apply(e,d)===!1)return;r=[[e,p.bindType||h]];if(!g&&!p.noBubble&&!f.isWindow(e)){s=p.delegateType||h,m=E.test(s+h)?e:e.parentNode,n=null;for(;m;m=m.parentNode)r.push([m,s]),n=m;n&&n===e.ownerDocument&&r.push([n.defaultView||n.parentWindow||a,s])}for(l=0;l<r.length&&!c.isPropagationStopped();l++)m=r[l][0],c.type=r[l][1],q=(f._data(m,"events")||{})[c.type]&&f._data(m,"handle"),q&&q.apply(m,d),q=o&&m[o],q&&f.acceptData(m)&&q.apply(m,d)===!1&&c.preventDefault();c.type=h,!g&&!c.isDefaultPrevented()&&(!p._default||p._default.apply(e.ownerDocument,d)===!1)&&(h!=="click"||!f.nodeName(e,"a"))&&f.acceptData(e)&&o&&e[h]&&(h!=="focus"&&h!=="blur"||c.target.offsetWidth!==0)&&!f.isWindow(e)&&(n=e[o],n&&(e[o]=null),f.event.triggered=h,e[h](),f.event.triggered=b,n&&(e[o]=n));return c.result}},dispatch:function(c){c=f.event.fix(c||a.event);var d=(f._data(this,"events")||{})[c.type]||[],e=d.delegateCount,g=[].slice.call(arguments,0),h=!c.exclusive&&!c.namespace,i=[],j,k,l,m,n,o,p,q,r,s,t;g[0]=c,c.delegateTarget=this;if(e&&!c.target.disabled&&(!c.button||c.type!=="click")){m=f(this),m.context=this.ownerDocument||this;for(l=c.target;l!=this;l=l.parentNode||this){o={},q=[],m[0]=l;for(j=0;j<e;j++)r=d[j],s=r.selector,o[s]===b&&(o[s]=r.quick?H(l,r.quick):m.is(s)),o[s]&&q.push(r);q.length&&i.push({elem:l,matches:q})}}d.length>e&&i.push({elem:this,matches:d.slice(e)});for(j=0;j<i.length&&!c.isPropagationStopped();j++){p=i[j],c.currentTarget=p.elem;for(k=0;k<p.matches.length&&!c.isImmediatePropagationStopped();k++){r=p.matches[k];if(h||!c.namespace&&!r.namespace||c.namespace_re&&c.namespace_re.test(r.namespace))c.data=r.data,c.handleObj=r,n=((f.event.special[r.origType]||{}).handle||r.handler).apply(p.elem,g),n!==b&&(c.result=n,n===!1&&(c.preventDefault(),c.stopPropagation()))}}return c.result},props:"attrChange attrName relatedNode srcElement altKey bubbles cancelable ctrlKey currentTarget eventPhase metaKey relatedTarget shiftKey target timeStamp view which".split(" "),fixHooks:{},keyHooks:{props:"char charCode key keyCode".split(" "),filter:function(a,b){a.which==null&&(a.which=b.charCode!=null?b.charCode:b.keyCode);return a}},mouseHooks:{props:"button buttons clientX clientY fromElement offsetX offsetY pageX pageY screenX screenY toElement".split(" "),filter:function(a,d){var e,f,g,h=d.button,i=d.fromElement;a.pageX==null&&d.clientX!=null&&(e=a.target.ownerDocument||c,f=e.documentElement,g=e.body,a.pageX=d.clientX+(f&&f.scrollLeft||g&&g.scrollLeft||0)-(f&&f.clientLeft||g&&g.clientLeft||0),a.pageY=d.clientY+(f&&f.scrollTop||g&&g.scrollTop||0)-(f&&f.clientTop||g&&g.clientTop||0)),!a.relatedTarget&&i&&(a.relatedTarget=i===a.target?d.toElement:i),!a.which&&h!==b&&(a.which=h&1?1:h&2?3:h&4?2:0);return a}},fix:function(a){if(a[f.expando])return a;var d,e,g=a,h=f.event.fixHooks[a.type]||{},i=h.props?this.props.concat(h.props):this.props;a=f.Event(g);for(d=i.length;d;)e=i[--d],a[e]=g[e];a.target||(a.target=g.srcElement||c),a.target.nodeType===3&&(a.target=a.target.parentNode),a.metaKey===b&&(a.metaKey=a.ctrlKey);return h.filter?h.filter(a,g):a},special:{ready:{setup:f.bindReady},load:{noBubble:!0},focus:{delegateType:"focusin"},blur:{delegateType:"focusout"},beforeunload:{setup:function(a,b,c){f.isWindow(this)&&(this.onbeforeunload=c)},teardown:function(a,b){this.onbeforeunload===b&&(this.onbeforeunload=null)}}},simulate:function(a,b,c,d){var e=f.extend(new f.Event,c,{type:a,isSimulated:!0,originalEvent:{}});d?f.event.trigger(e,null,b):f.event.dispatch.call(b,e),e.isDefaultPrevented()&&c.preventDefault()}},f.event.handle=f.event.dispatch,f.removeEvent=c.removeEventListener?function(a,b,c){a.removeEventListener&&a.removeEventListener(b,c,!1)}:function(a,b,c){a.detachEvent&&a.detachEvent("on"+b,c)},f.Event=function(a,b){if(!(this instanceof f.Event))return new f.Event(a,b);a&&a.type?(this.originalEvent=a,this.type=a.type,this.isDefaultPrevented=a.defaultPrevented||a.returnValue===!1||a.getPreventDefault&&a.getPreventDefault()?K:J):this.type=a,b&&f.extend(this,b),this.timeStamp=a&&a.timeStamp||f.now(),this[f.expando]=!0},f.Event.prototype={preventDefault:function(){this.isDefaultPrevented=K;var a=this.originalEvent;!a||(a.preventDefault?a.preventDefault():a.returnValue=!1)},stopPropagation:function(){this.isPropagationStopped=K;var a=this.originalEvent;!a||(a.stopPropagation&&a.stopPropagation(),a.cancelBubble=!0)},stopImmediatePropagation:function(){this.isImmediatePropagationStopped=K,this.stopPropagation()},isDefaultPrevented:J,isPropagationStopped:J,isImmediatePropagationStopped:J},f.each({mouseenter:"mouseover",mouseleave:"mouseout"},function(a,b){f.event.special[a]={delegateType:b,bindType:b,handle:function(a){var c=this,d=a.relatedTarget,e=a.handleObj,g=e.selector,h;if(!d||d!==c&&!f.contains(c,d))a.type=e.origType,h=e.handler.apply(this,arguments),a.type=b;return h}}}),f.support.submitBubbles||(f.event.special.submit={setup:function(){if(f.nodeName(this,"form"))return!1;f.event.add(this,"click._submit keypress._submit",function(a){var c=a.target,d=f.nodeName(c,"input")||f.nodeName(c,"button")?c.form:b;d&&!d._submit_attached&&(f.event.add(d,"submit._submit",function(a){this.parentNode&&!a.isTrigger&&f.event.simulate("submit",this.parentNode,a,!0)}),d._submit_attached=!0)})},teardown:function(){if(f.nodeName(this,"form"))return!1;f.event.remove(this,"._submit")}}),f.support.changeBubbles||(f.event.special.change={setup:function(){if(z.test(this.nodeName)){if(this.type==="checkbox"||this.type==="radio")f.event.add(this,"propertychange._change",function(a){a.originalEvent.propertyName==="checked"&&(this._just_changed=!0)}),f.event.add(this,"click._change",function(a){this._just_changed&&!a.isTrigger&&(this._just_changed=!1,f.event.simulate("change",this,a,!0))});return!1}f.event.add(this,"beforeactivate._change",function(a){var b=a.target;z.test(b.nodeName)&&!b._change_attached&&(f.event.add(b,"change._change",function(a){this.parentNode&&!a.isSimulated&&!a.isTrigger&&f.event.simulate("change",this.parentNode,a,!0)}),b._change_attached=!0)})},handle:function(a){var b=a.target;if(this!==b||a.isSimulated||a.isTrigger||b.type!=="radio"&&b.type!=="checkbox")return a.handleObj.handler.apply(this,arguments)},teardown:function(){f.event.remove(this,"._change");return z.test(this.nodeName)}}),f.support.focusinBubbles||f.each({focus:"focusin",blur:"focusout"},function(a,b){var d=0,e=function(a){f.event.simulate(b,a.target,f.event.fix(a),!0)};f.event.special[b]={setup:function(){d++===0&&c.addEventListener(a,e,!0)},teardown:function(){--d===0&&c.removeEventListener(a,e,!0)}}}),f.fn.extend({on:function(a,c,d,e,g){var h,i;if(typeof a=="object"){typeof c!="string"&&(d=c,c=b);for(i in a)this.on(i,c,d,a[i],g);return this}d==null&&e==null?(e=c,d=c=b):e==null&&(typeof c=="string"?(e=d,d=b):(e=d,d=c,c=b));if(e===!1)e=J;else if(!e)return this;g===1&&(h=e,e=function(a){f().off(a);return h.apply(this,arguments)},e.guid=h.guid||(h.guid=f.guid++));return this.each(function(){f.event.add(this,a,e,d,c)})},one:function(a,b,c,d){return this.on.call(this,a,b,c,d,1)},off:function(a,c,d){if(a&&a.preventDefault&&a.handleObj){var e=a.handleObj;f(a.delegateTarget).off(e.namespace?e.type+"."+e.namespace:e.type,e.selector,e.handler);return this}if(typeof a=="object"){for(var g in a)this.off(g,c,a[g]);return this}if(c===!1||typeof c=="function")d=c,c=b;d===!1&&(d=J);return this.each(function(){f.event.remove(this,a,d,c)})},bind:function(a,b,c){return this.on(a,null,b,c)},unbind:function(a,b){return this.off(a,null,b)},live:function(a,b,c){f(this.context).on(a,this.selector,b,c);return this},die:function(a,b){f(this.context).off(a,this.selector||"**",b);return this},delegate:function(a,b,c,d){return this.on(b,a,c,d)},undelegate:function(a,b,c){return arguments.length==1?this.off(a,"**"):this.off(b,a,c)},trigger:function(a,b){return this.each(function(){f.event.trigger(a,b,this)})},triggerHandler:function(a,b){if(this[0])return f.event.trigger(a,b,this[0],!0)},toggle:function(a){var b=arguments,c=a.guid||f.guid++,d=0,e=function(c){var e=(f._data(this,"lastToggle"+a.guid)||0)%d;f._data(this,"lastToggle"+a.guid,e+1),c.preventDefault();return b[e].apply(this,arguments)||!1};e.guid=c;while(d<b.length)b[d++].guid=c;return this.click(e)},hover:function(a,b){return this.mouseenter(a).mouseleave(b||a)}}),f.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error contextmenu".split(" "),function(a,b){f.fn[b]=function(a,c){c==null&&(c=a,a=null);return arguments.length>0?this.on(b,null,a,c):this.trigger(b)},f.attrFn&&(f.attrFn[b]=!0),C.test(b)&&(f.event.fixHooks[b]=f.event.keyHooks),D.test(b)&&(f.event.fixHooks[b]=f.event.mouseHooks)}),function(){function x(a,b,c,e,f,g){for(var h=0,i=e.length;h<i;h++){var j=e[h];if(j){var k=!1;j=j[a];while(j){if(j[d]===c){k=e[j.sizset];break}if(j.nodeType===1){g||(j[d]=c,j.sizset=h);if(typeof b!="string"){if(j===b){k=!0;break}}else if(m.filter(b,[j]).length>0){k=j;break}}j=j[a]}e[h]=k}}}function w(a,b,c,e,f,g){for(var h=0,i=e.length;h<i;h++){var j=e[h];if(j){var k=!1;j=j[a];while(j){if(j[d]===c){k=e[j.sizset];break}j.nodeType===1&&!g&&(j[d]=c,j.sizset=h);if(j.nodeName.toLowerCase()===b){k=j;break}j=j[a]}e[h]=k}}}var a=/((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^\[\]]*\]|['"][^'"]*['"]|[^\[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?((?:.|\r|\n)*)/g,d="sizcache"+(Math.random()+"").replace(".",""),e=0,g=Object.prototype.toString,h=!1,i=!0,j=/\\/g,k=/\r\n/g,l=/\W/;[0,0].sort(function(){i=!1;return 0});var m=function(b,d,e,f){e=e||[],d=d||c;var h=d;if(d.nodeType!==1&&d.nodeType!==9)return[];if(!b||typeof b!="string")return e;var i,j,k,l,n,q,r,t,u=!0,v=m.isXML(d),w=[],x=b;do{a.exec(""),i=a.exec(x);if(i){x=i[3],w.push(i[1]);if(i[2]){l=i[3];break}}}while(i);if(w.length>1&&p.exec(b))if(w.length===2&&o.relative[w[0]])j=y(w[0]+w[1],d,f);else{j=o.relative[w[0]]?[d]:m(w.shift(),d);while(w.length)b=w.shift(),o.relative[b]&&(b+=w.shift()),j=y(b,j,f)}else{!f&&w.length>1&&d.nodeType===9&&!v&&o.match.ID.test(w[0])&&!o.match.ID.test(w[w.length-1])&&(n=m.find(w.shift(),d,v),d=n.expr?m.filter(n.expr,n.set)[0]:n.set[0]);if(d){n=f?{expr:w.pop(),set:s(f)}:m.find(w.pop(),w.length===1&&(w[0]==="~"||w[0]==="+")&&d.parentNode?d.parentNode:d,v),j=n.expr?m.filter(n.expr,n.set):n.set,w.length>0?k=s(j):u=!1;while(w.length)q=w.pop(),r=q,o.relative[q]?r=w.pop():q="",r==null&&(r=d),o.relative[q](k,r,v)}else k=w=[]}k||(k=j),k||m.error(q||b);if(g.call(k)==="[object Array]")if(!u)e.push.apply(e,k);else if(d&&d.nodeType===1)for(t=0;k[t]!=null;t++)k[t]&&(k[t]===!0||k[t].nodeType===1&&m.contains(d,k[t]))&&e.push(j[t]);else for(t=0;k[t]!=null;t++)k[t]&&k[t].nodeType===1&&e.push(j[t]);else s(k,e);l&&(m(l,h,e,f),m.uniqueSort(e));return e};m.uniqueSort=function(a){if(u){h=i,a.sort(u);if(h)for(var b=1;b<a.length;b++)a[b]===a[b-1]&&a.splice(b--,1)}return a},m.matches=function(a,b){return m(a,null,null,b)},m.matchesSelector=function(a,b){return m(b,null,null,[a]).length>0},m.find=function(a,b,c){var d,e,f,g,h,i;if(!a)return[];for(e=0,f=o.order.length;e<f;e++){h=o.order[e];if(g=o.leftMatch[h].exec(a)){i=g[1],g.splice(1,1);if(i.substr(i.length-1)!=="\\"){g[1]=(g[1]||"").replace(j,""),d=o.find[h](g,b,c);if(d!=null){a=a.replace(o.match[h],"");break}}}}d||(d=typeof b.getElementsByTagName!="undefined"?b.getElementsByTagName("*"):[]);return{set:d,expr:a}},m.filter=function(a,c,d,e){var f,g,h,i,j,k,l,n,p,q=a,r=[],s=c,t=c&&c[0]&&m.isXML(c[0]);while(a&&c.length){for(h in o.filter)if((f=o.leftMatch[h].exec(a))!=null&&f[2]){k=o.filter[h],l=f[1],g=!1,f.splice(1,1);if(l.substr(l.length-1)==="\\")continue;s===r&&(r=[]);if(o.preFilter[h]){f=o.preFilter[h](f,s,d,r,e,t);if(!f)g=i=!0;else if(f===!0)continue}if(f)for(n=0;(j=s[n])!=null;n++)j&&(i=k(j,f,n,s),p=e^i,d&&i!=null?p?g=!0:s[n]=!1:p&&(r.push(j),g=!0));if(i!==b){d||(s=r),a=a.replace(o.match[h],"");if(!g)return[];break}}if(a===q)if(g==null)m.error(a);else break;q=a}return s},m.error=function(a){throw new Error("Syntax error, unrecognized expression: "+a)};var n=m.getText=function(a){var b,c,d=a.nodeType,e="";if(d){if(d===1||d===9){if(typeof a.textContent=="string")return a.textContent;if(typeof a.innerText=="string")return a.innerText.replace(k,"");for(a=a.firstChild;a;a=a.nextSibling)e+=n(a)}else if(d===3||d===4)return a.nodeValue}else for(b=0;c=a[b];b++)c.nodeType!==8&&(e+=n(c));return e},o=m.selectors={order:["ID","NAME","TAG"],match:{ID:/#((?:[\w\u00c0-\uFFFF\-]|\\.)+)/,CLASS:/\.((?:[\w\u00c0-\uFFFF\-]|\\.)+)/,NAME:/\[name=['"]*((?:[\w\u00c0-\uFFFF\-]|\\.)+)['"]*\]/,ATTR:/\[\s*((?:[\w\u00c0-\uFFFF\-]|\\.)+)\s*(?:(\S?=)\s*(?:(['"])(.*?)\3|(#?(?:[\w\u00c0-\uFFFF\-]|\\.)*)|)|)\s*\]/,TAG:/^((?:[\w\u00c0-\uFFFF\*\-]|\\.)+)/,CHILD:/:(only|nth|last|first)-child(?:\(\s*(even|odd|(?:[+\-]?\d+|(?:[+\-]?\d*)?n\s*(?:[+\-]\s*\d+)?))\s*\))?/,POS:/:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^\-]|$)/,PSEUDO:/:((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\2\))?/},leftMatch:{},attrMap:{"class":"className","for":"htmlFor"},attrHandle:{href:function(a){return a.getAttribute("href")},type:function(a){return a.getAttribute("type")}},relative:{"+":function(a,b){var c=typeof b=="string",d=c&&!l.test(b),e=c&&!d;d&&(b=b.toLowerCase());for(var f=0,g=a.length,h;f<g;f++)if(h=a[f]){while((h=h.previousSibling)&&h.nodeType!==1);a[f]=e||h&&h.nodeName.toLowerCase()===b?h||!1:h===b}e&&m.filter(b,a,!0)},">":function(a,b){var c,d=typeof b=="string",e=0,f=a.length;if(d&&!l.test(b)){b=b.toLowerCase();for(;e<f;e++){c=a[e];if(c){var g=c.parentNode;a[e]=g.nodeName.toLowerCase()===b?g:!1}}}else{for(;e<f;e++)c=a[e],c&&(a[e]=d?c.parentNode:c.parentNode===b);d&&m.filter(b,a,!0)}},"":function(a,b,c){var d,f=e++,g=x;typeof b=="string"&&!l.test(b)&&(b=b.toLowerCase(),d=b,g=w),g("parentNode",b,f,a,d,c)},"~":function(a,b,c){var d,f=e++,g=x;typeof b=="string"&&!l.test(b)&&(b=b.toLowerCase(),d=b,g=w),g("previousSibling",b,f,a,d,c)}},find:{ID:function(a,b,c){if(typeof b.getElementById!="undefined"&&!c){var d=b.getElementById(a[1]);return d&&d.parentNode?[d]:[]}},NAME:function(a,b){if(typeof b.getElementsByName!="undefined"){var c=[],d=b.getElementsByName(a[1]);for(var e=0,f=d.length;e<f;e++)d[e].getAttribute("name")===a[1]&&c.push(d[e]);return c.length===0?null:c}},TAG:function(a,b){if(typeof b.getElementsByTagName!="undefined")return b.getElementsByTagName(a[1])}},preFilter:{CLASS:function(a,b,c,d,e,f){a=" "+a[1].replace(j,"")+" ";if(f)return a;for(var g=0,h;(h=b[g])!=null;g++)h&&(e^(h.className&&(" "+h.className+" ").replace(/[\t\n\r]/g," ").indexOf(a)>=0)?c||d.push(h):c&&(b[g]=!1));return!1},ID:function(a){return a[1].replace(j,"")},TAG:function(a,b){return a[1].replace(j,"").toLowerCase()},CHILD:function(a){if(a[1]==="nth"){a[2]||m.error(a[0]),a[2]=a[2].replace(/^\+|\s*/g,"");var b=/(-?)(\d*)(?:n([+\-]?\d*))?/.exec(a[2]==="even"&&"2n"||a[2]==="odd"&&"2n+1"||!/\D/.test(a[2])&&"0n+"+a[2]||a[2]);a[2]=b[1]+(b[2]||1)-0,a[3]=b[3]-0}else a[2]&&m.error(a[0]);a[0]=e++;return a},ATTR:function(a,b,c,d,e,f){var g=a[1]=a[1].replace(j,"");!f&&o.attrMap[g]&&(a[1]=o.attrMap[g]),a[4]=(a[4]||a[5]||"").replace(j,""),a[2]==="~="&&(a[4]=" "+a[4]+" ");return a},PSEUDO:function(b,c,d,e,f){if(b[1]==="not")if((a.exec(b[3])||"").length>1||/^\w/.test(b[3]))b[3]=m(b[3],null,null,c);else{var g=m.filter(b[3],c,d,!0^f);d||e.push.apply(e,g);return!1}else if(o.match.POS.test(b[0])||o.match.CHILD.test(b[0]))return!0;return b},POS:function(a){a.unshift(!0);return a}},filters:{enabled:function(a){return a.disabled===!1&&a.type!=="hidden"},disabled:function(a){return a.disabled===!0},checked:function(a){return a.checked===!0},selected:function(a){a.parentNode&&a.parentNode.selectedIndex;return a.selected===!0},parent:function(a){return!!a.firstChild},empty:function(a){return!a.firstChild},has:function(a,b,c){return!!m(c[3],a).length},header:function(a){return/h\d/i.test(a.nodeName)},text:function(a){var b=a.getAttribute("type"),c=a.type;return a.nodeName.toLowerCase()==="input"&&"text"===c&&(b===c||b===null)},radio:function(a){return a.nodeName.toLowerCase()==="input"&&"radio"===a.type},checkbox:function(a){return a.nodeName.toLowerCase()==="input"&&"checkbox"===a.type},file:function(a){return a.nodeName.toLowerCase()==="input"&&"file"===a.type},password:function(a){return a.nodeName.toLowerCase()==="input"&&"password"===a.type},submit:function(a){var b=a.nodeName.toLowerCase();return(b==="input"||b==="button")&&"submit"===a.type},image:function(a){return a.nodeName.toLowerCase()==="input"&&"image"===a.type},reset:function(a){var b=a.nodeName.toLowerCase();return(b==="input"||b==="button")&&"reset"===a.type},button:function(a){var b=a.nodeName.toLowerCase();return b==="input"&&"button"===a.type||b==="button"},input:function(a){return/input|select|textarea|button/i.test(a.nodeName)},focus:function(a){return a===a.ownerDocument.activeElement}},setFilters:{first:function(a,b){return b===0},last:function(a,b,c,d){return b===d.length-1},even:function(a,b){return b%2===0},odd:function(a,b){return b%2===1},lt:function(a,b,c){return b<c[3]-0},gt:function(a,b,c){return b>c[3]-0},nth:function(a,b,c){return c[3]-0===b},eq:function(a,b,c){return c[3]-0===b}},filter:{PSEUDO:function(a,b,c,d){var e=b[1],f=o.filters[e];if(f)return f(a,c,b,d);if(e==="contains")return(a.textContent||a.innerText||n([a])||"").indexOf(b[3])>=0;if(e==="not"){var g=b[3];for(var h=0,i=g.length;h<i;h++)if(g[h]===a)return!1;return!0}m.error(e)},CHILD:function(a,b){var c,e,f,g,h,i,j,k=b[1],l=a;switch(k){case"only":case"first":while(l=l.previousSibling)if(l.nodeType===1)return!1;if(k==="first")return!0;l=a;case"last":while(l=l.nextSibling)if(l.nodeType===1)return!1;return!0;case"nth":c=b[2],e=b[3];if(c===1&&e===0)return!0;f=b[0],g=a.parentNode;if(g&&(g[d]!==f||!a.nodeIndex)){i=0;for(l=g.firstChild;l;l=l.nextSibling)l.nodeType===1&&(l.nodeIndex=++i);g[d]=f}j=a.nodeIndex-e;return c===0?j===0:j%c===0&&j/c>=0}},ID:function(a,b){return a.nodeType===1&&a.getAttribute("id")===b},TAG:function(a,b){return b==="*"&&a.nodeType===1||!!a.nodeName&&a.nodeName.toLowerCase()===b},CLASS:function(a,b){return(" "+(a.className||a.getAttribute("class"))+" ").indexOf(b)>-1},ATTR:function(a,b){var c=b[1],d=m.attr?m.attr(a,c):o.attrHandle[c]?o.attrHandle[c](a):a[c]!=null?a[c]:a.getAttribute(c),e=d+"",f=b[2],g=b[4];return d==null?f==="!=":!f&&m.attr?d!=null:f==="="?e===g:f==="*="?e.indexOf(g)>=0:f==="~="?(" "+e+" ").indexOf(g)>=0:g?f==="!="?e!==g:f==="^="?e.indexOf(g)===0:f==="$="?e.substr(e.length-g.length)===g:f==="|="?e===g||e.substr(0,g.length+1)===g+"-":!1:e&&d!==!1},POS:function(a,b,c,d){var e=b[2],f=o.setFilters[e];if(f)return f(a,c,b,d)}}},p=o.match.POS,q=function(a,b){return"\\"+(b-0+1)};for(var r in o.match)o.match[r]=new RegExp(o.match[r].source+/(?![^\[]*\])(?![^\(]*\))/.source),o.leftMatch[r]=new RegExp(/(^(?:.|\r|\n)*?)/.source+o.match[r].source.replace(/\\(\d+)/g,q));var s=function(a,b){a=Array.prototype.slice.call(a,0);if(b){b.push.apply(b,a);return b}return a};try{Array.prototype.slice.call(c.documentElement.childNodes,0)[0].nodeType}catch(t){s=function(a,b){var c=0,d=b||[];if(g.call(a)==="[object Array]")Array.prototype.push.apply(d,a);else if(typeof a.length=="number")for(var e=a.length;c<e;c++)d.push(a[c]);else for(;a[c];c++)d.push(a[c]);return d}}var u,v;c.documentElement.compareDocumentPosition?u=function(a,b){if(a===b){h=!0;return 0}if(!a.compareDocumentPosition||!b.compareDocumentPosition)return a.compareDocumentPosition?-1:1;return a.compareDocumentPosition(b)&4?-1:1}:(u=function(a,b){if(a===b){h=!0;return 0}if(a.sourceIndex&&b.sourceIndex)return a.sourceIndex-b.sourceIndex;var c,d,e=[],f=[],g=a.parentNode,i=b.parentNode,j=g;if(g===i)return v(a,b);if(!g)return-1;if(!i)return 1;while(j)e.unshift(j),j=j.parentNode;j=i;while(j)f.unshift(j),j=j.parentNode;c=e.length,d=f.length;for(var k=0;k<c&&k<d;k++)if(e[k]!==f[k])return v(e[k],f[k]);return k===c?v(a,f[k],-1):v(e[k],b,1)},v=function(a,b,c){if(a===b)return c;var d=a.nextSibling;while(d){if(d===b)return-1;d=d.nextSibling}return 1}),function(){var a=c.createElement("div"),d="script"+(new Date).getTime(),e=c.documentElement;a.innerHTML="<a name='"+d+"'/>",e.insertBefore(a,e.firstChild),c.getElementById(d)&&(o.find.ID=function(a,c,d){if(typeof c.getElementById!="undefined"&&!d){var e=c.getElementById(a[1]);return e?e.id===a[1]||typeof e.getAttributeNode!="undefined"&&e.getAttributeNode("id").nodeValue===a[1]?[e]:b:[]}},o.filter.ID=function(a,b){var c=typeof a.getAttributeNode!="undefined"&&a.getAttributeNode("id");return a.nodeType===1&&c&&c.nodeValue===b}),e.removeChild(a),e=a=null}(),function(){var a=c.createElement("div");a.appendChild(c.createComment("")),a.getElementsByTagName("*").length>0&&(o.find.TAG=function(a,b){var c=b.getElementsByTagName(a[1]);if(a[1]==="*"){var d=[];for(var e=0;c[e];e++)c[e].nodeType===1&&d.push(c[e]);c=d}return c}),a.innerHTML="<a href='#'></a>",a.firstChild&&typeof a.firstChild.getAttribute!="undefined"&&a.firstChild.getAttribute("href")!=="#"&&(o.attrHandle.href=function(a){return a.getAttribute("href",2)}),a=null}(),c.querySelectorAll&&function(){var a=m,b=c.createElement("div"),d="__sizzle__";b.innerHTML="<p class='TEST'></p>";if(!b.querySelectorAll||b.querySelectorAll(".TEST").length!==0){m=function(b,e,f,g){e=e||c;if(!g&&!m.isXML(e)){var h=/^(\w+$)|^\.([\w\-]+$)|^#([\w\-]+$)/.exec(b);if(h&&(e.nodeType===1||e.nodeType===9)){if(h[1])return s(e.getElementsByTagName(b),f);if(h[2]&&o.find.CLASS&&e.getElementsByClassName)return s(e.getElementsByClassName(h[2]),f)}if(e.nodeType===9){if(b==="body"&&e.body)return s([e.body],f);if(h&&h[3]){var i=e.getElementById(h[3]);if(!i||!i.parentNode)return s([],f);if(i.id===h[3])return s([i],f)}try{return s(e.querySelectorAll(b),f)}catch(j){}}else if(e.nodeType===1&&e.nodeName.toLowerCase()!=="object"){var k=e,l=e.getAttribute("id"),n=l||d,p=e.parentNode,q=/^\s*[+~]/.test(b);l?n=n.replace(/'/g,"\\$&"):e.setAttribute("id",n),q&&p&&(e=e.parentNode);try{if(!q||p)return s(e.querySelectorAll("[id='"+n+"'] "+b),f)}catch(r){}finally{l||k.removeAttribute("id")}}}return a(b,e,f,g)};for(var e in a)m[e]=a[e];b=null}}(),function(){var a=c.documentElement,b=a.matchesSelector||a.mozMatchesSelector||a.webkitMatchesSelector||a.msMatchesSelector;if(b){var d=!b.call(c.createElement("div"),"div"),e=!1;try{b.call(c.documentElement,"[test!='']:sizzle")}catch(f){e=!0}m.matchesSelector=function(a,c){c=c.replace(/\=\s*([^'"\]]*)\s*\]/g,"='$1']");if(!m.isXML(a))try{if(e||!o.match.PSEUDO.test(c)&&!/!=/.test(c)){var f=b.call(a,c);if(f||!d||a.document&&a.document.nodeType!==11)return f}}catch(g){}return m(c,null,null,[a]).length>0}}}(),function(){var a=c.createElement("div");a.innerHTML="<div class='test e'></div><div class='test'></div>";if(!!a.getElementsByClassName&&a.getElementsByClassName("e").length!==0){a.lastChild.className="e";if(a.getElementsByClassName("e").length===1)return;o.order.splice(1,0,"CLASS"),o.find.CLASS=function(a,b,c){if(typeof b.getElementsByClassName!="undefined"&&!c)return b.getElementsByClassName(a[1])},a=null}}(),c.documentElement.contains?m.contains=function(a,b){return a!==b&&(a.contains?a.contains(b):!0)}:c.documentElement.compareDocumentPosition?m.contains=function(a,b){return!!(a.compareDocumentPosition(b)&16)}:m.contains=function(){return!1},m.isXML=function(a){var b=(a?a.ownerDocument||a:0).documentElement;return b?b.nodeName!=="HTML":!1};var y=function(a,b,c){var d,e=[],f="",g=b.nodeType?[b]:b;while(d=o.match.PSEUDO.exec(a))f+=d[0],a=a.replace(o.match.PSEUDO,"");a=o.relative[a]?a+"*":a;for(var h=0,i=g.length;h<i;h++)m(a,g[h],e,c);return m.filter(f,e)};m.attr=f.attr,m.selectors.attrMap={},f.find=m,f.expr=m.selectors,f.expr[":"]=f.expr.filters,f.unique=m.uniqueSort,f.text=m.getText,f.isXMLDoc=m.isXML,f.contains=m.contains}();var L=/Until$/,M=/^(?:parents|prevUntil|prevAll)/,N=/,/,O=/^.[^:#\[\.,]*$/,P=Array.prototype.slice,Q=f.expr.match.POS,R={children:!0,contents:!0,next:!0,prev:!0};f.fn.extend({find:function(a){var b=this,c,d;if(typeof a!="string")return f(a).filter(function(){for(c=0,d=b.length;c<d;c++)if(f.contains(b[c],this))return!0});var e=this.pushStack("","find",a),g,h,i;for(c=0,d=this.length;c<d;c++){g=e.length,f.find(a,this[c],e);if(c>0)for(h=g;h<e.length;h++)for(i=0;i<g;i++)if(e[i]===e[h]){e.splice(h--,1);break}}return e},has:function(a){var b=f(a);return this.filter(function(){for(var a=0,c=b.length;a<c;a++)if(f.contains(this,b[a]))return!0})},not:function(a){return this.pushStack(T(this,a,!1),"not",a)},filter:function(a){return this.pushStack(T(this,a,!0),"filter",a)},is:function(a){return!!a&&(typeof a=="string"?Q.test(a)?f(a,this.context).index(this[0])>=0:f.filter(a,this).length>0:this.filter(a).length>0)},closest:function(a,b){var c=[],d,e,g=this[0];if(f.isArray(a)){var h=1;while(g&&g.ownerDocument&&g!==b){for(d=0;d<a.length;d++)f(g).is(a[d])&&c.push({selector:a[d],elem:g,level:h});g=g.parentNode,h++}return c}var i=Q.test(a)||typeof a!="string"?f(a,b||this.context):0;for(d=0,e=this.length;d<e;d++){g=this[d];while(g){if(i?i.index(g)>-1:f.find.matchesSelector(g,a)){c.push(g);break}g=g.parentNode;if(!g||!g.ownerDocument||g===b||g.nodeType===11)break}}c=c.length>1?f.unique(c):c;return this.pushStack(c,"closest",a)},index:function(a){if(!a)return this[0]&&this[0].parentNode?this.prevAll().length:-1;if(typeof a=="string")return f.inArray(this[0],f(a));return f.inArray(a.jquery?a[0]:a,this)},add:function(a,b){var c=typeof a=="string"?f(a,b):f.makeArray(a&&a.nodeType?[a]:a),d=f.merge(this.get(),c);return this.pushStack(S(c[0])||S(d[0])?d:f.unique(d))},andSelf:function(){return this.add(this.prevObject)}}),f.each({parent:function(a){var b=a.parentNode;return b&&b.nodeType!==11?b:null},parents:function(a){return f.dir(a,"parentNode")},parentsUntil:function(a,b,c){return f.dir(a,"parentNode",c)},next:function(a){return f.nth(a,2,"nextSibling")},prev:function(a){return f.nth(a,2,"previousSibling")},nextAll:function(a){return f.dir(a,"nextSibling")},prevAll:function(a){return f.dir(a,"previousSibling")},nextUntil:function(a,b,c){return f.dir(a,"nextSibling",c)},prevUntil:function(a,b,c){return f.dir(a,"previousSibling",c)},siblings:function(a){return f.sibling(a.parentNode.firstChild,a)},children:function(a){return f.sibling(a.firstChild)},contents:function(a){return f.nodeName(a,"iframe")?a.contentDocument||a.contentWindow.document:f.makeArray(a.childNodes)}},function(a,b){f.fn[a]=function(c,d){var e=f.map(this,b,c);L.test(a)||(d=c),d&&typeof d=="string"&&(e=f.filter(d,e)),e=this.length>1&&!R[a]?f.unique(e):e,(this.length>1||N.test(d))&&M.test(a)&&(e=e.reverse());return this.pushStack(e,a,P.call(arguments).join(","))}}),f.extend({filter:function(a,b,c){c&&(a=":not("+a+")");return b.length===1?f.find.matchesSelector(b[0],a)?[b[0]]:[]:f.find.matches(a,b)},dir:function(a,c,d){var e=[],g=a[c];while(g&&g.nodeType!==9&&(d===b||g.nodeType!==1||!f(g).is(d)))g.nodeType===1&&e.push(g),g=g[c];return e},nth:function(a,b,c,d){b=b||1;var e=0;for(;a;a=a[c])if(a.nodeType===1&&++e===b)break;return a},sibling:function(a,b){var c=[];for(;a;a=a.nextSibling)a.nodeType===1&&a!==b&&c.push(a);return c}});var V="abbr|article|aside|audio|canvas|datalist|details|figcaption|figure|footer|header|hgroup|mark|meter|nav|output|progress|section|summary|time|video",W=/ jQuery\d+="(?:\d+|null)"/g,X=/^\s+/,Y=/<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:]+)[^>]*)\/>/ig,Z=/<([\w:]+)/,$=/<tbody/i,_=/<|&#?\w+;/,ba=/<(?:script|style)/i,bb=/<(?:script|object|embed|option|style)/i,bc=new RegExp("<(?:"+V+")","i"),bd=/checked\s*(?:[^=]|=\s*.checked.)/i,be=/\/(java|ecma)script/i,bf=/^\s*<!(?:\[CDATA\[|\-\-)/,bg={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],area:[1,"<map>","</map>"],_default:[0,"",""]},bh=U(c);bg.optgroup=bg.option,bg.tbody=bg.tfoot=bg.colgroup=bg.caption=bg.thead,bg.th=bg.td,f.support.htmlSerialize||(bg._default=[1,"div<div>","</div>"]),f.fn.extend({text:function(a){if(f.isFunction(a))return this.each(function(b){var c=f(this);c.text(a.call(this,b,c.text()))});if(typeof a!="object"&&a!==b)return this.empty().append((this[0]&&this[0].ownerDocument||c).createTextNode(a));return f.text(this)},wrapAll:function(a){if(f.isFunction(a))return this.each(function(b){f(this).wrapAll(a.call(this,b))});if(this[0]){var b=f(a,this[0].ownerDocument).eq(0).clone(!0);this[0].parentNode&&b.insertBefore(this[0]),b.map(function(){var a=this;while(a.firstChild&&a.firstChild.nodeType===1)a=a.firstChild;return a}).append(this)}return this},wrapInner:function(a){if(f.isFunction(a))return this.each(function(b){f(this).wrapInner(a.call(this,b))});return this.each(function(){var b=f(this),c=b.contents();c.length?c.wrapAll(a):b.append(a)})},wrap:function(a){var b=f.isFunction(a);return this.each(function(c){f(this).wrapAll(b?a.call(this,c):a)})},unwrap:function(){return this.parent().each(function(){f.nodeName(this,"body")||f(this).replaceWith(this.childNodes)}).end()},append:function(){return this.domManip(arguments,!0,function(a){this.nodeType===1&&this.appendChild(a)})},prepend:function(){return this.domManip(arguments,!0,function(a){this.nodeType===1&&this.insertBefore(a,this.firstChild)})},before:function(){if(this[0]&&this[0].parentNode)return this.domManip(arguments,!1,function(a){this.parentNode.insertBefore(a,this)});if(arguments.length){var a=f.clean(arguments);a.push.apply(a,this.toArray());return this.pushStack(a,"before",arguments)}},after:function(){if(this[0]&&this[0].parentNode)return this.domManip(arguments,!1,function(a){this.parentNode.insertBefore(a,this.nextSibling)});if(arguments.length){var a=this.pushStack(this,"after",arguments);a.push.apply(a,f.clean(arguments));return a}},remove:function(a,b){for(var c=0,d;(d=this[c])!=null;c++)if(!a||f.filter(a,[d]).length)!b&&d.nodeType===1&&(f.cleanData(d.getElementsByTagName("*")),f.cleanData([d])),d.parentNode&&d.parentNode.removeChild(d);return this},empty:function()
{for(var a=0,b;(b=this[a])!=null;a++){b.nodeType===1&&f.cleanData(b.getElementsByTagName("*"));while(b.firstChild)b.removeChild(b.firstChild)}return this},clone:function(a,b){a=a==null?!1:a,b=b==null?a:b;return this.map(function(){return f.clone(this,a,b)})},html:function(a){if(a===b)return this[0]&&this[0].nodeType===1?this[0].innerHTML.replace(W,""):null;if(typeof a=="string"&&!ba.test(a)&&(f.support.leadingWhitespace||!X.test(a))&&!bg[(Z.exec(a)||["",""])[1].toLowerCase()]){a=a.replace(Y,"<$1></$2>");try{for(var c=0,d=this.length;c<d;c++)this[c].nodeType===1&&(f.cleanData(this[c].getElementsByTagName("*")),this[c].innerHTML=a)}catch(e){this.empty().append(a)}}else f.isFunction(a)?this.each(function(b){var c=f(this);c.html(a.call(this,b,c.html()))}):this.empty().append(a);return this},replaceWith:function(a){if(this[0]&&this[0].parentNode){if(f.isFunction(a))return this.each(function(b){var c=f(this),d=c.html();c.replaceWith(a.call(this,b,d))});typeof a!="string"&&(a=f(a).detach());return this.each(function(){var b=this.nextSibling,c=this.parentNode;f(this).remove(),b?f(b).before(a):f(c).append(a)})}return this.length?this.pushStack(f(f.isFunction(a)?a():a),"replaceWith",a):this},detach:function(a){return this.remove(a,!0)},domManip:function(a,c,d){var e,g,h,i,j=a[0],k=[];if(!f.support.checkClone&&arguments.length===3&&typeof j=="string"&&bd.test(j))return this.each(function(){f(this).domManip(a,c,d,!0)});if(f.isFunction(j))return this.each(function(e){var g=f(this);a[0]=j.call(this,e,c?g.html():b),g.domManip(a,c,d)});if(this[0]){i=j&&j.parentNode,f.support.parentNode&&i&&i.nodeType===11&&i.childNodes.length===this.length?e={fragment:i}:e=f.buildFragment(a,this,k),h=e.fragment,h.childNodes.length===1?g=h=h.firstChild:g=h.firstChild;if(g){c=c&&f.nodeName(g,"tr");for(var l=0,m=this.length,n=m-1;l<m;l++)d.call(c?bi(this[l],g):this[l],e.cacheable||m>1&&l<n?f.clone(h,!0,!0):h)}k.length&&f.each(k,bp)}return this}}),f.buildFragment=function(a,b,d){var e,g,h,i,j=a[0];b&&b[0]&&(i=b[0].ownerDocument||b[0]),i.createDocumentFragment||(i=c),a.length===1&&typeof j=="string"&&j.length<512&&i===c&&j.charAt(0)==="<"&&!bb.test(j)&&(f.support.checkClone||!bd.test(j))&&(f.support.html5Clone||!bc.test(j))&&(g=!0,h=f.fragments[j],h&&h!==1&&(e=h)),e||(e=i.createDocumentFragment(),f.clean(a,i,e,d)),g&&(f.fragments[j]=h?e:1);return{fragment:e,cacheable:g}},f.fragments={},f.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(a,b){f.fn[a]=function(c){var d=[],e=f(c),g=this.length===1&&this[0].parentNode;if(g&&g.nodeType===11&&g.childNodes.length===1&&e.length===1){e[b](this[0]);return this}for(var h=0,i=e.length;h<i;h++){var j=(h>0?this.clone(!0):this).get();f(e[h])[b](j),d=d.concat(j)}return this.pushStack(d,a,e.selector)}}),f.extend({clone:function(a,b,c){var d,e,g,h=f.support.html5Clone||!bc.test("<"+a.nodeName)?a.cloneNode(!0):bo(a);if((!f.support.noCloneEvent||!f.support.noCloneChecked)&&(a.nodeType===1||a.nodeType===11)&&!f.isXMLDoc(a)){bk(a,h),d=bl(a),e=bl(h);for(g=0;d[g];++g)e[g]&&bk(d[g],e[g])}if(b){bj(a,h);if(c){d=bl(a),e=bl(h);for(g=0;d[g];++g)bj(d[g],e[g])}}d=e=null;return h},clean:function(a,b,d,e){var g;b=b||c,typeof b.createElement=="undefined"&&(b=b.ownerDocument||b[0]&&b[0].ownerDocument||c);var h=[],i;for(var j=0,k;(k=a[j])!=null;j++){typeof k=="number"&&(k+="");if(!k)continue;if(typeof k=="string")if(!_.test(k))k=b.createTextNode(k);else{k=k.replace(Y,"<$1></$2>");var l=(Z.exec(k)||["",""])[1].toLowerCase(),m=bg[l]||bg._default,n=m[0],o=b.createElement("div");b===c?bh.appendChild(o):U(b).appendChild(o),o.innerHTML=m[1]+k+m[2];while(n--)o=o.lastChild;if(!f.support.tbody){var p=$.test(k),q=l==="table"&&!p?o.firstChild&&o.firstChild.childNodes:m[1]==="<table>"&&!p?o.childNodes:[];for(i=q.length-1;i>=0;--i)f.nodeName(q[i],"tbody")&&!q[i].childNodes.length&&q[i].parentNode.removeChild(q[i])}!f.support.leadingWhitespace&&X.test(k)&&o.insertBefore(b.createTextNode(X.exec(k)[0]),o.firstChild),k=o.childNodes}var r;if(!f.support.appendChecked)if(k[0]&&typeof (r=k.length)=="number")for(i=0;i<r;i++)bn(k[i]);else bn(k);k.nodeType?h.push(k):h=f.merge(h,k)}if(d){g=function(a){return!a.type||be.test(a.type)};for(j=0;h[j];j++)if(e&&f.nodeName(h[j],"script")&&(!h[j].type||h[j].type.toLowerCase()==="text/javascript"))e.push(h[j].parentNode?h[j].parentNode.removeChild(h[j]):h[j]);else{if(h[j].nodeType===1){var s=f.grep(h[j].getElementsByTagName("script"),g);h.splice.apply(h,[j+1,0].concat(s))}d.appendChild(h[j])}}return h},cleanData:function(a){var b,c,d=f.cache,e=f.event.special,g=f.support.deleteExpando;for(var h=0,i;(i=a[h])!=null;h++){if(i.nodeName&&f.noData[i.nodeName.toLowerCase()])continue;c=i[f.expando];if(c){b=d[c];if(b&&b.events){for(var j in b.events)e[j]?f.event.remove(i,j):f.removeEvent(i,j,b.handle);b.handle&&(b.handle.elem=null)}g?delete i[f.expando]:i.removeAttribute&&i.removeAttribute(f.expando),delete d[c]}}}});var bq=/alpha\([^)]*\)/i,br=/opacity=([^)]*)/,bs=/([A-Z]|^ms)/g,bt=/^-?\d+(?:px)?$/i,bu=/^-?\d/,bv=/^([\-+])=([\-+.\de]+)/,bw={position:"absolute",visibility:"hidden",display:"block"},bx=["Left","Right"],by=["Top","Bottom"],bz,bA,bB;f.fn.css=function(a,c){if(arguments.length===2&&c===b)return this;return f.access(this,a,c,!0,function(a,c,d){return d!==b?f.style(a,c,d):f.css(a,c)})},f.extend({cssHooks:{opacity:{get:function(a,b){if(b){var c=bz(a,"opacity","opacity");return c===""?"1":c}return a.style.opacity}}},cssNumber:{fillOpacity:!0,fontWeight:!0,lineHeight:!0,opacity:!0,orphans:!0,widows:!0,zIndex:!0,zoom:!0},cssProps:{"float":f.support.cssFloat?"cssFloat":"styleFloat"},style:function(a,c,d,e){if(!!a&&a.nodeType!==3&&a.nodeType!==8&&!!a.style){var g,h,i=f.camelCase(c),j=a.style,k=f.cssHooks[i];c=f.cssProps[i]||i;if(d===b){if(k&&"get"in k&&(g=k.get(a,!1,e))!==b)return g;return j[c]}h=typeof d,h==="string"&&(g=bv.exec(d))&&(d=+(g[1]+1)*+g[2]+parseFloat(f.css(a,c)),h="number");if(d==null||h==="number"&&isNaN(d))return;h==="number"&&!f.cssNumber[i]&&(d+="px");if(!k||!("set"in k)||(d=k.set(a,d))!==b)try{j[c]=d}catch(l){}}},css:function(a,c,d){var e,g;c=f.camelCase(c),g=f.cssHooks[c],c=f.cssProps[c]||c,c==="cssFloat"&&(c="float");if(g&&"get"in g&&(e=g.get(a,!0,d))!==b)return e;if(bz)return bz(a,c)},swap:function(a,b,c){var d={};for(var e in b)d[e]=a.style[e],a.style[e]=b[e];c.call(a);for(e in b)a.style[e]=d[e]}}),f.curCSS=f.css,f.each(["height","width"],function(a,b){f.cssHooks[b]={get:function(a,c,d){var e;if(c){if(a.offsetWidth!==0)return bC(a,b,d);f.swap(a,bw,function(){e=bC(a,b,d)});return e}},set:function(a,b){if(!bt.test(b))return b;b=parseFloat(b);if(b>=0)return b+"px"}}}),f.support.opacity||(f.cssHooks.opacity={get:function(a,b){return br.test((b&&a.currentStyle?a.currentStyle.filter:a.style.filter)||"")?parseFloat(RegExp.$1)/100+"":b?"1":""},set:function(a,b){var c=a.style,d=a.currentStyle,e=f.isNumeric(b)?"alpha(opacity="+b*100+")":"",g=d&&d.filter||c.filter||"";c.zoom=1;if(b>=1&&f.trim(g.replace(bq,""))===""){c.removeAttribute("filter");if(d&&!d.filter)return}c.filter=bq.test(g)?g.replace(bq,e):g+" "+e}}),f(function(){f.support.reliableMarginRight||(f.cssHooks.marginRight={get:function(a,b){var c;f.swap(a,{display:"inline-block"},function(){b?c=bz(a,"margin-right","marginRight"):c=a.style.marginRight});return c}})}),c.defaultView&&c.defaultView.getComputedStyle&&(bA=function(a,b){var c,d,e;b=b.replace(bs,"-$1").toLowerCase(),(d=a.ownerDocument.defaultView)&&(e=d.getComputedStyle(a,null))&&(c=e.getPropertyValue(b),c===""&&!f.contains(a.ownerDocument.documentElement,a)&&(c=f.style(a,b)));return c}),c.documentElement.currentStyle&&(bB=function(a,b){var c,d,e,f=a.currentStyle&&a.currentStyle[b],g=a.style;f===null&&g&&(e=g[b])&&(f=e),!bt.test(f)&&bu.test(f)&&(c=g.left,d=a.runtimeStyle&&a.runtimeStyle.left,d&&(a.runtimeStyle.left=a.currentStyle.left),g.left=b==="fontSize"?"1em":f||0,f=g.pixelLeft+"px",g.left=c,d&&(a.runtimeStyle.left=d));return f===""?"auto":f}),bz=bA||bB,f.expr&&f.expr.filters&&(f.expr.filters.hidden=function(a){var b=a.offsetWidth,c=a.offsetHeight;return b===0&&c===0||!f.support.reliableHiddenOffsets&&(a.style&&a.style.display||f.css(a,"display"))==="none"},f.expr.filters.visible=function(a){return!f.expr.filters.hidden(a)});var bD=/%20/g,bE=/\[\]$/,bF=/\r?\n/g,bG=/#.*$/,bH=/^(.*?):[ \t]*([^\r\n]*)\r?$/mg,bI=/^(?:color|date|datetime|datetime-local|email|hidden|month|number|password|range|search|tel|text|time|url|week)$/i,bJ=/^(?:about|app|app\-storage|.+\-extension|file|res|widget):$/,bK=/^(?:GET|HEAD)$/,bL=/^\/\//,bM=/\?/,bN=/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,bO=/^(?:select|textarea)/i,bP=/\s+/,bQ=/([?&])_=[^&]*/,bR=/^([\w\+\.\-]+:)(?:\/\/([^\/?#:]*)(?::(\d+))?)?/,bS=f.fn.load,bT={},bU={},bV,bW,bX=["*/"]+["*"];try{bV=e.href}catch(bY){bV=c.createElement("a"),bV.href="",bV=bV.href}bW=bR.exec(bV.toLowerCase())||[],f.fn.extend({load:function(a,c,d){if(typeof a!="string"&&bS)return bS.apply(this,arguments);if(!this.length)return this;var e=a.indexOf(" ");if(e>=0){var g=a.slice(e,a.length);a=a.slice(0,e)}var h="GET";c&&(f.isFunction(c)?(d=c,c=b):typeof c=="object"&&(c=f.param(c,f.ajaxSettings.traditional),h="POST"));var i=this;f.ajax({url:a,type:h,dataType:"html",data:c,complete:function(a,b,c){c=a.responseText,a.isResolved()&&(a.done(function(a){c=a}),i.html(g?f("<div>").append(c.replace(bN,"")).find(g):c)),d&&i.each(d,[c,b,a])}});return this},serialize:function(){return f.param(this.serializeArray())},serializeArray:function(){return this.map(function(){return this.elements?f.makeArray(this.elements):this}).filter(function(){return this.name&&!this.disabled&&(this.checked||bO.test(this.nodeName)||bI.test(this.type))}).map(function(a,b){var c=f(this).val();return c==null?null:f.isArray(c)?f.map(c,function(a,c){return{name:b.name,value:a.replace(bF,"\r\n")}}):{name:b.name,value:c.replace(bF,"\r\n")}}).get()}}),f.each("ajaxStart ajaxStop ajaxComplete ajaxError ajaxSuccess ajaxSend".split(" "),function(a,b){f.fn[b]=function(a){return this.on(b,a)}}),f.each(["get","post"],function(a,c){f[c]=function(a,d,e,g){f.isFunction(d)&&(g=g||e,e=d,d=b);return f.ajax({type:c,url:a,data:d,success:e,dataType:g})}}),f.extend({getScript:function(a,c){return f.get(a,b,c,"script")},getJSON:function(a,b,c){return f.get(a,b,c,"json")},ajaxSetup:function(a,b){b?b_(a,f.ajaxSettings):(b=a,a=f.ajaxSettings),b_(a,b);return a},ajaxSettings:{url:bV,isLocal:bJ.test(bW[1]),global:!0,type:"GET",contentType:"application/x-www-form-urlencoded",processData:!0,async:!0,accepts:{xml:"application/xml, text/xml",html:"text/html",text:"text/plain",json:"application/json, text/javascript","*":bX},contents:{xml:/xml/,html:/html/,json:/json/},responseFields:{xml:"responseXML",text:"responseText"},converters:{"* text":a.String,"text html":!0,"text json":f.parseJSON,"text xml":f.parseXML},flatOptions:{context:!0,url:!0}},ajaxPrefilter:bZ(bT),ajaxTransport:bZ(bU),ajax:function(a,c){function w(a,c,l,m){if(s!==2){s=2,q&&clearTimeout(q),p=b,n=m||"",v.readyState=a>0?4:0;var o,r,u,w=c,x=l?cb(d,v,l):b,y,z;if(a>=200&&a<300||a===304){if(d.ifModified){if(y=v.getResponseHeader("Last-Modified"))f.lastModified[k]=y;if(z=v.getResponseHeader("Etag"))f.etag[k]=z}if(a===304)w="notmodified",o=!0;else try{r=cc(d,x),w="success",o=!0}catch(A){w="parsererror",u=A}}else{u=w;if(!w||a)w="error",a<0&&(a=0)}v.status=a,v.statusText=""+(c||w),o?h.resolveWith(e,[r,w,v]):h.rejectWith(e,[v,w,u]),v.statusCode(j),j=b,t&&g.trigger("ajax"+(o?"Success":"Error"),[v,d,o?r:u]),i.fireWith(e,[v,w]),t&&(g.trigger("ajaxComplete",[v,d]),--f.active||f.event.trigger("ajaxStop"))}}typeof a=="object"&&(c=a,a=b),c=c||{};var d=f.ajaxSetup({},c),e=d.context||d,g=e!==d&&(e.nodeType||e instanceof f)?f(e):f.event,h=f.Deferred(),i=f.Callbacks("once memory"),j=d.statusCode||{},k,l={},m={},n,o,p,q,r,s=0,t,u,v={readyState:0,setRequestHeader:function(a,b){if(!s){var c=a.toLowerCase();a=m[c]=m[c]||a,l[a]=b}return this},getAllResponseHeaders:function(){return s===2?n:null},getResponseHeader:function(a){var c;if(s===2){if(!o){o={};while(c=bH.exec(n))o[c[1].toLowerCase()]=c[2]}c=o[a.toLowerCase()]}return c===b?null:c},overrideMimeType:function(a){s||(d.mimeType=a);return this},abort:function(a){a=a||"abort",p&&p.abort(a),w(0,a);return this}};h.promise(v),v.success=v.done,v.error=v.fail,v.complete=i.add,v.statusCode=function(a){if(a){var b;if(s<2)for(b in a)j[b]=[j[b],a[b]];else b=a[v.status],v.then(b,b)}return this},d.url=((a||d.url)+"").replace(bG,"").replace(bL,bW[1]+"//"),d.dataTypes=f.trim(d.dataType||"*").toLowerCase().split(bP),d.crossDomain==null&&(r=bR.exec(d.url.toLowerCase()),d.crossDomain=!(!r||r[1]==bW[1]&&r[2]==bW[2]&&(r[3]||(r[1]==="http:"?80:443))==(bW[3]||(bW[1]==="http:"?80:443)))),d.data&&d.processData&&typeof d.data!="string"&&(d.data=f.param(d.data,d.traditional)),b$(bT,d,c,v);if(s===2)return!1;t=d.global,d.type=d.type.toUpperCase(),d.hasContent=!bK.test(d.type),t&&f.active++===0&&f.event.trigger("ajaxStart");if(!d.hasContent){d.data&&(d.url+=(bM.test(d.url)?"&":"?")+d.data,delete d.data),k=d.url;if(d.cache===!1){var x=f.now(),y=d.url.replace(bQ,"$1_="+x);d.url=y+(y===d.url?(bM.test(d.url)?"&":"?")+"_="+x:"")}}(d.data&&d.hasContent&&d.contentType!==!1||c.contentType)&&v.setRequestHeader("Content-Type",d.contentType),d.ifModified&&(k=k||d.url,f.lastModified[k]&&v.setRequestHeader("If-Modified-Since",f.lastModified[k]),f.etag[k]&&v.setRequestHeader("If-None-Match",f.etag[k])),v.setRequestHeader("Accept",d.dataTypes[0]&&d.accepts[d.dataTypes[0]]?d.accepts[d.dataTypes[0]]+(d.dataTypes[0]!=="*"?", "+bX+"; q=0.01":""):d.accepts["*"]);for(u in d.headers)v.setRequestHeader(u,d.headers[u]);if(d.beforeSend&&(d.beforeSend.call(e,v,d)===!1||s===2)){v.abort();return!1}for(u in{success:1,error:1,complete:1})v[u](d[u]);p=b$(bU,d,c,v);if(!p)w(-1,"No Transport");else{v.readyState=1,t&&g.trigger("ajaxSend",[v,d]),d.async&&d.timeout>0&&(q=setTimeout(function(){v.abort("timeout")},d.timeout));try{s=1,p.send(l,w)}catch(z){if(s<2)w(-1,z);else throw z}}return v},param:function(a,c){var d=[],e=function(a,b){b=f.isFunction(b)?b():b,d[d.length]=encodeURIComponent(a)+"="+encodeURIComponent(b)};c===b&&(c=f.ajaxSettings.traditional);if(f.isArray(a)||a.jquery&&!f.isPlainObject(a))f.each(a,function(){e(this.name,this.value)});else for(var g in a)ca(g,a[g],c,e);return d.join("&").replace(bD,"+")}}),f.extend({active:0,lastModified:{},etag:{}});var cd=f.now(),ce=/(\=)\?(&|$)|\?\?/i;f.ajaxSetup({jsonp:"callback",jsonpCallback:function(){return f.expando+"_"+cd++}}),f.ajaxPrefilter("json jsonp",function(b,c,d){var e=b.contentType==="application/x-www-form-urlencoded"&&typeof b.data=="string";if(b.dataTypes[0]==="jsonp"||b.jsonp!==!1&&(ce.test(b.url)||e&&ce.test(b.data))){var g,h=b.jsonpCallback=f.isFunction(b.jsonpCallback)?b.jsonpCallback():b.jsonpCallback,i=a[h],j=b.url,k=b.data,l="$1"+h+"$2";b.jsonp!==!1&&(j=j.replace(ce,l),b.url===j&&(e&&(k=k.replace(ce,l)),b.data===k&&(j+=(/\?/.test(j)?"&":"?")+b.jsonp+"="+h))),b.url=j,b.data=k,a[h]=function(a){g=[a]},d.always(function(){a[h]=i,g&&f.isFunction(i)&&a[h](g[0])}),b.converters["script json"]=function(){g||f.error(h+" was not called");return g[0]},b.dataTypes[0]="json";return"script"}}),f.ajaxSetup({accepts:{script:"text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"},contents:{script:/javascript|ecmascript/},converters:{"text script":function(a){f.globalEval(a);return a}}}),f.ajaxPrefilter("script",function(a){a.cache===b&&(a.cache=!1),a.crossDomain&&(a.type="GET",a.global=!1)}),f.ajaxTransport("script",function(a){if(a.crossDomain){var d,e=c.head||c.getElementsByTagName("head")[0]||c.documentElement;return{send:function(f,g){d=c.createElement("script"),d.async="async",a.scriptCharset&&(d.charset=a.scriptCharset),d.src=a.url,d.onload=d.onreadystatechange=function(a,c){if(c||!d.readyState||/loaded|complete/.test(d.readyState))d.onload=d.onreadystatechange=null,e&&d.parentNode&&e.removeChild(d),d=b,c||g(200,"success")},e.insertBefore(d,e.firstChild)},abort:function(){d&&d.onload(0,1)}}}});var cf=a.ActiveXObject?function(){for(var a in ch)ch[a](0,1)}:!1,cg=0,ch;f.ajaxSettings.xhr=a.ActiveXObject?function(){return!this.isLocal&&ci()||cj()}:ci,function(a){f.extend(f.support,{ajax:!!a,cors:!!a&&"withCredentials"in a})}(f.ajaxSettings.xhr()),f.support.ajax&&f.ajaxTransport(function(c){if(!c.crossDomain||f.support.cors){var d;return{send:function(e,g){var h=c.xhr(),i,j;c.username?h.open(c.type,c.url,c.async,c.username,c.password):h.open(c.type,c.url,c.async);if(c.xhrFields)for(j in c.xhrFields)h[j]=c.xhrFields[j];c.mimeType&&h.overrideMimeType&&h.overrideMimeType(c.mimeType),!c.crossDomain&&!e["X-Requested-With"]&&(e["X-Requested-With"]="XMLHttpRequest");try{for(j in e)h.setRequestHeader(j,e[j])}catch(k){}h.send(c.hasContent&&c.data||null),d=function(a,e){var j,k,l,m,n;try{if(d&&(e||h.readyState===4)){d=b,i&&(h.onreadystatechange=f.noop,cf&&delete ch[i]);if(e)h.readyState!==4&&h.abort();else{j=h.status,l=h.getAllResponseHeaders(),m={},n=h.responseXML,n&&n.documentElement&&(m.xml=n),m.text=h.responseText;try{k=h.statusText}catch(o){k=""}!j&&c.isLocal&&!c.crossDomain?j=m.text?200:404:j===1223&&(j=204)}}}catch(p){e||g(-1,p)}m&&g(j,k,m,l)},!c.async||h.readyState===4?d():(i=++cg,cf&&(ch||(ch={},f(a).unload(cf)),ch[i]=d),h.onreadystatechange=d)},abort:function(){d&&d(0,1)}}}});var ck={},cl,cm,cn=/^(?:toggle|show|hide)$/,co=/^([+\-]=)?([\d+.\-]+)([a-z%]*)$/i,cp,cq=[["height","marginTop","marginBottom","paddingTop","paddingBottom"],["width","marginLeft","marginRight","paddingLeft","paddingRight"],["opacity"]],cr;f.fn.extend({show:function(a,b,c){var d,e;if(a||a===0)return this.animate(cu("show",3),a,b,c);for(var g=0,h=this.length;g<h;g++)d=this[g],d.style&&(e=d.style.display,!f._data(d,"olddisplay")&&e==="none"&&(e=d.style.display=""),e===""&&f.css(d,"display")==="none"&&f._data(d,"olddisplay",cv(d.nodeName)));for(g=0;g<h;g++){d=this[g];if(d.style){e=d.style.display;if(e===""||e==="none")d.style.display=f._data(d,"olddisplay")||""}}return this},hide:function(a,b,c){if(a||a===0)return this.animate(cu("hide",3),a,b,c);var d,e,g=0,h=this.length;for(;g<h;g++)d=this[g],d.style&&(e=f.css(d,"display"),e!=="none"&&!f._data(d,"olddisplay")&&f._data(d,"olddisplay",e));for(g=0;g<h;g++)this[g].style&&(this[g].style.display="none");return this},_toggle:f.fn.toggle,toggle:function(a,b,c){var d=typeof a=="boolean";f.isFunction(a)&&f.isFunction(b)?this._toggle.apply(this,arguments):a==null||d?this.each(function(){var b=d?a:f(this).is(":hidden");f(this)[b?"show":"hide"]()}):this.animate(cu("toggle",3),a,b,c);return this},fadeTo:function(a,b,c,d){return this.filter(":hidden").css("opacity",0).show().end().animate({opacity:b},a,c,d)},animate:function(a,b,c,d){function g(){e.queue===!1&&f._mark(this);var b=f.extend({},e),c=this.nodeType===1,d=c&&f(this).is(":hidden"),g,h,i,j,k,l,m,n,o;b.animatedProperties={};for(i in a){g=f.camelCase(i),i!==g&&(a[g]=a[i],delete a[i]),h=a[g],f.isArray(h)?(b.animatedProperties[g]=h[1],h=a[g]=h[0]):b.animatedProperties[g]=b.specialEasing&&b.specialEasing[g]||b.easing||"swing";if(h==="hide"&&d||h==="show"&&!d)return b.complete.call(this);c&&(g==="height"||g==="width")&&(b.overflow=[this.style.overflow,this.style.overflowX,this.style.overflowY],f.css(this,"display")==="inline"&&f.css(this,"float")==="none"&&(!f.support.inlineBlockNeedsLayout||cv(this.nodeName)==="inline"?this.style.display="inline-block":this.style.zoom=1))}b.overflow!=null&&(this.style.overflow="hidden");for(i in a)j=new f.fx(this,b,i),h=a[i],cn.test(h)?(o=f._data(this,"toggle"+i)||(h==="toggle"?d?"show":"hide":0),o?(f._data(this,"toggle"+i,o==="show"?"hide":"show"),j[o]()):j[h]()):(k=co.exec(h),l=j.cur(),k?(m=parseFloat(k[2]),n=k[3]||(f.cssNumber[i]?"":"px"),n!=="px"&&(f.style(this,i,(m||1)+n),l=(m||1)/j.cur()*l,f.style(this,i,l+n)),k[1]&&(m=(k[1]==="-="?-1:1)*m+l),j.custom(l,m,n)):j.custom(l,h,""));return!0}var e=f.speed(b,c,d);if(f.isEmptyObject(a))return this.each(e.complete,[!1]);a=f.extend({},a);return e.queue===!1?this.each(g):this.queue(e.queue,g)},stop:function(a,c,d){typeof a!="string"&&(d=c,c=a,a=b),c&&a!==!1&&this.queue(a||"fx",[]);return this.each(function(){function h(a,b,c){var e=b[c];f.removeData(a,c,!0),e.stop(d)}var b,c=!1,e=f.timers,g=f._data(this);d||f._unmark(!0,this);if(a==null)for(b in g)g[b]&&g[b].stop&&b.indexOf(".run")===b.length-4&&h(this,g,b);else g[b=a+".run"]&&g[b].stop&&h(this,g,b);for(b=e.length;b--;)e[b].elem===this&&(a==null||e[b].queue===a)&&(d?e[b](!0):e[b].saveState(),c=!0,e.splice(b,1));(!d||!c)&&f.dequeue(this,a)})}}),f.each({slideDown:cu("show",1),slideUp:cu("hide",1),slideToggle:cu("toggle",1),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"},fadeToggle:{opacity:"toggle"}},function(a,b){f.fn[a]=function(a,c,d){return this.animate(b,a,c,d)}}),f.extend({speed:function(a,b,c){var d=a&&typeof a=="object"?f.extend({},a):{complete:c||!c&&b||f.isFunction(a)&&a,duration:a,easing:c&&b||b&&!f.isFunction(b)&&b};d.duration=f.fx.off?0:typeof d.duration=="number"?d.duration:d.duration in f.fx.speeds?f.fx.speeds[d.duration]:f.fx.speeds._default;if(d.queue==null||d.queue===!0)d.queue="fx";d.old=d.complete,d.complete=function(a){f.isFunction(d.old)&&d.old.call(this),d.queue?f.dequeue(this,d.queue):a!==!1&&f._unmark(this)};return d},easing:{linear:function(a,b,c,d){return c+d*a},swing:function(a,b,c,d){return(-Math.cos(a*Math.PI)/2+.5)*d+c}},timers:[],fx:function(a,b,c){this.options=b,this.elem=a,this.prop=c,b.orig=b.orig||{}}}),f.fx.prototype={update:function(){this.options.step&&this.options.step.call(this.elem,this.now,this),(f.fx.step[this.prop]||f.fx.step._default)(this)},cur:function(){if(this.elem[this.prop]!=null&&(!this.elem.style||this.elem.style[this.prop]==null))return this.elem[this.prop];var a,b=f.css(this.elem,this.prop);return isNaN(a=parseFloat(b))?!b||b==="auto"?0:b:a},custom:function(a,c,d){function h(a){return e.step(a)}var e=this,g=f.fx;this.startTime=cr||cs(),this.end=c,this.now=this.start=a,this.pos=this.state=0,this.unit=d||this.unit||(f.cssNumber[this.prop]?"":"px"),h.queue=this.options.queue,h.elem=this.elem,h.saveState=function(){e.options.hide&&f._data(e.elem,"fxshow"+e.prop)===b&&f._data(e.elem,"fxshow"+e.prop,e.start)},h()&&f.timers.push(h)&&!cp&&(cp=setInterval(g.tick,g.interval))},show:function(){var a=f._data(this.elem,"fxshow"+this.prop);this.options.orig[this.prop]=a||f.style(this.elem,this.prop),this.options.show=!0,a!==b?this.custom(this.cur(),a):this.custom(this.prop==="width"||this.prop==="height"?1:0,this.cur()),f(this.elem).show()},hide:function(){this.options.orig[this.prop]=f._data(this.elem,"fxshow"+this.prop)||f.style(this.elem,this.prop),this.options.hide=!0,this.custom(this.cur(),0)},step:function(a){var b,c,d,e=cr||cs(),g=!0,h=this.elem,i=this.options;if(a||e>=i.duration+this.startTime){this.now=this.end,this.pos=this.state=1,this.update(),i.animatedProperties[this.prop]=!0;for(b in i.animatedProperties)i.animatedProperties[b]!==!0&&(g=!1);if(g){i.overflow!=null&&!f.support.shrinkWrapBlocks&&f.each(["","X","Y"],function(a,b){h.style["overflow"+b]=i.overflow[a]}),i.hide&&f(h).hide();if(i.hide||i.show)for(b in i.animatedProperties)f.style(h,b,i.orig[b]),f.removeData(h,"fxshow"+b,!0),f.removeData(h,"toggle"+b,!0);d=i.complete,d&&(i.complete=!1,d.call(h))}return!1}i.duration==Infinity?this.now=e:(c=e-this.startTime,this.state=c/i.duration,this.pos=f.easing[i.animatedProperties[this.prop]](this.state,c,0,1,i.duration),this.now=this.start+(this.end-this.start)*this.pos),this.update();return!0}},f.extend(f.fx,{tick:function(){var a,b=f.timers,c=0;for(;c<b.length;c++)a=b[c],!a()&&b[c]===a&&b.splice(c--,1);b.length||f.fx.stop()},interval:13,stop:function(){clearInterval(cp),cp=null},speeds:{slow:600,fast:200,_default:400},step:{opacity:function(a){f.style(a.elem,"opacity",a.now)},_default:function(a){a.elem.style&&a.elem.style[a.prop]!=null?a.elem.style[a.prop]=a.now+a.unit:a.elem[a.prop]=a.now}}}),f.each(["width","height"],function(a,b){f.fx.step[b]=function(a){f.style(a.elem,b,Math.max(0,a.now)+a.unit)}}),f.expr&&f.expr.filters&&(f.expr.filters.animated=function(a){return f.grep(f.timers,function(b){return a===b.elem}).length});var cw=/^t(?:able|d|h)$/i,cx=/^(?:body|html)$/i;"getBoundingClientRect"in c.documentElement?f.fn.offset=function(a){var b=this[0],c;if(a)return this.each(function(b){f.offset.setOffset(this,a,b)});if(!b||!b.ownerDocument)return null;if(b===b.ownerDocument.body)return f.offset.bodyOffset(b);try{c=b.getBoundingClientRect()}catch(d){}var e=b.ownerDocument,g=e.documentElement;if(!c||!f.contains(g,b))return c?{top:c.top,left:c.left}:{top:0,left:0};var h=e.body,i=cy(e),j=g.clientTop||h.clientTop||0,k=g.clientLeft||h.clientLeft||0,l=i.pageYOffset||f.support.boxModel&&g.scrollTop||h.scrollTop,m=i.pageXOffset||f.support.boxModel&&g.scrollLeft||h.scrollLeft,n=c.top+l-j,o=c.left+m-k;return{top:n,left:o}}:f.fn.offset=function(a){var b=this[0];if(a)return this.each(function(b){f.offset.setOffset(this,a,b)});if(!b||!b.ownerDocument)return null;if(b===b.ownerDocument.body)return f.offset.bodyOffset(b);var c,d=b.offsetParent,e=b,g=b.ownerDocument,h=g.documentElement,i=g.body,j=g.defaultView,k=j?j.getComputedStyle(b,null):b.currentStyle,l=b.offsetTop,m=b.offsetLeft;while((b=b.parentNode)&&b!==i&&b!==h){if(f.support.fixedPosition&&k.position==="fixed")break;c=j?j.getComputedStyle(b,null):b.currentStyle,l-=b.scrollTop,m-=b.scrollLeft,b===d&&(l+=b.offsetTop,m+=b.offsetLeft,f.support.doesNotAddBorder&&(!f.support.doesAddBorderForTableAndCells||!cw.test(b.nodeName))&&(l+=parseFloat(c.borderTopWidth)||0,m+=parseFloat(c.borderLeftWidth)||0),e=d,d=b.offsetParent),f.support.subtractsBorderForOverflowNotVisible&&c.overflow!=="visible"&&(l+=parseFloat(c.borderTopWidth)||0,m+=parseFloat(c.borderLeftWidth)||0),k=c}if(k.position==="relative"||k.position==="static")l+=i.offsetTop,m+=i.offsetLeft;f.support.fixedPosition&&k.position==="fixed"&&(l+=Math.max(h.scrollTop,i.scrollTop),m+=Math.max(h.scrollLeft,i.scrollLeft));return{top:l,left:m}},f.offset={bodyOffset:function(a){var b=a.offsetTop,c=a.offsetLeft;f.support.doesNotIncludeMarginInBodyOffset&&(b+=parseFloat(f.css(a,"marginTop"))||0,c+=parseFloat(f.css(a,"marginLeft"))||0);return{top:b,left:c}},setOffset:function(a,b,c){var d=f.css(a,"position");d==="static"&&(a.style.position="relative");var e=f(a),g=e.offset(),h=f.css(a,"top"),i=f.css(a,"left"),j=(d==="absolute"||d==="fixed")&&f.inArray("auto",[h,i])>-1,k={},l={},m,n;j?(l=e.position(),m=l.top,n=l.left):(m=parseFloat(h)||0,n=parseFloat(i)||0),f.isFunction(b)&&(b=b.call(a,c,g)),b.top!=null&&(k.top=b.top-g.top+m),b.left!=null&&(k.left=b.left-g.left+n),"using"in b?b.using.call(a,k):e.css(k)}},f.fn.extend({position:function(){if(!this[0])return null;var a=this[0],b=this.offsetParent(),c=this.offset(),d=cx.test(b[0].nodeName)?{top:0,left:0}:b.offset();c.top-=parseFloat(f.css(a,"marginTop"))||0,c.left-=parseFloat(f.css(a,"marginLeft"))||0,d.top+=parseFloat(f.css(b[0],"borderTopWidth"))||0,d.left+=parseFloat(f.css(b[0],"borderLeftWidth"))||0;return{top:c.top-d.top,left:c.left-d.left}},offsetParent:function(){return this.map(function(){var a=this.offsetParent||c.body;while(a&&!cx.test(a.nodeName)&&f.css(a,"position")==="static")a=a.offsetParent;return a})}}),f.each(["Left","Top"],function(a,c){var d="scroll"+c;f.fn[d]=function(c){var e,g;if(c===b){e=this[0];if(!e)return null;g=cy(e);return g?"pageXOffset"in g?g[a?"pageYOffset":"pageXOffset"]:f.support.boxModel&&g.document.documentElement[d]||g.document.body[d]:e[d]}return this.each(function(){g=cy(this),g?g.scrollTo(a?f(g).scrollLeft():c,a?c:f(g).scrollTop()):this[d]=c})}}),f.each(["Height","Width"],function(a,c){var d=c.toLowerCase();f.fn["inner"+c]=function(){var a=this[0];return a?a.style?parseFloat(f.css(a,d,"padding")):this[d]():null},f.fn["outer"+c]=function(a){var b=this[0];return b?b.style?parseFloat(f.css(b,d,a?"margin":"border")):this[d]():null},f.fn[d]=function(a){var e=this[0];if(!e)return a==null?null:this;if(f.isFunction(a))return this.each(function(b){var c=f(this);c[d](a.call(this,b,c[d]()))});if(f.isWindow(e)){var g=e.document.documentElement["client"+c],h=e.document.body;return e.document.compatMode==="CSS1Compat"&&g||h&&h["client"+c]||g}if(e.nodeType===9)return Math.max(e.documentElement["client"+c],e.body["scroll"+c],e.documentElement["scroll"+c],e.body["offset"+c],e.documentElement["offset"+c]);if(a===b){var i=f.css(e,d),j=parseFloat(i);return f.isNumeric(j)?j:i}return this.css(d,typeof a=="string"?a:a+"px")}}),a.jQuery=a.$=f,typeof define=="function"&&define.amd&&define.amd.jQuery&&define("jquery",[],function(){return f})})(window);



/*! jQuery UI - v1.10.2 - 2013-04-29
* http://jqueryui.com
* Includes: jquery.ui.core.js, jquery.ui.widget.js, jquery.ui.mouse.js, jquery.ui.position.js, jquery.ui.draggable.js, jquery.ui.resizable.js, jquery.ui.sortable.js
* Copyright 2013 jQuery Foundation and other contributors Licensed MIT */

(function(e,t){function i(t,i){var a,n,r,o=t.nodeName.toLowerCase();return"area"===o?(a=t.parentNode,n=a.name,t.href&&n&&"map"===a.nodeName.toLowerCase()?(r=e("img[usemap=#"+n+"]")[0],!!r&&s(r)):!1):(/input|select|textarea|button|object/.test(o)?!t.disabled:"a"===o?t.href||i:i)&&s(t)}function s(t){return e.expr.filters.visible(t)&&!e(t).parents().addBack().filter(function(){return"hidden"===e.css(this,"visibility")}).length}var a=0,n=/^ui-id-\d+$/;e.ui=e.ui||{},e.extend(e.ui,{version:"1.10.2",keyCode:{BACKSPACE:8,COMMA:188,DELETE:46,DOWN:40,END:35,ENTER:13,ESCAPE:27,HOME:36,LEFT:37,NUMPAD_ADD:107,NUMPAD_DECIMAL:110,NUMPAD_DIVIDE:111,NUMPAD_ENTER:108,NUMPAD_MULTIPLY:106,NUMPAD_SUBTRACT:109,PAGE_DOWN:34,PAGE_UP:33,PERIOD:190,RIGHT:39,SPACE:32,TAB:9,UP:38}}),e.fn.extend({focus:function(t){return function(i,s){return"number"==typeof i?this.each(function(){var t=this;setTimeout(function(){e(t).focus(),s&&s.call(t)},i)}):t.apply(this,arguments)}}(e.fn.focus),scrollParent:function(){var t;return t=e.ui.ie&&/(static|relative)/.test(this.css("position"))||/absolute/.test(this.css("position"))?this.parents().filter(function(){return/(relative|absolute|fixed)/.test(e.css(this,"position"))&&/(auto|scroll)/.test(e.css(this,"overflow")+e.css(this,"overflow-y")+e.css(this,"overflow-x"))}).eq(0):this.parents().filter(function(){return/(auto|scroll)/.test(e.css(this,"overflow")+e.css(this,"overflow-y")+e.css(this,"overflow-x"))}).eq(0),/fixed/.test(this.css("position"))||!t.length?e(document):t},zIndex:function(i){if(i!==t)return this.css("zIndex",i);if(this.length)for(var s,a,n=e(this[0]);n.length&&n[0]!==document;){if(s=n.css("position"),("absolute"===s||"relative"===s||"fixed"===s)&&(a=parseInt(n.css("zIndex"),10),!isNaN(a)&&0!==a))return a;n=n.parent()}return 0},uniqueId:function(){return this.each(function(){this.id||(this.id="ui-id-"+ ++a)})},removeUniqueId:function(){return this.each(function(){n.test(this.id)&&e(this).removeAttr("id")})}}),e.extend(e.expr[":"],{data:e.expr.createPseudo?e.expr.createPseudo(function(t){return function(i){return!!e.data(i,t)}}):function(t,i,s){return!!e.data(t,s[3])},focusable:function(t){return i(t,!isNaN(e.attr(t,"tabindex")))},tabbable:function(t){var s=e.attr(t,"tabindex"),a=isNaN(s);return(a||s>=0)&&i(t,!a)}}),e("<a>").outerWidth(1).jquery||e.each(["Width","Height"],function(i,s){function a(t,i,s,a){return e.each(n,function(){i-=parseFloat(e.css(t,"padding"+this))||0,s&&(i-=parseFloat(e.css(t,"border"+this+"Width"))||0),a&&(i-=parseFloat(e.css(t,"margin"+this))||0)}),i}var n="Width"===s?["Left","Right"]:["Top","Bottom"],r=s.toLowerCase(),o={innerWidth:e.fn.innerWidth,innerHeight:e.fn.innerHeight,outerWidth:e.fn.outerWidth,outerHeight:e.fn.outerHeight};e.fn["inner"+s]=function(i){return i===t?o["inner"+s].call(this):this.each(function(){e(this).css(r,a(this,i)+"px")})},e.fn["outer"+s]=function(t,i){return"number"!=typeof t?o["outer"+s].call(this,t):this.each(function(){e(this).css(r,a(this,t,!0,i)+"px")})}}),e.fn.addBack||(e.fn.addBack=function(e){return this.add(null==e?this.prevObject:this.prevObject.filter(e))}),e("<a>").data("a-b","a").removeData("a-b").data("a-b")&&(e.fn.removeData=function(t){return function(i){return arguments.length?t.call(this,e.camelCase(i)):t.call(this)}}(e.fn.removeData)),e.ui.ie=!!/msie [\w.]+/.exec(navigator.userAgent.toLowerCase()),e.support.selectstart="onselectstart"in document.createElement("div"),e.fn.extend({disableSelection:function(){return this.bind((e.support.selectstart?"selectstart":"mousedown")+".ui-disableSelection",function(e){e.preventDefault()})},enableSelection:function(){return this.unbind(".ui-disableSelection")}}),e.extend(e.ui,{plugin:{add:function(t,i,s){var a,n=e.ui[t].prototype;for(a in s)n.plugins[a]=n.plugins[a]||[],n.plugins[a].push([i,s[a]])},call:function(e,t,i){var s,a=e.plugins[t];if(a&&e.element[0].parentNode&&11!==e.element[0].parentNode.nodeType)for(s=0;a.length>s;s++)e.options[a[s][0]]&&a[s][1].apply(e.element,i)}},hasScroll:function(t,i){if("hidden"===e(t).css("overflow"))return!1;var s=i&&"left"===i?"scrollLeft":"scrollTop",a=!1;return t[s]>0?!0:(t[s]=1,a=t[s]>0,t[s]=0,a)}})})(jQuery);(function(e,t){var i=0,s=Array.prototype.slice,n=e.cleanData;e.cleanData=function(t){for(var i,s=0;null!=(i=t[s]);s++)try{e(i).triggerHandler("remove")}catch(a){}n(t)},e.widget=function(i,s,n){var a,r,o,h,l={},u=i.split(".")[0];i=i.split(".")[1],a=u+"-"+i,n||(n=s,s=e.Widget),e.expr[":"][a.toLowerCase()]=function(t){return!!e.data(t,a)},e[u]=e[u]||{},r=e[u][i],o=e[u][i]=function(e,i){return this._createWidget?(arguments.length&&this._createWidget(e,i),t):new o(e,i)},e.extend(o,r,{version:n.version,_proto:e.extend({},n),_childConstructors:[]}),h=new s,h.options=e.widget.extend({},h.options),e.each(n,function(i,n){return e.isFunction(n)?(l[i]=function(){var e=function(){return s.prototype[i].apply(this,arguments)},t=function(e){return s.prototype[i].apply(this,e)};return function(){var i,s=this._super,a=this._superApply;return this._super=e,this._superApply=t,i=n.apply(this,arguments),this._super=s,this._superApply=a,i}}(),t):(l[i]=n,t)}),o.prototype=e.widget.extend(h,{widgetEventPrefix:r?h.widgetEventPrefix:i},l,{constructor:o,namespace:u,widgetName:i,widgetFullName:a}),r?(e.each(r._childConstructors,function(t,i){var s=i.prototype;e.widget(s.namespace+"."+s.widgetName,o,i._proto)}),delete r._childConstructors):s._childConstructors.push(o),e.widget.bridge(i,o)},e.widget.extend=function(i){for(var n,a,r=s.call(arguments,1),o=0,h=r.length;h>o;o++)for(n in r[o])a=r[o][n],r[o].hasOwnProperty(n)&&a!==t&&(i[n]=e.isPlainObject(a)?e.isPlainObject(i[n])?e.widget.extend({},i[n],a):e.widget.extend({},a):a);return i},e.widget.bridge=function(i,n){var a=n.prototype.widgetFullName||i;e.fn[i]=function(r){var o="string"==typeof r,h=s.call(arguments,1),l=this;return r=!o&&h.length?e.widget.extend.apply(null,[r].concat(h)):r,o?this.each(function(){var s,n=e.data(this,a);return n?e.isFunction(n[r])&&"_"!==r.charAt(0)?(s=n[r].apply(n,h),s!==n&&s!==t?(l=s&&s.jquery?l.pushStack(s.get()):s,!1):t):e.error("no such method '"+r+"' for "+i+" widget instance"):e.error("cannot call methods on "+i+" prior to initialization; "+"attempted to call method '"+r+"'")}):this.each(function(){var t=e.data(this,a);t?t.option(r||{})._init():e.data(this,a,new n(r,this))}),l}},e.Widget=function(){},e.Widget._childConstructors=[],e.Widget.prototype={widgetName:"widget",widgetEventPrefix:"",defaultElement:"<div>",options:{disabled:!1,create:null},_createWidget:function(t,s){s=e(s||this.defaultElement||this)[0],this.element=e(s),this.uuid=i++,this.eventNamespace="."+this.widgetName+this.uuid,this.options=e.widget.extend({},this.options,this._getCreateOptions(),t),this.bindings=e(),this.hoverable=e(),this.focusable=e(),s!==this&&(e.data(s,this.widgetFullName,this),this._on(!0,this.element,{remove:function(e){e.target===s&&this.destroy()}}),this.document=e(s.style?s.ownerDocument:s.document||s),this.window=e(this.document[0].defaultView||this.document[0].parentWindow)),this._create(),this._trigger("create",null,this._getCreateEventData()),this._init()},_getCreateOptions:e.noop,_getCreateEventData:e.noop,_create:e.noop,_init:e.noop,destroy:function(){this._destroy(),this.element.unbind(this.eventNamespace).removeData(this.widgetName).removeData(this.widgetFullName).removeData(e.camelCase(this.widgetFullName)),this.widget().unbind(this.eventNamespace).removeAttr("aria-disabled").removeClass(this.widgetFullName+"-disabled "+"ui-state-disabled"),this.bindings.unbind(this.eventNamespace),this.hoverable.removeClass("ui-state-hover"),this.focusable.removeClass("ui-state-focus")},_destroy:e.noop,widget:function(){return this.element},option:function(i,s){var n,a,r,o=i;if(0===arguments.length)return e.widget.extend({},this.options);if("string"==typeof i)if(o={},n=i.split("."),i=n.shift(),n.length){for(a=o[i]=e.widget.extend({},this.options[i]),r=0;n.length-1>r;r++)a[n[r]]=a[n[r]]||{},a=a[n[r]];if(i=n.pop(),s===t)return a[i]===t?null:a[i];a[i]=s}else{if(s===t)return this.options[i]===t?null:this.options[i];o[i]=s}return this._setOptions(o),this},_setOptions:function(e){var t;for(t in e)this._setOption(t,e[t]);return this},_setOption:function(e,t){return this.options[e]=t,"disabled"===e&&(this.widget().toggleClass(this.widgetFullName+"-disabled ui-state-disabled",!!t).attr("aria-disabled",t),this.hoverable.removeClass("ui-state-hover"),this.focusable.removeClass("ui-state-focus")),this},enable:function(){return this._setOption("disabled",!1)},disable:function(){return this._setOption("disabled",!0)},_on:function(i,s,n){var a,r=this;"boolean"!=typeof i&&(n=s,s=i,i=!1),n?(s=a=e(s),this.bindings=this.bindings.add(s)):(n=s,s=this.element,a=this.widget()),e.each(n,function(n,o){function h(){return i||r.options.disabled!==!0&&!e(this).hasClass("ui-state-disabled")?("string"==typeof o?r[o]:o).apply(r,arguments):t}"string"!=typeof o&&(h.guid=o.guid=o.guid||h.guid||e.guid++);var l=n.match(/^(\w+)\s*(.*)$/),u=l[1]+r.eventNamespace,c=l[2];c?a.delegate(c,u,h):s.bind(u,h)})},_off:function(e,t){t=(t||"").split(" ").join(this.eventNamespace+" ")+this.eventNamespace,e.unbind(t).undelegate(t)},_delay:function(e,t){function i(){return("string"==typeof e?s[e]:e).apply(s,arguments)}var s=this;return setTimeout(i,t||0)},_hoverable:function(t){this.hoverable=this.hoverable.add(t),this._on(t,{mouseenter:function(t){e(t.currentTarget).addClass("ui-state-hover")},mouseleave:function(t){e(t.currentTarget).removeClass("ui-state-hover")}})},_focusable:function(t){this.focusable=this.focusable.add(t),this._on(t,{focusin:function(t){e(t.currentTarget).addClass("ui-state-focus")},focusout:function(t){e(t.currentTarget).removeClass("ui-state-focus")}})},_trigger:function(t,i,s){var n,a,r=this.options[t];if(s=s||{},i=e.Event(i),i.type=(t===this.widgetEventPrefix?t:this.widgetEventPrefix+t).toLowerCase(),i.target=this.element[0],a=i.originalEvent)for(n in a)n in i||(i[n]=a[n]);return this.element.trigger(i,s),!(e.isFunction(r)&&r.apply(this.element[0],[i].concat(s))===!1||i.isDefaultPrevented())}},e.each({show:"fadeIn",hide:"fadeOut"},function(t,i){e.Widget.prototype["_"+t]=function(s,n,a){"string"==typeof n&&(n={effect:n});var r,o=n?n===!0||"number"==typeof n?i:n.effect||i:t;n=n||{},"number"==typeof n&&(n={duration:n}),r=!e.isEmptyObject(n),n.complete=a,n.delay&&s.delay(n.delay),r&&e.effects&&e.effects.effect[o]?s[t](n):o!==t&&s[o]?s[o](n.duration,n.easing,a):s.queue(function(i){e(this)[t](),a&&a.call(s[0]),i()})}})})(jQuery);(function(e){var t=!1;e(document).mouseup(function(){t=!1}),e.widget("ui.mouse",{version:"1.10.2",options:{cancel:"input,textarea,button,select,option",distance:1,delay:0},_mouseInit:function(){var t=this;this.element.bind("mousedown."+this.widgetName,function(e){return t._mouseDown(e)}).bind("click."+this.widgetName,function(i){return!0===e.data(i.target,t.widgetName+".preventClickEvent")?(e.removeData(i.target,t.widgetName+".preventClickEvent"),i.stopImmediatePropagation(),!1):undefined}),this.started=!1},_mouseDestroy:function(){this.element.unbind("."+this.widgetName),this._mouseMoveDelegate&&e(document).unbind("mousemove."+this.widgetName,this._mouseMoveDelegate).unbind("mouseup."+this.widgetName,this._mouseUpDelegate)},_mouseDown:function(i){if(!t){this._mouseStarted&&this._mouseUp(i),this._mouseDownEvent=i;var s=this,n=1===i.which,a="string"==typeof this.options.cancel&&i.target.nodeName?e(i.target).closest(this.options.cancel).length:!1;return n&&!a&&this._mouseCapture(i)?(this.mouseDelayMet=!this.options.delay,this.mouseDelayMet||(this._mouseDelayTimer=setTimeout(function(){s.mouseDelayMet=!0},this.options.delay)),this._mouseDistanceMet(i)&&this._mouseDelayMet(i)&&(this._mouseStarted=this._mouseStart(i)!==!1,!this._mouseStarted)?(i.preventDefault(),!0):(!0===e.data(i.target,this.widgetName+".preventClickEvent")&&e.removeData(i.target,this.widgetName+".preventClickEvent"),this._mouseMoveDelegate=function(e){return s._mouseMove(e)},this._mouseUpDelegate=function(e){return s._mouseUp(e)},e(document).bind("mousemove."+this.widgetName,this._mouseMoveDelegate).bind("mouseup."+this.widgetName,this._mouseUpDelegate),i.preventDefault(),t=!0,!0)):!0}},_mouseMove:function(t){return e.ui.ie&&(!document.documentMode||9>document.documentMode)&&!t.button?this._mouseUp(t):this._mouseStarted?(this._mouseDrag(t),t.preventDefault()):(this._mouseDistanceMet(t)&&this._mouseDelayMet(t)&&(this._mouseStarted=this._mouseStart(this._mouseDownEvent,t)!==!1,this._mouseStarted?this._mouseDrag(t):this._mouseUp(t)),!this._mouseStarted)},_mouseUp:function(t){return e(document).unbind("mousemove."+this.widgetName,this._mouseMoveDelegate).unbind("mouseup."+this.widgetName,this._mouseUpDelegate),this._mouseStarted&&(this._mouseStarted=!1,t.target===this._mouseDownEvent.target&&e.data(t.target,this.widgetName+".preventClickEvent",!0),this._mouseStop(t)),!1},_mouseDistanceMet:function(e){return Math.max(Math.abs(this._mouseDownEvent.pageX-e.pageX),Math.abs(this._mouseDownEvent.pageY-e.pageY))>=this.options.distance},_mouseDelayMet:function(){return this.mouseDelayMet},_mouseStart:function(){},_mouseDrag:function(){},_mouseStop:function(){},_mouseCapture:function(){return!0}})})(jQuery);(function(t,e){function i(t,e,i){return[parseFloat(t[0])*(p.test(t[0])?e/100:1),parseFloat(t[1])*(p.test(t[1])?i/100:1)]}function s(e,i){return parseInt(t.css(e,i),10)||0}function n(e){var i=e[0];return 9===i.nodeType?{width:e.width(),height:e.height(),offset:{top:0,left:0}}:t.isWindow(i)?{width:e.width(),height:e.height(),offset:{top:e.scrollTop(),left:e.scrollLeft()}}:i.preventDefault?{width:0,height:0,offset:{top:i.pageY,left:i.pageX}}:{width:e.outerWidth(),height:e.outerHeight(),offset:e.offset()}}t.ui=t.ui||{};var a,o=Math.max,r=Math.abs,h=Math.round,l=/left|center|right/,c=/top|center|bottom/,u=/[\+\-]\d+(\.[\d]+)?%?/,d=/^\w+/,p=/%$/,f=t.fn.position;t.position={scrollbarWidth:function(){if(a!==e)return a;var i,s,n=t("<div style='display:block;width:50px;height:50px;overflow:hidden;'><div style='height:100px;width:auto;'></div></div>"),o=n.children()[0];return t("body").append(n),i=o.offsetWidth,n.css("overflow","scroll"),s=o.offsetWidth,i===s&&(s=n[0].clientWidth),n.remove(),a=i-s},getScrollInfo:function(e){var i=e.isWindow?"":e.element.css("overflow-x"),s=e.isWindow?"":e.element.css("overflow-y"),n="scroll"===i||"auto"===i&&e.width<e.element[0].scrollWidth,a="scroll"===s||"auto"===s&&e.height<e.element[0].scrollHeight;return{width:a?t.position.scrollbarWidth():0,height:n?t.position.scrollbarWidth():0}},getWithinInfo:function(e){var i=t(e||window),s=t.isWindow(i[0]);return{element:i,isWindow:s,offset:i.offset()||{left:0,top:0},scrollLeft:i.scrollLeft(),scrollTop:i.scrollTop(),width:s?i.width():i.outerWidth(),height:s?i.height():i.outerHeight()}}},t.fn.position=function(e){if(!e||!e.of)return f.apply(this,arguments);e=t.extend({},e);var a,p,m,g,v,_,b=t(e.of),y=t.position.getWithinInfo(e.within),w=t.position.getScrollInfo(y),x=(e.collision||"flip").split(" "),k={};return _=n(b),b[0].preventDefault&&(e.at="left top"),p=_.width,m=_.height,g=_.offset,v=t.extend({},g),t.each(["my","at"],function(){var t,i,s=(e[this]||"").split(" ");1===s.length&&(s=l.test(s[0])?s.concat(["center"]):c.test(s[0])?["center"].concat(s):["center","center"]),s[0]=l.test(s[0])?s[0]:"center",s[1]=c.test(s[1])?s[1]:"center",t=u.exec(s[0]),i=u.exec(s[1]),k[this]=[t?t[0]:0,i?i[0]:0],e[this]=[d.exec(s[0])[0],d.exec(s[1])[0]]}),1===x.length&&(x[1]=x[0]),"right"===e.at[0]?v.left+=p:"center"===e.at[0]&&(v.left+=p/2),"bottom"===e.at[1]?v.top+=m:"center"===e.at[1]&&(v.top+=m/2),a=i(k.at,p,m),v.left+=a[0],v.top+=a[1],this.each(function(){var n,l,c=t(this),u=c.outerWidth(),d=c.outerHeight(),f=s(this,"marginLeft"),_=s(this,"marginTop"),D=u+f+s(this,"marginRight")+w.width,T=d+_+s(this,"marginBottom")+w.height,C=t.extend({},v),M=i(k.my,c.outerWidth(),c.outerHeight());"right"===e.my[0]?C.left-=u:"center"===e.my[0]&&(C.left-=u/2),"bottom"===e.my[1]?C.top-=d:"center"===e.my[1]&&(C.top-=d/2),C.left+=M[0],C.top+=M[1],t.support.offsetFractions||(C.left=h(C.left),C.top=h(C.top)),n={marginLeft:f,marginTop:_},t.each(["left","top"],function(i,s){t.ui.position[x[i]]&&t.ui.position[x[i]][s](C,{targetWidth:p,targetHeight:m,elemWidth:u,elemHeight:d,collisionPosition:n,collisionWidth:D,collisionHeight:T,offset:[a[0]+M[0],a[1]+M[1]],my:e.my,at:e.at,within:y,elem:c})}),e.using&&(l=function(t){var i=g.left-C.left,s=i+p-u,n=g.top-C.top,a=n+m-d,h={target:{element:b,left:g.left,top:g.top,width:p,height:m},element:{element:c,left:C.left,top:C.top,width:u,height:d},horizontal:0>s?"left":i>0?"right":"center",vertical:0>a?"top":n>0?"bottom":"middle"};u>p&&p>r(i+s)&&(h.horizontal="center"),d>m&&m>r(n+a)&&(h.vertical="middle"),h.important=o(r(i),r(s))>o(r(n),r(a))?"horizontal":"vertical",e.using.call(this,t,h)}),c.offset(t.extend(C,{using:l}))})},t.ui.position={fit:{left:function(t,e){var i,s=e.within,n=s.isWindow?s.scrollLeft:s.offset.left,a=s.width,r=t.left-e.collisionPosition.marginLeft,h=n-r,l=r+e.collisionWidth-a-n;e.collisionWidth>a?h>0&&0>=l?(i=t.left+h+e.collisionWidth-a-n,t.left+=h-i):t.left=l>0&&0>=h?n:h>l?n+a-e.collisionWidth:n:h>0?t.left+=h:l>0?t.left-=l:t.left=o(t.left-r,t.left)},top:function(t,e){var i,s=e.within,n=s.isWindow?s.scrollTop:s.offset.top,a=e.within.height,r=t.top-e.collisionPosition.marginTop,h=n-r,l=r+e.collisionHeight-a-n;e.collisionHeight>a?h>0&&0>=l?(i=t.top+h+e.collisionHeight-a-n,t.top+=h-i):t.top=l>0&&0>=h?n:h>l?n+a-e.collisionHeight:n:h>0?t.top+=h:l>0?t.top-=l:t.top=o(t.top-r,t.top)}},flip:{left:function(t,e){var i,s,n=e.within,a=n.offset.left+n.scrollLeft,o=n.width,h=n.isWindow?n.scrollLeft:n.offset.left,l=t.left-e.collisionPosition.marginLeft,c=l-h,u=l+e.collisionWidth-o-h,d="left"===e.my[0]?-e.elemWidth:"right"===e.my[0]?e.elemWidth:0,p="left"===e.at[0]?e.targetWidth:"right"===e.at[0]?-e.targetWidth:0,f=-2*e.offset[0];0>c?(i=t.left+d+p+f+e.collisionWidth-o-a,(0>i||r(c)>i)&&(t.left+=d+p+f)):u>0&&(s=t.left-e.collisionPosition.marginLeft+d+p+f-h,(s>0||u>r(s))&&(t.left+=d+p+f))},top:function(t,e){var i,s,n=e.within,a=n.offset.top+n.scrollTop,o=n.height,h=n.isWindow?n.scrollTop:n.offset.top,l=t.top-e.collisionPosition.marginTop,c=l-h,u=l+e.collisionHeight-o-h,d="top"===e.my[1],p=d?-e.elemHeight:"bottom"===e.my[1]?e.elemHeight:0,f="top"===e.at[1]?e.targetHeight:"bottom"===e.at[1]?-e.targetHeight:0,m=-2*e.offset[1];0>c?(s=t.top+p+f+m+e.collisionHeight-o-a,t.top+p+f+m>c&&(0>s||r(c)>s)&&(t.top+=p+f+m)):u>0&&(i=t.top-e.collisionPosition.marginTop+p+f+m-h,t.top+p+f+m>u&&(i>0||u>r(i))&&(t.top+=p+f+m))}},flipfit:{left:function(){t.ui.position.flip.left.apply(this,arguments),t.ui.position.fit.left.apply(this,arguments)},top:function(){t.ui.position.flip.top.apply(this,arguments),t.ui.position.fit.top.apply(this,arguments)}}},function(){var e,i,s,n,a,o=document.getElementsByTagName("body")[0],r=document.createElement("div");e=document.createElement(o?"div":"body"),s={visibility:"hidden",width:0,height:0,border:0,margin:0,background:"none"},o&&t.extend(s,{position:"absolute",left:"-1000px",top:"-1000px"});for(a in s)e.style[a]=s[a];e.appendChild(r),i=o||document.documentElement,i.insertBefore(e,i.firstChild),r.style.cssText="position: absolute; left: 10.7432222px;",n=t(r).offset().left,t.support.offsetFractions=n>10&&11>n,e.innerHTML="",i.removeChild(e)}()})(jQuery);(function(e){e.widget("ui.draggable",e.ui.mouse,{version:"1.10.2",widgetEventPrefix:"drag",options:{addClasses:!0,appendTo:"parent",axis:!1,connectToSortable:!1,containment:!1,cursor:"auto",cursorAt:!1,grid:!1,handle:!1,helper:"original",iframeFix:!1,opacity:!1,refreshPositions:!1,revert:!1,revertDuration:500,scope:"default",scroll:!0,scrollSensitivity:20,scrollSpeed:20,snap:!1,snapMode:"both",snapTolerance:20,stack:!1,zIndex:!1,drag:null,start:null,stop:null},_create:function(){"original"!==this.options.helper||/^(?:r|a|f)/.test(this.element.css("position"))||(this.element[0].style.position="relative"),this.options.addClasses&&this.element.addClass("ui-draggable"),this.options.disabled&&this.element.addClass("ui-draggable-disabled"),this._mouseInit()},_destroy:function(){this.element.removeClass("ui-draggable ui-draggable-dragging ui-draggable-disabled"),this._mouseDestroy()},_mouseCapture:function(t){var i=this.options;return this.helper||i.disabled||e(t.target).closest(".ui-resizable-handle").length>0?!1:(this.handle=this._getHandle(t),this.handle?(e(i.iframeFix===!0?"iframe":i.iframeFix).each(function(){e("<div class='ui-draggable-iframeFix' style='background: #fff;'></div>").css({width:this.offsetWidth+"px",height:this.offsetHeight+"px",position:"absolute",opacity:"0.001",zIndex:1e3}).css(e(this).offset()).appendTo("body")}),!0):!1)},_mouseStart:function(t){var i=this.options;return this.helper=this._createHelper(t),this.helper.addClass("ui-draggable-dragging"),this._cacheHelperProportions(),e.ui.ddmanager&&(e.ui.ddmanager.current=this),this._cacheMargins(),this.cssPosition=this.helper.css("position"),this.scrollParent=this.helper.scrollParent(),this.offset=this.positionAbs=this.element.offset(),this.offset={top:this.offset.top-this.margins.top,left:this.offset.left-this.margins.left},e.extend(this.offset,{click:{left:t.pageX-this.offset.left,top:t.pageY-this.offset.top},parent:this._getParentOffset(),relative:this._getRelativeOffset()}),this.originalPosition=this.position=this._generatePosition(t),this.originalPageX=t.pageX,this.originalPageY=t.pageY,i.cursorAt&&this._adjustOffsetFromHelper(i.cursorAt),i.containment&&this._setContainment(),this._trigger("start",t)===!1?(this._clear(),!1):(this._cacheHelperProportions(),e.ui.ddmanager&&!i.dropBehaviour&&e.ui.ddmanager.prepareOffsets(this,t),this._mouseDrag(t,!0),e.ui.ddmanager&&e.ui.ddmanager.dragStart(this,t),!0)},_mouseDrag:function(t,i){if(this.position=this._generatePosition(t),this.positionAbs=this._convertPositionTo("absolute"),!i){var s=this._uiHash();if(this._trigger("drag",t,s)===!1)return this._mouseUp({}),!1;this.position=s.position}return this.options.axis&&"y"===this.options.axis||(this.helper[0].style.left=this.position.left+"px"),this.options.axis&&"x"===this.options.axis||(this.helper[0].style.top=this.position.top+"px"),e.ui.ddmanager&&e.ui.ddmanager.drag(this,t),!1},_mouseStop:function(t){var i,s=this,n=!1,a=!1;for(e.ui.ddmanager&&!this.options.dropBehaviour&&(a=e.ui.ddmanager.drop(this,t)),this.dropped&&(a=this.dropped,this.dropped=!1),i=this.element[0];i&&(i=i.parentNode);)i===document&&(n=!0);return n||"original"!==this.options.helper?("invalid"===this.options.revert&&!a||"valid"===this.options.revert&&a||this.options.revert===!0||e.isFunction(this.options.revert)&&this.options.revert.call(this.element,a)?e(this.helper).animate(this.originalPosition,parseInt(this.options.revertDuration,10),function(){s._trigger("stop",t)!==!1&&s._clear()}):this._trigger("stop",t)!==!1&&this._clear(),!1):!1},_mouseUp:function(t){return e("div.ui-draggable-iframeFix").each(function(){this.parentNode.removeChild(this)}),e.ui.ddmanager&&e.ui.ddmanager.dragStop(this,t),e.ui.mouse.prototype._mouseUp.call(this,t)},cancel:function(){return this.helper.is(".ui-draggable-dragging")?this._mouseUp({}):this._clear(),this},_getHandle:function(t){return this.options.handle?!!e(t.target).closest(this.element.find(this.options.handle)).length:!0},_createHelper:function(t){var i=this.options,s=e.isFunction(i.helper)?e(i.helper.apply(this.element[0],[t])):"clone"===i.helper?this.element.clone().removeAttr("id"):this.element;return s.parents("body").length||s.appendTo("parent"===i.appendTo?this.element[0].parentNode:i.appendTo),s[0]===this.element[0]||/(fixed|absolute)/.test(s.css("position"))||s.css("position","absolute"),s},_adjustOffsetFromHelper:function(t){"string"==typeof t&&(t=t.split(" ")),e.isArray(t)&&(t={left:+t[0],top:+t[1]||0}),"left"in t&&(this.offset.click.left=t.left+this.margins.left),"right"in t&&(this.offset.click.left=this.helperProportions.width-t.right+this.margins.left),"top"in t&&(this.offset.click.top=t.top+this.margins.top),"bottom"in t&&(this.offset.click.top=this.helperProportions.height-t.bottom+this.margins.top)},_getParentOffset:function(){this.offsetParent=this.helper.offsetParent();var t=this.offsetParent.offset();return"absolute"===this.cssPosition&&this.scrollParent[0]!==document&&e.contains(this.scrollParent[0],this.offsetParent[0])&&(t.left+=this.scrollParent.scrollLeft(),t.top+=this.scrollParent.scrollTop()),(this.offsetParent[0]===document.body||this.offsetParent[0].tagName&&"html"===this.offsetParent[0].tagName.toLowerCase()&&e.ui.ie)&&(t={top:0,left:0}),{top:t.top+(parseInt(this.offsetParent.css("borderTopWidth"),10)||0),left:t.left+(parseInt(this.offsetParent.css("borderLeftWidth"),10)||0)}},_getRelativeOffset:function(){if("relative"===this.cssPosition){var e=this.element.position();return{top:e.top-(parseInt(this.helper.css("top"),10)||0)+this.scrollParent.scrollTop(),left:e.left-(parseInt(this.helper.css("left"),10)||0)+this.scrollParent.scrollLeft()}}return{top:0,left:0}},_cacheMargins:function(){this.margins={left:parseInt(this.element.css("marginLeft"),10)||0,top:parseInt(this.element.css("marginTop"),10)||0,right:parseInt(this.element.css("marginRight"),10)||0,bottom:parseInt(this.element.css("marginBottom"),10)||0}},_cacheHelperProportions:function(){this.helperProportions={width:this.helper.outerWidth(),height:this.helper.outerHeight()}},_setContainment:function(){var t,i,s,n=this.options;if("parent"===n.containment&&(n.containment=this.helper[0].parentNode),("document"===n.containment||"window"===n.containment)&&(this.containment=["document"===n.containment?0:e(window).scrollLeft()-this.offset.relative.left-this.offset.parent.left,"document"===n.containment?0:e(window).scrollTop()-this.offset.relative.top-this.offset.parent.top,("document"===n.containment?0:e(window).scrollLeft())+e("document"===n.containment?document:window).width()-this.helperProportions.width-this.margins.left,("document"===n.containment?0:e(window).scrollTop())+(e("document"===n.containment?document:window).height()||document.body.parentNode.scrollHeight)-this.helperProportions.height-this.margins.top]),/^(document|window|parent)$/.test(n.containment)||n.containment.constructor===Array)n.containment.constructor===Array&&(this.containment=n.containment);else{if(i=e(n.containment),s=i[0],!s)return;t="hidden"!==e(s).css("overflow"),this.containment=[(parseInt(e(s).css("borderLeftWidth"),10)||0)+(parseInt(e(s).css("paddingLeft"),10)||0),(parseInt(e(s).css("borderTopWidth"),10)||0)+(parseInt(e(s).css("paddingTop"),10)||0),(t?Math.max(s.scrollWidth,s.offsetWidth):s.offsetWidth)-(parseInt(e(s).css("borderRightWidth"),10)||0)-(parseInt(e(s).css("paddingRight"),10)||0)-this.helperProportions.width-this.margins.left-this.margins.right,(t?Math.max(s.scrollHeight,s.offsetHeight):s.offsetHeight)-(parseInt(e(s).css("borderBottomWidth"),10)||0)-(parseInt(e(s).css("paddingBottom"),10)||0)-this.helperProportions.height-this.margins.top-this.margins.bottom],this.relative_container=i}},_convertPositionTo:function(t,i){i||(i=this.position);var s="absolute"===t?1:-1,n="absolute"!==this.cssPosition||this.scrollParent[0]!==document&&e.contains(this.scrollParent[0],this.offsetParent[0])?this.scrollParent:this.offsetParent,a=/(html|body)/i.test(n[0].tagName);return{top:i.top+this.offset.relative.top*s+this.offset.parent.top*s-("fixed"===this.cssPosition?-this.scrollParent.scrollTop():a?0:n.scrollTop())*s,left:i.left+this.offset.relative.left*s+this.offset.parent.left*s-("fixed"===this.cssPosition?-this.scrollParent.scrollLeft():a?0:n.scrollLeft())*s}},_generatePosition:function(t){var i,s,n,a,o=this.options,r="absolute"!==this.cssPosition||this.scrollParent[0]!==document&&e.contains(this.scrollParent[0],this.offsetParent[0])?this.scrollParent:this.offsetParent,h=/(html|body)/i.test(r[0].tagName),l=t.pageX,u=t.pageY;return this.originalPosition&&(this.containment&&(this.relative_container?(s=this.relative_container.offset(),i=[this.containment[0]+s.left,this.containment[1]+s.top,this.containment[2]+s.left,this.containment[3]+s.top]):i=this.containment,t.pageX-this.offset.click.left<i[0]&&(l=i[0]+this.offset.click.left),t.pageY-this.offset.click.top<i[1]&&(u=i[1]+this.offset.click.top),t.pageX-this.offset.click.left>i[2]&&(l=i[2]+this.offset.click.left),t.pageY-this.offset.click.top>i[3]&&(u=i[3]+this.offset.click.top)),o.grid&&(n=o.grid[1]?this.originalPageY+Math.round((u-this.originalPageY)/o.grid[1])*o.grid[1]:this.originalPageY,u=i?n-this.offset.click.top>=i[1]||n-this.offset.click.top>i[3]?n:n-this.offset.click.top>=i[1]?n-o.grid[1]:n+o.grid[1]:n,a=o.grid[0]?this.originalPageX+Math.round((l-this.originalPageX)/o.grid[0])*o.grid[0]:this.originalPageX,l=i?a-this.offset.click.left>=i[0]||a-this.offset.click.left>i[2]?a:a-this.offset.click.left>=i[0]?a-o.grid[0]:a+o.grid[0]:a)),{top:u-this.offset.click.top-this.offset.relative.top-this.offset.parent.top+("fixed"===this.cssPosition?-this.scrollParent.scrollTop():h?0:r.scrollTop()),left:l-this.offset.click.left-this.offset.relative.left-this.offset.parent.left+("fixed"===this.cssPosition?-this.scrollParent.scrollLeft():h?0:r.scrollLeft())}},_clear:function(){this.helper.removeClass("ui-draggable-dragging"),this.helper[0]===this.element[0]||this.cancelHelperRemoval||this.helper.remove(),this.helper=null,this.cancelHelperRemoval=!1},_trigger:function(t,i,s){return s=s||this._uiHash(),e.ui.plugin.call(this,t,[i,s]),"drag"===t&&(this.positionAbs=this._convertPositionTo("absolute")),e.Widget.prototype._trigger.call(this,t,i,s)},plugins:{},_uiHash:function(){return{helper:this.helper,position:this.position,originalPosition:this.originalPosition,offset:this.positionAbs}}}),e.ui.plugin.add("draggable","connectToSortable",{start:function(t,i){var s=e(this).data("ui-draggable"),n=s.options,a=e.extend({},i,{item:s.element});s.sortables=[],e(n.connectToSortable).each(function(){var i=e.data(this,"ui-sortable");i&&!i.options.disabled&&(s.sortables.push({instance:i,shouldRevert:i.options.revert}),i.refreshPositions(),i._trigger("activate",t,a))})},stop:function(t,i){var s=e(this).data("ui-draggable"),n=e.extend({},i,{item:s.element});e.each(s.sortables,function(){this.instance.isOver?(this.instance.isOver=0,s.cancelHelperRemoval=!0,this.instance.cancelHelperRemoval=!1,this.shouldRevert&&(this.instance.options.revert=this.shouldRevert),this.instance._mouseStop(t),this.instance.options.helper=this.instance.options._helper,"original"===s.options.helper&&this.instance.currentItem.css({top:"auto",left:"auto"})):(this.instance.cancelHelperRemoval=!1,this.instance._trigger("deactivate",t,n))})},drag:function(t,i){var s=e(this).data("ui-draggable"),n=this;e.each(s.sortables,function(){var a=!1,o=this;this.instance.positionAbs=s.positionAbs,this.instance.helperProportions=s.helperProportions,this.instance.offset.click=s.offset.click,this.instance._intersectsWith(this.instance.containerCache)&&(a=!0,e.each(s.sortables,function(){return this.instance.positionAbs=s.positionAbs,this.instance.helperProportions=s.helperProportions,this.instance.offset.click=s.offset.click,this!==o&&this.instance._intersectsWith(this.instance.containerCache)&&e.contains(o.instance.element[0],this.instance.element[0])&&(a=!1),a})),a?(this.instance.isOver||(this.instance.isOver=1,this.instance.currentItem=e(n).clone().removeAttr("id").appendTo(this.instance.element).data("ui-sortable-item",!0),this.instance.options._helper=this.instance.options.helper,this.instance.options.helper=function(){return i.helper[0]},t.target=this.instance.currentItem[0],this.instance._mouseCapture(t,!0),this.instance._mouseStart(t,!0,!0),this.instance.offset.click.top=s.offset.click.top,this.instance.offset.click.left=s.offset.click.left,this.instance.offset.parent.left-=s.offset.parent.left-this.instance.offset.parent.left,this.instance.offset.parent.top-=s.offset.parent.top-this.instance.offset.parent.top,s._trigger("toSortable",t),s.dropped=this.instance.element,s.currentItem=s.element,this.instance.fromOutside=s),this.instance.currentItem&&this.instance._mouseDrag(t)):this.instance.isOver&&(this.instance.isOver=0,this.instance.cancelHelperRemoval=!0,this.instance.options.revert=!1,this.instance._trigger("out",t,this.instance._uiHash(this.instance)),this.instance._mouseStop(t,!0),this.instance.options.helper=this.instance.options._helper,this.instance.currentItem.remove(),this.instance.placeholder&&this.instance.placeholder.remove(),s._trigger("fromSortable",t),s.dropped=!1)})}}),e.ui.plugin.add("draggable","cursor",{start:function(){var t=e("body"),i=e(this).data("ui-draggable").options;t.css("cursor")&&(i._cursor=t.css("cursor")),t.css("cursor",i.cursor)},stop:function(){var t=e(this).data("ui-draggable").options;t._cursor&&e("body").css("cursor",t._cursor)}}),e.ui.plugin.add("draggable","opacity",{start:function(t,i){var s=e(i.helper),n=e(this).data("ui-draggable").options;s.css("opacity")&&(n._opacity=s.css("opacity")),s.css("opacity",n.opacity)},stop:function(t,i){var s=e(this).data("ui-draggable").options;s._opacity&&e(i.helper).css("opacity",s._opacity)}}),e.ui.plugin.add("draggable","scroll",{start:function(){var t=e(this).data("ui-draggable");t.scrollParent[0]!==document&&"HTML"!==t.scrollParent[0].tagName&&(t.overflowOffset=t.scrollParent.offset())},drag:function(t){var i=e(this).data("ui-draggable"),s=i.options,n=!1;i.scrollParent[0]!==document&&"HTML"!==i.scrollParent[0].tagName?(s.axis&&"x"===s.axis||(i.overflowOffset.top+i.scrollParent[0].offsetHeight-t.pageY<s.scrollSensitivity?i.scrollParent[0].scrollTop=n=i.scrollParent[0].scrollTop+s.scrollSpeed:t.pageY-i.overflowOffset.top<s.scrollSensitivity&&(i.scrollParent[0].scrollTop=n=i.scrollParent[0].scrollTop-s.scrollSpeed)),s.axis&&"y"===s.axis||(i.overflowOffset.left+i.scrollParent[0].offsetWidth-t.pageX<s.scrollSensitivity?i.scrollParent[0].scrollLeft=n=i.scrollParent[0].scrollLeft+s.scrollSpeed:t.pageX-i.overflowOffset.left<s.scrollSensitivity&&(i.scrollParent[0].scrollLeft=n=i.scrollParent[0].scrollLeft-s.scrollSpeed))):(s.axis&&"x"===s.axis||(t.pageY-e(document).scrollTop()<s.scrollSensitivity?n=e(document).scrollTop(e(document).scrollTop()-s.scrollSpeed):e(window).height()-(t.pageY-e(document).scrollTop())<s.scrollSensitivity&&(n=e(document).scrollTop(e(document).scrollTop()+s.scrollSpeed))),s.axis&&"y"===s.axis||(t.pageX-e(document).scrollLeft()<s.scrollSensitivity?n=e(document).scrollLeft(e(document).scrollLeft()-s.scrollSpeed):e(window).width()-(t.pageX-e(document).scrollLeft())<s.scrollSensitivity&&(n=e(document).scrollLeft(e(document).scrollLeft()+s.scrollSpeed)))),n!==!1&&e.ui.ddmanager&&!s.dropBehaviour&&e.ui.ddmanager.prepareOffsets(i,t)}}),e.ui.plugin.add("draggable","snap",{start:function(){var t=e(this).data("ui-draggable"),i=t.options;t.snapElements=[],e(i.snap.constructor!==String?i.snap.items||":data(ui-draggable)":i.snap).each(function(){var i=e(this),s=i.offset();this!==t.element[0]&&t.snapElements.push({item:this,width:i.outerWidth(),height:i.outerHeight(),top:s.top,left:s.left})})},drag:function(t,i){var s,n,a,o,r,h,l,u,c,d,p=e(this).data("ui-draggable"),f=p.options,m=f.snapTolerance,g=i.offset.left,v=g+p.helperProportions.width,y=i.offset.top,b=y+p.helperProportions.height;for(c=p.snapElements.length-1;c>=0;c--)r=p.snapElements[c].left,h=r+p.snapElements[c].width,l=p.snapElements[c].top,u=l+p.snapElements[c].height,g>r-m&&h+m>g&&y>l-m&&u+m>y||g>r-m&&h+m>g&&b>l-m&&u+m>b||v>r-m&&h+m>v&&y>l-m&&u+m>y||v>r-m&&h+m>v&&b>l-m&&u+m>b?("inner"!==f.snapMode&&(s=m>=Math.abs(l-b),n=m>=Math.abs(u-y),a=m>=Math.abs(r-v),o=m>=Math.abs(h-g),s&&(i.position.top=p._convertPositionTo("relative",{top:l-p.helperProportions.height,left:0}).top-p.margins.top),n&&(i.position.top=p._convertPositionTo("relative",{top:u,left:0}).top-p.margins.top),a&&(i.position.left=p._convertPositionTo("relative",{top:0,left:r-p.helperProportions.width}).left-p.margins.left),o&&(i.position.left=p._convertPositionTo("relative",{top:0,left:h}).left-p.margins.left)),d=s||n||a||o,"outer"!==f.snapMode&&(s=m>=Math.abs(l-y),n=m>=Math.abs(u-b),a=m>=Math.abs(r-g),o=m>=Math.abs(h-v),s&&(i.position.top=p._convertPositionTo("relative",{top:l,left:0}).top-p.margins.top),n&&(i.position.top=p._convertPositionTo("relative",{top:u-p.helperProportions.height,left:0}).top-p.margins.top),a&&(i.position.left=p._convertPositionTo("relative",{top:0,left:r}).left-p.margins.left),o&&(i.position.left=p._convertPositionTo("relative",{top:0,left:h-p.helperProportions.width}).left-p.margins.left)),!p.snapElements[c].snapping&&(s||n||a||o||d)&&p.options.snap.snap&&p.options.snap.snap.call(p.element,t,e.extend(p._uiHash(),{snapItem:p.snapElements[c].item})),p.snapElements[c].snapping=s||n||a||o||d):(p.snapElements[c].snapping&&p.options.snap.release&&p.options.snap.release.call(p.element,t,e.extend(p._uiHash(),{snapItem:p.snapElements[c].item})),p.snapElements[c].snapping=!1)}}),e.ui.plugin.add("draggable","stack",{start:function(){var t,i=this.data("ui-draggable").options,s=e.makeArray(e(i.stack)).sort(function(t,i){return(parseInt(e(t).css("zIndex"),10)||0)-(parseInt(e(i).css("zIndex"),10)||0)});s.length&&(t=parseInt(e(s[0]).css("zIndex"),10)||0,e(s).each(function(i){e(this).css("zIndex",t+i)}),this.css("zIndex",t+s.length))}}),e.ui.plugin.add("draggable","zIndex",{start:function(t,i){var s=e(i.helper),n=e(this).data("ui-draggable").options;s.css("zIndex")&&(n._zIndex=s.css("zIndex")),s.css("zIndex",n.zIndex)},stop:function(t,i){var s=e(this).data("ui-draggable").options;s._zIndex&&e(i.helper).css("zIndex",s._zIndex)}})})(jQuery);(function(e){function t(e){return parseInt(e,10)||0}function i(e){return!isNaN(parseInt(e,10))}e.widget("ui.resizable",e.ui.mouse,{version:"1.10.2",widgetEventPrefix:"resize",options:{alsoResize:!1,animate:!1,animateDuration:"slow",animateEasing:"swing",aspectRatio:!1,autoHide:!1,containment:!1,ghost:!1,grid:!1,handles:"e,s,se",helper:!1,maxHeight:null,maxWidth:null,minHeight:10,minWidth:10,zIndex:90,resize:null,start:null,stop:null},_create:function(){var t,i,s,n,a,o=this,r=this.options;if(this.element.addClass("ui-resizable"),e.extend(this,{_aspectRatio:!!r.aspectRatio,aspectRatio:r.aspectRatio,originalElement:this.element,_proportionallyResizeElements:[],_helper:r.helper||r.ghost||r.animate?r.helper||"ui-resizable-helper":null}),this.element[0].nodeName.match(/canvas|textarea|input|select|button|img/i)&&(this.element.wrap(e("<div class='ui-wrapper' style='overflow: hidden;'></div>").css({position:this.element.css("position"),width:this.element.outerWidth(),height:this.element.outerHeight(),top:this.element.css("top"),left:this.element.css("left")})),this.element=this.element.parent().data("ui-resizable",this.element.data("ui-resizable")),this.elementIsWrapper=!0,this.element.css({marginLeft:this.originalElement.css("marginLeft"),marginTop:this.originalElement.css("marginTop"),marginRight:this.originalElement.css("marginRight"),marginBottom:this.originalElement.css("marginBottom")}),this.originalElement.css({marginLeft:0,marginTop:0,marginRight:0,marginBottom:0}),this.originalResizeStyle=this.originalElement.css("resize"),this.originalElement.css("resize","none"),this._proportionallyResizeElements.push(this.originalElement.css({position:"static",zoom:1,display:"block"})),this.originalElement.css({margin:this.originalElement.css("margin")}),this._proportionallyResize()),this.handles=r.handles||(e(".ui-resizable-handle",this.element).length?{n:".ui-resizable-n",e:".ui-resizable-e",s:".ui-resizable-s",w:".ui-resizable-w",se:".ui-resizable-se",sw:".ui-resizable-sw",ne:".ui-resizable-ne",nw:".ui-resizable-nw"}:"e,s,se"),this.handles.constructor===String)for("all"===this.handles&&(this.handles="n,e,s,w,se,sw,ne,nw"),t=this.handles.split(","),this.handles={},i=0;t.length>i;i++)s=e.trim(t[i]),a="ui-resizable-"+s,n=e("<div class='ui-resizable-handle "+a+"'></div>"),n.css({zIndex:r.zIndex}),"se"===s&&n.addClass("ui-icon ui-icon-gripsmall-diagonal-se"),this.handles[s]=".ui-resizable-"+s,this.element.append(n);this._renderAxis=function(t){var i,s,n,a;t=t||this.element;for(i in this.handles)this.handles[i].constructor===String&&(this.handles[i]=e(this.handles[i],this.element).show()),this.elementIsWrapper&&this.originalElement[0].nodeName.match(/textarea|input|select|button/i)&&(s=e(this.handles[i],this.element),a=/sw|ne|nw|se|n|s/.test(i)?s.outerHeight():s.outerWidth(),n=["padding",/ne|nw|n/.test(i)?"Top":/se|sw|s/.test(i)?"Bottom":/^e$/.test(i)?"Right":"Left"].join(""),t.css(n,a),this._proportionallyResize()),e(this.handles[i]).length},this._renderAxis(this.element),this._handles=e(".ui-resizable-handle",this.element).disableSelection(),this._handles.mouseover(function(){o.resizing||(this.className&&(n=this.className.match(/ui-resizable-(se|sw|ne|nw|n|e|s|w)/i)),o.axis=n&&n[1]?n[1]:"se")}),r.autoHide&&(this._handles.hide(),e(this.element).addClass("ui-resizable-autohide").mouseenter(function(){r.disabled||(e(this).removeClass("ui-resizable-autohide"),o._handles.show())}).mouseleave(function(){r.disabled||o.resizing||(e(this).addClass("ui-resizable-autohide"),o._handles.hide())})),this._mouseInit()},_destroy:function(){this._mouseDestroy();var t,i=function(t){e(t).removeClass("ui-resizable ui-resizable-disabled ui-resizable-resizing").removeData("resizable").removeData("ui-resizable").unbind(".resizable").find(".ui-resizable-handle").remove()};return this.elementIsWrapper&&(i(this.element),t=this.element,this.originalElement.css({position:t.css("position"),width:t.outerWidth(),height:t.outerHeight(),top:t.css("top"),left:t.css("left")}).insertAfter(t),t.remove()),this.originalElement.css("resize",this.originalResizeStyle),i(this.originalElement),this},_mouseCapture:function(t){var i,s,n=!1;for(i in this.handles)s=e(this.handles[i])[0],(s===t.target||e.contains(s,t.target))&&(n=!0);return!this.options.disabled&&n},_mouseStart:function(i){var s,n,a,o=this.options,r=this.element.position(),h=this.element;return this.resizing=!0,/absolute/.test(h.css("position"))?h.css({position:"absolute",top:h.css("top"),left:h.css("left")}):h.is(".ui-draggable")&&h.css({position:"absolute",top:r.top,left:r.left}),this._renderProxy(),s=t(this.helper.css("left")),n=t(this.helper.css("top")),o.containment&&(s+=e(o.containment).scrollLeft()||0,n+=e(o.containment).scrollTop()||0),this.offset=this.helper.offset(),this.position={left:s,top:n},this.size=this._helper?{width:h.outerWidth(),height:h.outerHeight()}:{width:h.width(),height:h.height()},this.originalSize=this._helper?{width:h.outerWidth(),height:h.outerHeight()}:{width:h.width(),height:h.height()},this.originalPosition={left:s,top:n},this.sizeDiff={width:h.outerWidth()-h.width(),height:h.outerHeight()-h.height()},this.originalMousePosition={left:i.pageX,top:i.pageY},this.aspectRatio="number"==typeof o.aspectRatio?o.aspectRatio:this.originalSize.width/this.originalSize.height||1,a=e(".ui-resizable-"+this.axis).css("cursor"),e("body").css("cursor","auto"===a?this.axis+"-resize":a),h.addClass("ui-resizable-resizing"),this._propagate("start",i),!0},_mouseDrag:function(t){var i,s=this.helper,n={},a=this.originalMousePosition,o=this.axis,r=this.position.top,h=this.position.left,l=this.size.width,u=this.size.height,c=t.pageX-a.left||0,d=t.pageY-a.top||0,p=this._change[o];return p?(i=p.apply(this,[t,c,d]),this._updateVirtualBoundaries(t.shiftKey),(this._aspectRatio||t.shiftKey)&&(i=this._updateRatio(i,t)),i=this._respectSize(i,t),this._updateCache(i),this._propagate("resize",t),this.position.top!==r&&(n.top=this.position.top+"px"),this.position.left!==h&&(n.left=this.position.left+"px"),this.size.width!==l&&(n.width=this.size.width+"px"),this.size.height!==u&&(n.height=this.size.height+"px"),s.css(n),!this._helper&&this._proportionallyResizeElements.length&&this._proportionallyResize(),e.isEmptyObject(n)||this._trigger("resize",t,this.ui()),!1):!1},_mouseStop:function(t){this.resizing=!1;var i,s,n,a,o,r,h,l=this.options,u=this;return this._helper&&(i=this._proportionallyResizeElements,s=i.length&&/textarea/i.test(i[0].nodeName),n=s&&e.ui.hasScroll(i[0],"left")?0:u.sizeDiff.height,a=s?0:u.sizeDiff.width,o={width:u.helper.width()-a,height:u.helper.height()-n},r=parseInt(u.element.css("left"),10)+(u.position.left-u.originalPosition.left)||null,h=parseInt(u.element.css("top"),10)+(u.position.top-u.originalPosition.top)||null,l.animate||this.element.css(e.extend(o,{top:h,left:r})),u.helper.height(u.size.height),u.helper.width(u.size.width),this._helper&&!l.animate&&this._proportionallyResize()),e("body").css("cursor","auto"),this.element.removeClass("ui-resizable-resizing"),this._propagate("stop",t),this._helper&&this.helper.remove(),!1},_updateVirtualBoundaries:function(e){var t,s,n,a,o,r=this.options;o={minWidth:i(r.minWidth)?r.minWidth:0,maxWidth:i(r.maxWidth)?r.maxWidth:1/0,minHeight:i(r.minHeight)?r.minHeight:0,maxHeight:i(r.maxHeight)?r.maxHeight:1/0},(this._aspectRatio||e)&&(t=o.minHeight*this.aspectRatio,n=o.minWidth/this.aspectRatio,s=o.maxHeight*this.aspectRatio,a=o.maxWidth/this.aspectRatio,t>o.minWidth&&(o.minWidth=t),n>o.minHeight&&(o.minHeight=n),o.maxWidth>s&&(o.maxWidth=s),o.maxHeight>a&&(o.maxHeight=a)),this._vBoundaries=o},_updateCache:function(e){this.offset=this.helper.offset(),i(e.left)&&(this.position.left=e.left),i(e.top)&&(this.position.top=e.top),i(e.height)&&(this.size.height=e.height),i(e.width)&&(this.size.width=e.width)},_updateRatio:function(e){var t=this.position,s=this.size,n=this.axis;return i(e.height)?e.width=e.height*this.aspectRatio:i(e.width)&&(e.height=e.width/this.aspectRatio),"sw"===n&&(e.left=t.left+(s.width-e.width),e.top=null),"nw"===n&&(e.top=t.top+(s.height-e.height),e.left=t.left+(s.width-e.width)),e},_respectSize:function(e){var t=this._vBoundaries,s=this.axis,n=i(e.width)&&t.maxWidth&&t.maxWidth<e.width,a=i(e.height)&&t.maxHeight&&t.maxHeight<e.height,o=i(e.width)&&t.minWidth&&t.minWidth>e.width,r=i(e.height)&&t.minHeight&&t.minHeight>e.height,h=this.originalPosition.left+this.originalSize.width,l=this.position.top+this.size.height,u=/sw|nw|w/.test(s),c=/nw|ne|n/.test(s);return o&&(e.width=t.minWidth),r&&(e.height=t.minHeight),n&&(e.width=t.maxWidth),a&&(e.height=t.maxHeight),o&&u&&(e.left=h-t.minWidth),n&&u&&(e.left=h-t.maxWidth),r&&c&&(e.top=l-t.minHeight),a&&c&&(e.top=l-t.maxHeight),e.width||e.height||e.left||!e.top?e.width||e.height||e.top||!e.left||(e.left=null):e.top=null,e},_proportionallyResize:function(){if(this._proportionallyResizeElements.length){var e,t,i,s,n,a=this.helper||this.element;for(e=0;this._proportionallyResizeElements.length>e;e++){if(n=this._proportionallyResizeElements[e],!this.borderDif)for(this.borderDif=[],i=[n.css("borderTopWidth"),n.css("borderRightWidth"),n.css("borderBottomWidth"),n.css("borderLeftWidth")],s=[n.css("paddingTop"),n.css("paddingRight"),n.css("paddingBottom"),n.css("paddingLeft")],t=0;i.length>t;t++)this.borderDif[t]=(parseInt(i[t],10)||0)+(parseInt(s[t],10)||0);n.css({height:a.height()-this.borderDif[0]-this.borderDif[2]||0,width:a.width()-this.borderDif[1]-this.borderDif[3]||0})}}},_renderProxy:function(){var t=this.element,i=this.options;this.elementOffset=t.offset(),this._helper?(this.helper=this.helper||e("<div style='overflow:hidden;'></div>"),this.helper.addClass(this._helper).css({width:this.element.outerWidth()-1,height:this.element.outerHeight()-1,position:"absolute",left:this.elementOffset.left+"px",top:this.elementOffset.top+"px",zIndex:++i.zIndex}),this.helper.appendTo("body").disableSelection()):this.helper=this.element},_change:{e:function(e,t){return{width:this.originalSize.width+t}},w:function(e,t){var i=this.originalSize,s=this.originalPosition;return{left:s.left+t,width:i.width-t}},n:function(e,t,i){var s=this.originalSize,n=this.originalPosition;return{top:n.top+i,height:s.height-i}},s:function(e,t,i){return{height:this.originalSize.height+i}},se:function(t,i,s){return e.extend(this._change.s.apply(this,arguments),this._change.e.apply(this,[t,i,s]))},sw:function(t,i,s){return e.extend(this._change.s.apply(this,arguments),this._change.w.apply(this,[t,i,s]))},ne:function(t,i,s){return e.extend(this._change.n.apply(this,arguments),this._change.e.apply(this,[t,i,s]))},nw:function(t,i,s){return e.extend(this._change.n.apply(this,arguments),this._change.w.apply(this,[t,i,s]))}},_propagate:function(t,i){e.ui.plugin.call(this,t,[i,this.ui()]),"resize"!==t&&this._trigger(t,i,this.ui())},plugins:{},ui:function(){return{originalElement:this.originalElement,element:this.element,helper:this.helper,position:this.position,size:this.size,originalSize:this.originalSize,originalPosition:this.originalPosition}}}),e.ui.plugin.add("resizable","animate",{stop:function(t){var i=e(this).data("ui-resizable"),s=i.options,n=i._proportionallyResizeElements,a=n.length&&/textarea/i.test(n[0].nodeName),o=a&&e.ui.hasScroll(n[0],"left")?0:i.sizeDiff.height,r=a?0:i.sizeDiff.width,h={width:i.size.width-r,height:i.size.height-o},l=parseInt(i.element.css("left"),10)+(i.position.left-i.originalPosition.left)||null,u=parseInt(i.element.css("top"),10)+(i.position.top-i.originalPosition.top)||null;i.element.animate(e.extend(h,u&&l?{top:u,left:l}:{}),{duration:s.animateDuration,easing:s.animateEasing,step:function(){var s={width:parseInt(i.element.css("width"),10),height:parseInt(i.element.css("height"),10),top:parseInt(i.element.css("top"),10),left:parseInt(i.element.css("left"),10)};n&&n.length&&e(n[0]).css({width:s.width,height:s.height}),i._updateCache(s),i._propagate("resize",t)}})}}),e.ui.plugin.add("resizable","containment",{start:function(){var i,s,n,a,o,r,h,l=e(this).data("ui-resizable"),u=l.options,c=l.element,d=u.containment,p=d instanceof e?d.get(0):/parent/.test(d)?c.parent().get(0):d;p&&(l.containerElement=e(p),/document/.test(d)||d===document?(l.containerOffset={left:0,top:0},l.containerPosition={left:0,top:0},l.parentData={element:e(document),left:0,top:0,width:e(document).width(),height:e(document).height()||document.body.parentNode.scrollHeight}):(i=e(p),s=[],e(["Top","Right","Left","Bottom"]).each(function(e,n){s[e]=t(i.css("padding"+n))}),l.containerOffset=i.offset(),l.containerPosition=i.position(),l.containerSize={height:i.innerHeight()-s[3],width:i.innerWidth()-s[1]},n=l.containerOffset,a=l.containerSize.height,o=l.containerSize.width,r=e.ui.hasScroll(p,"left")?p.scrollWidth:o,h=e.ui.hasScroll(p)?p.scrollHeight:a,l.parentData={element:p,left:n.left,top:n.top,width:r,height:h}))},resize:function(t){var i,s,n,a,o=e(this).data("ui-resizable"),r=o.options,h=o.containerOffset,l=o.position,u=o._aspectRatio||t.shiftKey,c={top:0,left:0},d=o.containerElement;d[0]!==document&&/static/.test(d.css("position"))&&(c=h),l.left<(o._helper?h.left:0)&&(o.size.width=o.size.width+(o._helper?o.position.left-h.left:o.position.left-c.left),u&&(o.size.height=o.size.width/o.aspectRatio),o.position.left=r.helper?h.left:0),l.top<(o._helper?h.top:0)&&(o.size.height=o.size.height+(o._helper?o.position.top-h.top:o.position.top),u&&(o.size.width=o.size.height*o.aspectRatio),o.position.top=o._helper?h.top:0),o.offset.left=o.parentData.left+o.position.left,o.offset.top=o.parentData.top+o.position.top,i=Math.abs((o._helper?o.offset.left-c.left:o.offset.left-c.left)+o.sizeDiff.width),s=Math.abs((o._helper?o.offset.top-c.top:o.offset.top-h.top)+o.sizeDiff.height),n=o.containerElement.get(0)===o.element.parent().get(0),a=/relative|absolute/.test(o.containerElement.css("position")),n&&a&&(i-=o.parentData.left),i+o.size.width>=o.parentData.width&&(o.size.width=o.parentData.width-i,u&&(o.size.height=o.size.width/o.aspectRatio)),s+o.size.height>=o.parentData.height&&(o.size.height=o.parentData.height-s,u&&(o.size.width=o.size.height*o.aspectRatio))},stop:function(){var t=e(this).data("ui-resizable"),i=t.options,s=t.containerOffset,n=t.containerPosition,a=t.containerElement,o=e(t.helper),r=o.offset(),h=o.outerWidth()-t.sizeDiff.width,l=o.outerHeight()-t.sizeDiff.height;t._helper&&!i.animate&&/relative/.test(a.css("position"))&&e(this).css({left:r.left-n.left-s.left,width:h,height:l}),t._helper&&!i.animate&&/static/.test(a.css("position"))&&e(this).css({left:r.left-n.left-s.left,width:h,height:l})}}),e.ui.plugin.add("resizable","alsoResize",{start:function(){var t=e(this).data("ui-resizable"),i=t.options,s=function(t){e(t).each(function(){var t=e(this);t.data("ui-resizable-alsoresize",{width:parseInt(t.width(),10),height:parseInt(t.height(),10),left:parseInt(t.css("left"),10),top:parseInt(t.css("top"),10)})})};"object"!=typeof i.alsoResize||i.alsoResize.parentNode?s(i.alsoResize):i.alsoResize.length?(i.alsoResize=i.alsoResize[0],s(i.alsoResize)):e.each(i.alsoResize,function(e){s(e)})},resize:function(t,i){var s=e(this).data("ui-resizable"),n=s.options,a=s.originalSize,o=s.originalPosition,r={height:s.size.height-a.height||0,width:s.size.width-a.width||0,top:s.position.top-o.top||0,left:s.position.left-o.left||0},h=function(t,s){e(t).each(function(){var t=e(this),n=e(this).data("ui-resizable-alsoresize"),a={},o=s&&s.length?s:t.parents(i.originalElement[0]).length?["width","height"]:["width","height","top","left"];e.each(o,function(e,t){var i=(n[t]||0)+(r[t]||0);i&&i>=0&&(a[t]=i||null)}),t.css(a)})};"object"!=typeof n.alsoResize||n.alsoResize.nodeType?h(n.alsoResize):e.each(n.alsoResize,function(e,t){h(e,t)})},stop:function(){e(this).removeData("resizable-alsoresize")}}),e.ui.plugin.add("resizable","ghost",{start:function(){var t=e(this).data("ui-resizable"),i=t.options,s=t.size;t.ghost=t.originalElement.clone(),t.ghost.css({opacity:.25,display:"block",position:"relative",height:s.height,width:s.width,margin:0,left:0,top:0}).addClass("ui-resizable-ghost").addClass("string"==typeof i.ghost?i.ghost:""),t.ghost.appendTo(t.helper)},resize:function(){var t=e(this).data("ui-resizable");t.ghost&&t.ghost.css({position:"relative",height:t.size.height,width:t.size.width})},stop:function(){var t=e(this).data("ui-resizable");t.ghost&&t.helper&&t.helper.get(0).removeChild(t.ghost.get(0))}}),e.ui.plugin.add("resizable","grid",{resize:function(){var t=e(this).data("ui-resizable"),i=t.options,s=t.size,n=t.originalSize,a=t.originalPosition,o=t.axis,r="number"==typeof i.grid?[i.grid,i.grid]:i.grid,h=r[0]||1,l=r[1]||1,u=Math.round((s.width-n.width)/h)*h,c=Math.round((s.height-n.height)/l)*l,d=n.width+u,p=n.height+c,f=i.maxWidth&&d>i.maxWidth,m=i.maxHeight&&p>i.maxHeight,g=i.minWidth&&i.minWidth>d,v=i.minHeight&&i.minHeight>p;i.grid=r,g&&(d+=h),v&&(p+=l),f&&(d-=h),m&&(p-=l),/^(se|s|e)$/.test(o)?(t.size.width=d,t.size.height=p):/^(ne)$/.test(o)?(t.size.width=d,t.size.height=p,t.position.top=a.top-c):/^(sw)$/.test(o)?(t.size.width=d,t.size.height=p,t.position.left=a.left-u):(t.size.width=d,t.size.height=p,t.position.top=a.top-c,t.position.left=a.left-u)}})})(jQuery);(function(t){function e(t,e,i){return t>e&&e+i>t}function i(t){return/left|right/.test(t.css("float"))||/inline|table-cell/.test(t.css("display"))}t.widget("ui.sortable",t.ui.mouse,{version:"1.10.2",widgetEventPrefix:"sort",ready:!1,options:{appendTo:"parent",axis:!1,connectWith:!1,containment:!1,cursor:"auto",cursorAt:!1,dropOnEmpty:!0,forcePlaceholderSize:!1,forceHelperSize:!1,grid:!1,handle:!1,helper:"original",items:"> *",opacity:!1,placeholder:!1,revert:!1,scroll:!0,scrollSensitivity:20,scrollSpeed:20,scope:"default",tolerance:"intersect",zIndex:1e3,activate:null,beforeStop:null,change:null,deactivate:null,out:null,over:null,receive:null,remove:null,sort:null,start:null,stop:null,update:null},_create:function(){var t=this.options;this.containerCache={},this.element.addClass("ui-sortable"),this.refresh(),this.floating=this.items.length?"x"===t.axis||i(this.items[0].item):!1,this.offset=this.element.offset(),this._mouseInit(),this.ready=!0},_destroy:function(){this.element.removeClass("ui-sortable ui-sortable-disabled"),this._mouseDestroy();for(var t=this.items.length-1;t>=0;t--)this.items[t].item.removeData(this.widgetName+"-item");return this},_setOption:function(e,i){"disabled"===e?(this.options[e]=i,this.widget().toggleClass("ui-sortable-disabled",!!i)):t.Widget.prototype._setOption.apply(this,arguments)},_mouseCapture:function(e,i){var s=null,n=!1,a=this;return this.reverting?!1:this.options.disabled||"static"===this.options.type?!1:(this._refreshItems(e),t(e.target).parents().each(function(){return t.data(this,a.widgetName+"-item")===a?(s=t(this),!1):undefined}),t.data(e.target,a.widgetName+"-item")===a&&(s=t(e.target)),s?!this.options.handle||i||(t(this.options.handle,s).find("*").addBack().each(function(){this===e.target&&(n=!0)}),n)?(this.currentItem=s,this._removeCurrentsFromItems(),!0):!1:!1)},_mouseStart:function(e,i,s){var n,a,o=this.options;if(this.currentContainer=this,this.refreshPositions(),this.helper=this._createHelper(e),this._cacheHelperProportions(),this._cacheMargins(),this.scrollParent=this.helper.scrollParent(),this.offset=this.currentItem.offset(),this.offset={top:this.offset.top-this.margins.top,left:this.offset.left-this.margins.left},t.extend(this.offset,{click:{left:e.pageX-this.offset.left,top:e.pageY-this.offset.top},parent:this._getParentOffset(),relative:this._getRelativeOffset()}),this.helper.css("position","absolute"),this.cssPosition=this.helper.css("position"),this.originalPosition=this._generatePosition(e),this.originalPageX=e.pageX,this.originalPageY=e.pageY,o.cursorAt&&this._adjustOffsetFromHelper(o.cursorAt),this.domPosition={prev:this.currentItem.prev()[0],parent:this.currentItem.parent()[0]},this.helper[0]!==this.currentItem[0]&&this.currentItem.hide(),this._createPlaceholder(),o.containment&&this._setContainment(),o.cursor&&"auto"!==o.cursor&&(a=this.document.find("body"),this.storedCursor=a.css("cursor"),a.css("cursor",o.cursor),this.storedStylesheet=t("<style>*{ cursor: "+o.cursor+" !important; }</style>").appendTo(a)),o.opacity&&(this.helper.css("opacity")&&(this._storedOpacity=this.helper.css("opacity")),this.helper.css("opacity",o.opacity)),o.zIndex&&(this.helper.css("zIndex")&&(this._storedZIndex=this.helper.css("zIndex")),this.helper.css("zIndex",o.zIndex)),this.scrollParent[0]!==document&&"HTML"!==this.scrollParent[0].tagName&&(this.overflowOffset=this.scrollParent.offset()),this._trigger("start",e,this._uiHash()),this._preserveHelperProportions||this._cacheHelperProportions(),!s)for(n=this.containers.length-1;n>=0;n--)this.containers[n]._trigger("activate",e,this._uiHash(this));return t.ui.ddmanager&&(t.ui.ddmanager.current=this),t.ui.ddmanager&&!o.dropBehaviour&&t.ui.ddmanager.prepareOffsets(this,e),this.dragging=!0,this.helper.addClass("ui-sortable-helper"),this._mouseDrag(e),!0},_mouseDrag:function(e){var i,s,n,a,o=this.options,r=!1;for(this.position=this._generatePosition(e),this.positionAbs=this._convertPositionTo("absolute"),this.lastPositionAbs||(this.lastPositionAbs=this.positionAbs),this.options.scroll&&(this.scrollParent[0]!==document&&"HTML"!==this.scrollParent[0].tagName?(this.overflowOffset.top+this.scrollParent[0].offsetHeight-e.pageY<o.scrollSensitivity?this.scrollParent[0].scrollTop=r=this.scrollParent[0].scrollTop+o.scrollSpeed:e.pageY-this.overflowOffset.top<o.scrollSensitivity&&(this.scrollParent[0].scrollTop=r=this.scrollParent[0].scrollTop-o.scrollSpeed),this.overflowOffset.left+this.scrollParent[0].offsetWidth-e.pageX<o.scrollSensitivity?this.scrollParent[0].scrollLeft=r=this.scrollParent[0].scrollLeft+o.scrollSpeed:e.pageX-this.overflowOffset.left<o.scrollSensitivity&&(this.scrollParent[0].scrollLeft=r=this.scrollParent[0].scrollLeft-o.scrollSpeed)):(e.pageY-t(document).scrollTop()<o.scrollSensitivity?r=t(document).scrollTop(t(document).scrollTop()-o.scrollSpeed):t(window).height()-(e.pageY-t(document).scrollTop())<o.scrollSensitivity&&(r=t(document).scrollTop(t(document).scrollTop()+o.scrollSpeed)),e.pageX-t(document).scrollLeft()<o.scrollSensitivity?r=t(document).scrollLeft(t(document).scrollLeft()-o.scrollSpeed):t(window).width()-(e.pageX-t(document).scrollLeft())<o.scrollSensitivity&&(r=t(document).scrollLeft(t(document).scrollLeft()+o.scrollSpeed))),r!==!1&&t.ui.ddmanager&&!o.dropBehaviour&&t.ui.ddmanager.prepareOffsets(this,e)),this.positionAbs=this._convertPositionTo("absolute"),this.options.axis&&"y"===this.options.axis||(this.helper[0].style.left=this.position.left+"px"),this.options.axis&&"x"===this.options.axis||(this.helper[0].style.top=this.position.top+"px"),i=this.items.length-1;i>=0;i--)if(s=this.items[i],n=s.item[0],a=this._intersectsWithPointer(s),a&&s.instance===this.currentContainer&&n!==this.currentItem[0]&&this.placeholder[1===a?"next":"prev"]()[0]!==n&&!t.contains(this.placeholder[0],n)&&("semi-dynamic"===this.options.type?!t.contains(this.element[0],n):!0)){if(this.direction=1===a?"down":"up","pointer"!==this.options.tolerance&&!this._intersectsWithSides(s))break;this._rearrange(e,s),this._trigger("change",e,this._uiHash());break}return this._contactContainers(e),t.ui.ddmanager&&t.ui.ddmanager.drag(this,e),this._trigger("sort",e,this._uiHash()),this.lastPositionAbs=this.positionAbs,!1},_mouseStop:function(e,i){if(e){if(t.ui.ddmanager&&!this.options.dropBehaviour&&t.ui.ddmanager.drop(this,e),this.options.revert){var s=this,n=this.placeholder.offset(),a=this.options.axis,o={};a&&"x"!==a||(o.left=n.left-this.offset.parent.left-this.margins.left+(this.offsetParent[0]===document.body?0:this.offsetParent[0].scrollLeft)),a&&"y"!==a||(o.top=n.top-this.offset.parent.top-this.margins.top+(this.offsetParent[0]===document.body?0:this.offsetParent[0].scrollTop)),this.reverting=!0,t(this.helper).animate(o,parseInt(this.options.revert,10)||500,function(){s._clear(e)})}else this._clear(e,i);return!1}},cancel:function(){if(this.dragging){this._mouseUp({target:null}),"original"===this.options.helper?this.currentItem.css(this._storedCSS).removeClass("ui-sortable-helper"):this.currentItem.show();for(var e=this.containers.length-1;e>=0;e--)this.containers[e]._trigger("deactivate",null,this._uiHash(this)),this.containers[e].containerCache.over&&(this.containers[e]._trigger("out",null,this._uiHash(this)),this.containers[e].containerCache.over=0)}return this.placeholder&&(this.placeholder[0].parentNode&&this.placeholder[0].parentNode.removeChild(this.placeholder[0]),"original"!==this.options.helper&&this.helper&&this.helper[0].parentNode&&this.helper.remove(),t.extend(this,{helper:null,dragging:!1,reverting:!1,_noFinalSort:null}),this.domPosition.prev?t(this.domPosition.prev).after(this.currentItem):t(this.domPosition.parent).prepend(this.currentItem)),this},serialize:function(e){var i=this._getItemsAsjQuery(e&&e.connected),s=[];return e=e||{},t(i).each(function(){var i=(t(e.item||this).attr(e.attribute||"id")||"").match(e.expression||/(.+)[\-=_](.+)/);i&&s.push((e.key||i[1]+"[]")+"="+(e.key&&e.expression?i[1]:i[2]))}),!s.length&&e.key&&s.push(e.key+"="),s.join("&")},toArray:function(e){var i=this._getItemsAsjQuery(e&&e.connected),s=[];return e=e||{},i.each(function(){s.push(t(e.item||this).attr(e.attribute||"id")||"")}),s},_intersectsWith:function(t){var e=this.positionAbs.left,i=e+this.helperProportions.width,s=this.positionAbs.top,n=s+this.helperProportions.height,a=t.left,o=a+t.width,r=t.top,h=r+t.height,l=this.offset.click.top,c=this.offset.click.left,u=s+l>r&&h>s+l&&e+c>a&&o>e+c;return"pointer"===this.options.tolerance||this.options.forcePointerForContainers||"pointer"!==this.options.tolerance&&this.helperProportions[this.floating?"width":"height"]>t[this.floating?"width":"height"]?u:e+this.helperProportions.width/2>a&&o>i-this.helperProportions.width/2&&s+this.helperProportions.height/2>r&&h>n-this.helperProportions.height/2},_intersectsWithPointer:function(t){var i="x"===this.options.axis||e(this.positionAbs.top+this.offset.click.top,t.top,t.height),s="y"===this.options.axis||e(this.positionAbs.left+this.offset.click.left,t.left,t.width),n=i&&s,a=this._getDragVerticalDirection(),o=this._getDragHorizontalDirection();return n?this.floating?o&&"right"===o||"down"===a?2:1:a&&("down"===a?2:1):!1},_intersectsWithSides:function(t){var i=e(this.positionAbs.top+this.offset.click.top,t.top+t.height/2,t.height),s=e(this.positionAbs.left+this.offset.click.left,t.left+t.width/2,t.width),n=this._getDragVerticalDirection(),a=this._getDragHorizontalDirection();return this.floating&&a?"right"===a&&s||"left"===a&&!s:n&&("down"===n&&i||"up"===n&&!i)},_getDragVerticalDirection:function(){var t=this.positionAbs.top-this.lastPositionAbs.top;return 0!==t&&(t>0?"down":"up")},_getDragHorizontalDirection:function(){var t=this.positionAbs.left-this.lastPositionAbs.left;return 0!==t&&(t>0?"right":"left")},refresh:function(t){return this._refreshItems(t),this.refreshPositions(),this},_connectWith:function(){var t=this.options;return t.connectWith.constructor===String?[t.connectWith]:t.connectWith},_getItemsAsjQuery:function(e){var i,s,n,a,o=[],r=[],h=this._connectWith();if(h&&e)for(i=h.length-1;i>=0;i--)for(n=t(h[i]),s=n.length-1;s>=0;s--)a=t.data(n[s],this.widgetFullName),a&&a!==this&&!a.options.disabled&&r.push([t.isFunction(a.options.items)?a.options.items.call(a.element):t(a.options.items,a.element).not(".ui-sortable-helper").not(".ui-sortable-placeholder"),a]);for(r.push([t.isFunction(this.options.items)?this.options.items.call(this.element,null,{options:this.options,item:this.currentItem}):t(this.options.items,this.element).not(".ui-sortable-helper").not(".ui-sortable-placeholder"),this]),i=r.length-1;i>=0;i--)r[i][0].each(function(){o.push(this)});return t(o)},_removeCurrentsFromItems:function(){var e=this.currentItem.find(":data("+this.widgetName+"-item)");this.items=t.grep(this.items,function(t){for(var i=0;e.length>i;i++)if(e[i]===t.item[0])return!1;return!0})},_refreshItems:function(e){this.items=[],this.containers=[this];var i,s,n,a,o,r,h,l,c=this.items,u=[[t.isFunction(this.options.items)?this.options.items.call(this.element[0],e,{item:this.currentItem}):t(this.options.items,this.element),this]],d=this._connectWith();if(d&&this.ready)for(i=d.length-1;i>=0;i--)for(n=t(d[i]),s=n.length-1;s>=0;s--)a=t.data(n[s],this.widgetFullName),a&&a!==this&&!a.options.disabled&&(u.push([t.isFunction(a.options.items)?a.options.items.call(a.element[0],e,{item:this.currentItem}):t(a.options.items,a.element),a]),this.containers.push(a));for(i=u.length-1;i>=0;i--)for(o=u[i][1],r=u[i][0],s=0,l=r.length;l>s;s++)h=t(r[s]),h.data(this.widgetName+"-item",o),c.push({item:h,instance:o,width:0,height:0,left:0,top:0})},refreshPositions:function(e){this.offsetParent&&this.helper&&(this.offset.parent=this._getParentOffset());var i,s,n,a;for(i=this.items.length-1;i>=0;i--)s=this.items[i],s.instance!==this.currentContainer&&this.currentContainer&&s.item[0]!==this.currentItem[0]||(n=this.options.toleranceElement?t(this.options.toleranceElement,s.item):s.item,e||(s.width=n.outerWidth(),s.height=n.outerHeight()),a=n.offset(),s.left=a.left,s.top=a.top);if(this.options.custom&&this.options.custom.refreshContainers)this.options.custom.refreshContainers.call(this);else for(i=this.containers.length-1;i>=0;i--)a=this.containers[i].element.offset(),this.containers[i].containerCache.left=a.left,this.containers[i].containerCache.top=a.top,this.containers[i].containerCache.width=this.containers[i].element.outerWidth(),this.containers[i].containerCache.height=this.containers[i].element.outerHeight();return this},_createPlaceholder:function(e){e=e||this;var i,s=e.options;s.placeholder&&s.placeholder.constructor!==String||(i=s.placeholder,s.placeholder={element:function(){var s=e.currentItem[0].nodeName.toLowerCase(),n=t(e.document[0].createElement(s)).addClass(i||e.currentItem[0].className+" ui-sortable-placeholder").removeClass("ui-sortable-helper");return"tr"===s?n.append("<td colspan='99'>&#160;</td>"):"img"===s&&n.attr("src",e.currentItem.attr("src")),i||n.css("visibility","hidden"),n},update:function(t,n){(!i||s.forcePlaceholderSize)&&(n.height()||n.height(e.currentItem.innerHeight()-parseInt(e.currentItem.css("paddingTop")||0,10)-parseInt(e.currentItem.css("paddingBottom")||0,10)),n.width()||n.width(e.currentItem.innerWidth()-parseInt(e.currentItem.css("paddingLeft")||0,10)-parseInt(e.currentItem.css("paddingRight")||0,10)))}}),e.placeholder=t(s.placeholder.element.call(e.element,e.currentItem)),e.currentItem.after(e.placeholder),s.placeholder.update(e,e.placeholder)},_contactContainers:function(s){var n,a,o,r,h,l,c,u,d,p,f=null,m=null;for(n=this.containers.length-1;n>=0;n--)if(!t.contains(this.currentItem[0],this.containers[n].element[0]))if(this._intersectsWith(this.containers[n].containerCache)){if(f&&t.contains(this.containers[n].element[0],f.element[0]))continue;f=this.containers[n],m=n}else this.containers[n].containerCache.over&&(this.containers[n]._trigger("out",s,this._uiHash(this)),this.containers[n].containerCache.over=0);if(f)if(1===this.containers.length)this.containers[m].containerCache.over||(this.containers[m]._trigger("over",s,this._uiHash(this)),this.containers[m].containerCache.over=1);else{for(o=1e4,r=null,p=f.floating||i(this.currentItem),h=p?"left":"top",l=p?"width":"height",c=this.positionAbs[h]+this.offset.click[h],a=this.items.length-1;a>=0;a--)t.contains(this.containers[m].element[0],this.items[a].item[0])&&this.items[a].item[0]!==this.currentItem[0]&&(!p||e(this.positionAbs.top+this.offset.click.top,this.items[a].top,this.items[a].height))&&(u=this.items[a].item.offset()[h],d=!1,Math.abs(u-c)>Math.abs(u+this.items[a][l]-c)&&(d=!0,u+=this.items[a][l]),o>Math.abs(u-c)&&(o=Math.abs(u-c),r=this.items[a],this.direction=d?"up":"down"));if(!r&&!this.options.dropOnEmpty)return;if(this.currentContainer===this.containers[m])return;r?this._rearrange(s,r,null,!0):this._rearrange(s,null,this.containers[m].element,!0),this._trigger("change",s,this._uiHash()),this.containers[m]._trigger("change",s,this._uiHash(this)),this.currentContainer=this.containers[m],this.options.placeholder.update(this.currentContainer,this.placeholder),this.containers[m]._trigger("over",s,this._uiHash(this)),this.containers[m].containerCache.over=1}},_createHelper:function(e){var i=this.options,s=t.isFunction(i.helper)?t(i.helper.apply(this.element[0],[e,this.currentItem])):"clone"===i.helper?this.currentItem.clone():this.currentItem;return s.parents("body").length||t("parent"!==i.appendTo?i.appendTo:this.currentItem[0].parentNode)[0].appendChild(s[0]),s[0]===this.currentItem[0]&&(this._storedCSS={width:this.currentItem[0].style.width,height:this.currentItem[0].style.height,position:this.currentItem.css("position"),top:this.currentItem.css("top"),left:this.currentItem.css("left")}),(!s[0].style.width||i.forceHelperSize)&&s.width(this.currentItem.width()),(!s[0].style.height||i.forceHelperSize)&&s.height(this.currentItem.height()),s},_adjustOffsetFromHelper:function(e){"string"==typeof e&&(e=e.split(" ")),t.isArray(e)&&(e={left:+e[0],top:+e[1]||0}),"left"in e&&(this.offset.click.left=e.left+this.margins.left),"right"in e&&(this.offset.click.left=this.helperProportions.width-e.right+this.margins.left),"top"in e&&(this.offset.click.top=e.top+this.margins.top),"bottom"in e&&(this.offset.click.top=this.helperProportions.height-e.bottom+this.margins.top)},_getParentOffset:function(){this.offsetParent=this.helper.offsetParent();var e=this.offsetParent.offset();return"absolute"===this.cssPosition&&this.scrollParent[0]!==document&&t.contains(this.scrollParent[0],this.offsetParent[0])&&(e.left+=this.scrollParent.scrollLeft(),e.top+=this.scrollParent.scrollTop()),(this.offsetParent[0]===document.body||this.offsetParent[0].tagName&&"html"===this.offsetParent[0].tagName.toLowerCase()&&t.ui.ie)&&(e={top:0,left:0}),{top:e.top+(parseInt(this.offsetParent.css("borderTopWidth"),10)||0),left:e.left+(parseInt(this.offsetParent.css("borderLeftWidth"),10)||0)}},_getRelativeOffset:function(){if("relative"===this.cssPosition){var t=this.currentItem.position();return{top:t.top-(parseInt(this.helper.css("top"),10)||0)+this.scrollParent.scrollTop(),left:t.left-(parseInt(this.helper.css("left"),10)||0)+this.scrollParent.scrollLeft()}}return{top:0,left:0}},_cacheMargins:function(){this.margins={left:parseInt(this.currentItem.css("marginLeft"),10)||0,top:parseInt(this.currentItem.css("marginTop"),10)||0}},_cacheHelperProportions:function(){this.helperProportions={width:this.helper.outerWidth(),height:this.helper.outerHeight()}},_setContainment:function(){var e,i,s,n=this.options;"parent"===n.containment&&(n.containment=this.helper[0].parentNode),("document"===n.containment||"window"===n.containment)&&(this.containment=[0-this.offset.relative.left-this.offset.parent.left,0-this.offset.relative.top-this.offset.parent.top,t("document"===n.containment?document:window).width()-this.helperProportions.width-this.margins.left,(t("document"===n.containment?document:window).height()||document.body.parentNode.scrollHeight)-this.helperProportions.height-this.margins.top]),/^(document|window|parent)$/.test(n.containment)||(e=t(n.containment)[0],i=t(n.containment).offset(),s="hidden"!==t(e).css("overflow"),this.containment=[i.left+(parseInt(t(e).css("borderLeftWidth"),10)||0)+(parseInt(t(e).css("paddingLeft"),10)||0)-this.margins.left,i.top+(parseInt(t(e).css("borderTopWidth"),10)||0)+(parseInt(t(e).css("paddingTop"),10)||0)-this.margins.top,i.left+(s?Math.max(e.scrollWidth,e.offsetWidth):e.offsetWidth)-(parseInt(t(e).css("borderLeftWidth"),10)||0)-(parseInt(t(e).css("paddingRight"),10)||0)-this.helperProportions.width-this.margins.left,i.top+(s?Math.max(e.scrollHeight,e.offsetHeight):e.offsetHeight)-(parseInt(t(e).css("borderTopWidth"),10)||0)-(parseInt(t(e).css("paddingBottom"),10)||0)-this.helperProportions.height-this.margins.top])},_convertPositionTo:function(e,i){i||(i=this.position);var s="absolute"===e?1:-1,n="absolute"!==this.cssPosition||this.scrollParent[0]!==document&&t.contains(this.scrollParent[0],this.offsetParent[0])?this.scrollParent:this.offsetParent,a=/(html|body)/i.test(n[0].tagName);return{top:i.top+this.offset.relative.top*s+this.offset.parent.top*s-("fixed"===this.cssPosition?-this.scrollParent.scrollTop():a?0:n.scrollTop())*s,left:i.left+this.offset.relative.left*s+this.offset.parent.left*s-("fixed"===this.cssPosition?-this.scrollParent.scrollLeft():a?0:n.scrollLeft())*s}},_generatePosition:function(e){var i,s,n=this.options,a=e.pageX,o=e.pageY,r="absolute"!==this.cssPosition||this.scrollParent[0]!==document&&t.contains(this.scrollParent[0],this.offsetParent[0])?this.scrollParent:this.offsetParent,h=/(html|body)/i.test(r[0].tagName);return"relative"!==this.cssPosition||this.scrollParent[0]!==document&&this.scrollParent[0]!==this.offsetParent[0]||(this.offset.relative=this._getRelativeOffset()),this.originalPosition&&(this.containment&&(e.pageX-this.offset.click.left<this.containment[0]&&(a=this.containment[0]+this.offset.click.left),e.pageY-this.offset.click.top<this.containment[1]&&(o=this.containment[1]+this.offset.click.top),e.pageX-this.offset.click.left>this.containment[2]&&(a=this.containment[2]+this.offset.click.left),e.pageY-this.offset.click.top>this.containment[3]&&(o=this.containment[3]+this.offset.click.top)),n.grid&&(i=this.originalPageY+Math.round((o-this.originalPageY)/n.grid[1])*n.grid[1],o=this.containment?i-this.offset.click.top>=this.containment[1]&&i-this.offset.click.top<=this.containment[3]?i:i-this.offset.click.top>=this.containment[1]?i-n.grid[1]:i+n.grid[1]:i,s=this.originalPageX+Math.round((a-this.originalPageX)/n.grid[0])*n.grid[0],a=this.containment?s-this.offset.click.left>=this.containment[0]&&s-this.offset.click.left<=this.containment[2]?s:s-this.offset.click.left>=this.containment[0]?s-n.grid[0]:s+n.grid[0]:s)),{top:o-this.offset.click.top-this.offset.relative.top-this.offset.parent.top+("fixed"===this.cssPosition?-this.scrollParent.scrollTop():h?0:r.scrollTop()),left:a-this.offset.click.left-this.offset.relative.left-this.offset.parent.left+("fixed"===this.cssPosition?-this.scrollParent.scrollLeft():h?0:r.scrollLeft())}},_rearrange:function(t,e,i,s){i?i[0].appendChild(this.placeholder[0]):e.item[0].parentNode.insertBefore(this.placeholder[0],"down"===this.direction?e.item[0]:e.item[0].nextSibling),this.counter=this.counter?++this.counter:1;var n=this.counter;this._delay(function(){n===this.counter&&this.refreshPositions(!s)})},_clear:function(t,e){this.reverting=!1;var i,s=[];if(!this._noFinalSort&&this.currentItem.parent().length&&this.placeholder.before(this.currentItem),this._noFinalSort=null,this.helper[0]===this.currentItem[0]){for(i in this._storedCSS)("auto"===this._storedCSS[i]||"static"===this._storedCSS[i])&&(this._storedCSS[i]="");this.currentItem.css(this._storedCSS).removeClass("ui-sortable-helper")}else this.currentItem.show();for(this.fromOutside&&!e&&s.push(function(t){this._trigger("receive",t,this._uiHash(this.fromOutside))}),!this.fromOutside&&this.domPosition.prev===this.currentItem.prev().not(".ui-sortable-helper")[0]&&this.domPosition.parent===this.currentItem.parent()[0]||e||s.push(function(t){this._trigger("update",t,this._uiHash())}),this!==this.currentContainer&&(e||(s.push(function(t){this._trigger("remove",t,this._uiHash())}),s.push(function(t){return function(e){t._trigger("receive",e,this._uiHash(this))}}.call(this,this.currentContainer)),s.push(function(t){return function(e){t._trigger("update",e,this._uiHash(this))}}.call(this,this.currentContainer)))),i=this.containers.length-1;i>=0;i--)e||s.push(function(t){return function(e){t._trigger("deactivate",e,this._uiHash(this))}}.call(this,this.containers[i])),this.containers[i].containerCache.over&&(s.push(function(t){return function(e){t._trigger("out",e,this._uiHash(this))}}.call(this,this.containers[i])),this.containers[i].containerCache.over=0);if(this.storedCursor&&(this.document.find("body").css("cursor",this.storedCursor),this.storedStylesheet.remove()),this._storedOpacity&&this.helper.css("opacity",this._storedOpacity),this._storedZIndex&&this.helper.css("zIndex","auto"===this._storedZIndex?"":this._storedZIndex),this.dragging=!1,this.cancelHelperRemoval){if(!e){for(this._trigger("beforeStop",t,this._uiHash()),i=0;s.length>i;i++)s[i].call(this,t);this._trigger("stop",t,this._uiHash())}return this.fromOutside=!1,!1}if(e||this._trigger("beforeStop",t,this._uiHash()),this.placeholder[0].parentNode.removeChild(this.placeholder[0]),this.helper[0]!==this.currentItem[0]&&this.helper.remove(),this.helper=null,!e){for(i=0;s.length>i;i++)s[i].call(this,t);this._trigger("stop",t,this._uiHash())}return this.fromOutside=!1,!0},_trigger:function(){t.Widget.prototype._trigger.apply(this,arguments)===!1&&this.cancel()},_uiHash:function(e){var i=e||this;return{helper:i.helper,placeholder:i.placeholder||t([]),position:i.position,originalPosition:i.originalPosition,offset:i.positionAbs,item:i.currentItem,sender:e?e.element:null}}})})(jQuery);



/*jslint browser: true, eqeqeq: true, bitwise: true, newcap: true, immed: true, regexp: false */

/**
LazyLoad makes it easy and painless to lazily load one or more external
JavaScript or CSS files on demand either during or after the rendering of a web
page.

Supported browsers include Firefox 2+, IE6+, Safari 3+ (including Mobile
Safari), Google Chrome, and Opera 9+. Other browsers may or may not work and
are not officially supported.

Visit https://github.com/rgrove/lazyload/ for more info.

Copyright (c) 2011 Ryan Grove <ryan@wonko.com>
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@module lazyload
@class LazyLoad
@static
@version 2.0.3 (git)
*/

LazyLoad = (function (doc) {
  // -- Private Variables ------------------------------------------------------

  // User agent and feature test information.
  var env,

  // Reference to the <head> element (populated lazily).
  head,

  // Requests currently in progress, if any.
  pending = {},

  // Number of times we've polled to check whether a pending stylesheet has
  // finished loading. If this gets too high, we're probably stalled.
  pollCount = 0,

  // Queued requests.
  queue = {css: [], js: []},

  // Reference to the browser's list of stylesheets.
  styleSheets = doc.styleSheets;

  // -- Private Methods --------------------------------------------------------

  /**
  Creates and returns an HTML element with the specified name and attributes.

  @method createNode
  @param {String} name element name
  @param {Object} attrs name/value mapping of element attributes
  @return {HTMLElement}
  @private
  */
  function createNode(name, attrs) {
    var node = doc.createElement(name), attr;

    for (attr in attrs) {
      if (attrs.hasOwnProperty(attr)) {
        node.setAttribute(attr, attrs[attr]);
      }
    }

    return node;
  }

  /**
  Called when the current pending resource of the specified type has finished
  loading. Executes the associated callback (if any) and loads the next
  resource in the queue.

  @method finish
  @param {String} type resource type ('css' or 'js')
  @private
  */
  function finish(type) {
    var p = pending[type],
        callback,
        urls;

    if (p) {
      callback = p.callback;
      urls     = p.urls;

      urls.shift();
      pollCount = 0;

      // If this is the last of the pending URLs, execute the callback and
      // start the next request in the queue (if any).
      if (!urls.length) {
        callback && callback.call(p.context, p.obj);
        pending[type] = null;
        queue[type].length && load(type);
      }
    }
  }

  /**
  Populates the <code>env</code> variable with user agent and feature test
  information.

  @method getEnv
  @private
  */
  function getEnv() {
    var ua = navigator.userAgent;

    env = {
      // True if this browser supports disabling async mode on dynamically
      // created script nodes. See
      // http://wiki.whatwg.org/wiki/Dynamic_Script_Execution_Order
      async: doc.createElement('script').async === true
    };

    (env.webkit = /AppleWebKit\//.test(ua))
      || (env.ie = /MSIE/.test(ua))
      || (env.opera = /Opera/.test(ua))
      || (env.gecko = /Gecko\//.test(ua))
      || (env.unknown = true);
  }

  /**
  Loads the specified resources, or the next resource of the specified type
  in the queue if no resources are specified. If a resource of the specified
  type is already being loaded, the new request will be queued until the
  first request has been finished.

  When an array of resource URLs is specified, those URLs will be loaded in
  parallel if it is possible to do so while preserving execution order. All
  browsers support parallel loading of CSS, but only Firefox and Opera
  support parallel loading of scripts. In other browsers, scripts will be
  queued and loaded one at a time to ensure correct execution order.

  @method load
  @param {String} type resource type ('css' or 'js')
  @param {String|Array} urls (optional) URL or array of URLs to load
  @param {Function} callback (optional) callback function to execute when the
    resource is loaded
  @param {Object} obj (optional) object to pass to the callback function
  @param {Object} context (optional) if provided, the callback function will
    be executed in this object's context
  @private
  */
  function load(type, urls, callback, obj, context) {
    var _finish = function () { finish(type); },
        isCSS   = type === 'css',
        nodes   = [],
        i, len, node, p, pendingUrls, url;

    env || getEnv();

    if (urls) {
      // If urls is a string, wrap it in an array. Otherwise assume it's an
      // array and create a copy of it so modifications won't be made to the
      // original.
      urls = typeof urls === 'string' ? [urls] : urls.concat();

      // Create a request object for each URL. If multiple URLs are specified,
      // the callback will only be executed after all URLs have been loaded.
      //
      // Sadly, Firefox and Opera are the only browsers capable of loading
      // scripts in parallel while preserving execution order. In all other
      // browsers, scripts must be loaded sequentially.
      //
      // All browsers respect CSS specificity based on the order of the link
      // elements in the DOM, regardless of the order in which the stylesheets
      // are actually downloaded.
      if (isCSS || env.async || env.gecko || env.opera) {
        // Load in parallel.
        queue[type].push({
          urls    : urls,
          callback: callback,
          obj     : obj,
          context : context
        });
      } else {
        // Load sequentially.
        for (i = 0, len = urls.length; i < len; ++i) {
          queue[type].push({
            urls    : [urls[i]],
            callback: i === len - 1 ? callback : null, // callback is only added to the last URL
            obj     : obj,
            context : context
          });
        }
      }
    }

    // If a previous load request of this type is currently in progress, we'll
    // wait our turn. Otherwise, grab the next item in the queue.
    if (pending[type] || !(p = pending[type] = queue[type].shift())) {
      return;
    }

    head || (head = doc.head || doc.getElementsByTagName('head')[0]);
    pendingUrls = p.urls;

    for (i = 0, len = pendingUrls.length; i < len; ++i) {
      url = pendingUrls[i];

      if (isCSS) {
          node = env.gecko ? createNode('style') : createNode('link', {
            href: url,
            rel : 'stylesheet'
          });
      } else {
        node = createNode('script', {src: url});
        node.async = false;
      }

      node.className = 'lazyload';
      node.setAttribute('charset', 'utf-8');

      if (env.ie && !isCSS) {
        node.onreadystatechange = function () {
          if (/loaded|complete/.test(node.readyState)) {
            node.onreadystatechange = null;
            _finish();
          }
        };
      } else if (isCSS && (env.gecko || env.webkit)) {
        // Gecko and WebKit don't support the onload event on link nodes.
        if (env.webkit) {
          // In WebKit, we can poll for changes to document.styleSheets to
          // figure out when stylesheets have loaded.
          p.urls[i] = node.href; // resolve relative URLs (or polling won't work)
          pollWebKit();
        } else {
          // In Gecko, we can import the requested URL into a <style> node and
          // poll for the existence of node.sheet.cssRules. Props to Zach
          // Leatherman for calling my attention to this technique.
          node.innerHTML = '@import "' + url + '";';
          pollGecko(node);
        }
      } else {
        node.onload = node.onerror = _finish;
      }

      nodes.push(node);
    }

    for (i = 0, len = nodes.length; i < len; ++i) {
      head.appendChild(nodes[i]);
    }
  }

  /**
  Begins polling to determine when the specified stylesheet has finished loading
  in Gecko. Polling stops when all pending stylesheets have loaded or after 10
  seconds (to prevent stalls).

  Thanks to Zach Leatherman for calling my attention to the @import-based
  cross-domain technique used here, and to Oleg Slobodskoi for an earlier
  same-domain implementation. See Zach's blog for more details:
  http://www.zachleat.com/web/2010/07/29/load-css-dynamically/

  @method pollGecko
  @param {HTMLElement} node Style node to poll.
  @private
  */
  function pollGecko(node) {
    var hasRules;

    try {
      // We don't really need to store this value or ever refer to it again, but
      // if we don't store it, Closure Compiler assumes the code is useless and
      // removes it.
      hasRules = !!node.sheet.cssRules;
    } catch (ex) {
      // An exception means the stylesheet is still loading.
      pollCount += 1;

      if (pollCount < 200) {
        setTimeout(function () { pollGecko(node); }, 50);
      } else {
        // We've been polling for 10 seconds and nothing's happened. Stop
        // polling and finish the pending requests to avoid blocking further
        // requests.
        hasRules && finish('css');
      }

      return;
    }

    // If we get here, the stylesheet has loaded.
    finish('css');
  }

  /**
  Begins polling to determine when pending stylesheets have finished loading
  in WebKit. Polling stops when all pending stylesheets have loaded or after 10
  seconds (to prevent stalls).

  @method pollWebKit
  @private
  */
  function pollWebKit() {
    var css = pending.css, i;

    if (css) {
      i = styleSheets.length;

      // Look for a stylesheet matching the pending URL.
      while (--i >= 0) {
        if (styleSheets[i].href === css.urls[0]) {
          finish('css');
          break;
        }
      }

      pollCount += 1;

      if (css) {
        if (pollCount < 200) {
          setTimeout(pollWebKit, 50);
        } else {
          // We've been polling for 10 seconds and nothing's happened, which may
          // indicate that the stylesheet has been removed from the document
          // before it had a chance to load. Stop polling and finish the pending
          // request to prevent blocking further requests.
          finish('css');
        }
      }
    }
  }

  return {

    /**
    Requests the specified CSS URL or URLs and executes the specified
    callback (if any) when they have finished loading. If an array of URLs is
    specified, the stylesheets will be loaded in parallel and the callback
    will be executed after all stylesheets have finished loading.

    @method css
    @param {String|Array} urls CSS URL or array of CSS URLs to load
    @param {Function} callback (optional) callback function to execute when
      the specified stylesheets are loaded
    @param {Object} obj (optional) object to pass to the callback function
    @param {Object} context (optional) if provided, the callback function
      will be executed in this object's context
    @static
    */
    css: function (urls, callback, obj, context) {
      load('css', urls, callback, obj, context);
    },

    /**
    Requests the specified JavaScript URL or URLs and executes the specified
    callback (if any) when they have finished loading. If an array of URLs is
    specified and the browser supports it, the scripts will be loaded in
    parallel and the callback will be executed after all scripts have
    finished loading.

    Currently, only Firefox and Opera support parallel loading of scripts while
    preserving execution order. In other browsers, scripts will be
    queued and loaded one at a time to ensure correct execution order.

    @method js
    @param {String|Array} urls JS URL or array of JS URLs to load
    @param {Function} callback (optional) callback function to execute when
      the specified scripts are loaded
    @param {Object} obj (optional) object to pass to the callback function
    @param {Object} context (optional) if provided, the callback function
      will be executed in this object's context
    @static
    */
    js: function (urls, callback, obj, context) {
      load('js', urls, callback, obj, context);
    }

  };
})(this.document);



/*! Copyright (c) 2011 Brandon Aaron (http://brandonaaron.net)
 * Licensed under the MIT License (LICENSE.txt).
 *
 * Thanks to: http://adomas.org/javascript-mouse-wheel/ for some pointers.
 * Thanks to: Mathias Bank(http://www.mathias-bank.de) for a scope bug fix.
 * Thanks to: Seamus Leahy for adding deltaX and deltaY
 *
 * Version: 3.0.6
 * 
 * Requires: 1.2.2+
 */

(function($) {

var types = ['DOMMouseScroll', 'mousewheel'];

if ($.event.fixHooks) {
    for ( var i=types.length; i; ) {
        $.event.fixHooks[ types[--i] ] = $.event.mouseHooks;
    }
}

$.event.special.mousewheel = {
    setup: function() {
        if ( this.addEventListener ) {
            for ( var i=types.length; i; ) {
                this.addEventListener( types[--i], handler, false );
            }
        } else {
            this.onmousewheel = handler;
        }
    },
    
    teardown: function() {
        if ( this.removeEventListener ) {
            for ( var i=types.length; i; ) {
                this.removeEventListener( types[--i], handler, false );
            }
        } else {
            this.onmousewheel = null;
        }
    }
};

$.fn.extend({
    mousewheel: function(fn) {
        return fn ? this.bind("mousewheel", fn) : this.trigger("mousewheel");
    },
    
    unmousewheel: function(fn) {
        return this.unbind("mousewheel", fn);
    }
});


function handler(event) {
    var orgEvent = event || window.event, args = [].slice.call( arguments, 1 ), delta = 0, returnValue = true, deltaX = 0, deltaY = 0;
    event = $.event.fix(orgEvent);
    event.type = "mousewheel";
    
    // Old school scrollwheel delta
    if ( orgEvent.wheelDelta ) { delta = orgEvent.wheelDelta/120; }
    if ( orgEvent.detail     ) { delta = -orgEvent.detail/3; }
    
    // New school multidimensional scroll (touchpads) deltas
    deltaY = delta;
    
    // Gecko
    if ( orgEvent.axis !== undefined && orgEvent.axis === orgEvent.HORIZONTAL_AXIS ) {
        deltaY = 0;
        deltaX = -1*delta;
    }
    
    // Webkit
    if ( orgEvent.wheelDeltaY !== undefined ) { deltaY = orgEvent.wheelDeltaY/120; }
    if ( orgEvent.wheelDeltaX !== undefined ) { deltaX = -1*orgEvent.wheelDeltaX/120; }
    
    // Add event and delta to the front of the arguments
    args.unshift(event, delta, deltaX, deltaY);
    
    return ($.event.dispatch || $.event.handle).apply(this, args);
}

})(jQuery);



/**
 * jQuery mousehold plugin - fires an event while the mouse is clicked down.
 * Additionally, the function, when executed, is passed a single
 * argument representing the count of times the event has been fired during
 * this session of the mouse hold.
 *
 * @author Remy Sharp (leftlogic.com)
 * @date 2006-12-15
 * @example $("img").mousehold(200, function(i){  })
 * @desc Repeats firing the passed function while the mouse is clicked down
 *
 * @name mousehold
 * @type jQuery
 * @param Number timeout The frequency to repeat the event in milliseconds
 * @param Function fn A function to execute
 * @cat Plugin
 */

(function($) {

$.fn.mousehold = function(timeout, f) {
  if (timeout && typeof timeout == 'function') {
    f = timeout;
    timeout = 100;
  }
  if (f && typeof f == 'function') {
    var timer = 0;
    var fireStep = 0;
    return this.each(function() {
      $(this).mousedown(function() {
        fireStep = 1;
        var ctr = 0;
        var t = this;
        timer = setInterval(function() {
          ctr++;
          f.call(t, ctr);
          fireStep = 2;
        }, timeout);
      })

      clearMousehold = function() {
        clearInterval(timer);
        if (fireStep == 1) f.call(this, 1);
        fireStep = 0;
      }
      
      $(this).mouseout(clearMousehold);
      $(this).mouseup(clearMousehold);
    })
  }
}

})(jQuery);




var grch37 = {
  "1": {
    "size": 249250621,
    "bands": [
      {
        "id": "p11.1",
        "start": 121500001,
        "end": 125000000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 120600001,
        "end": 121500000,
        "type": "gneg"
      },
      {
        "id": "p12",
        "start": 117800001,
        "end": 120600000,
        "type": "gpos50"
      },
      {
        "id": "p13.1",
        "start": 116100001,
        "end": 117800000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 111800001,
        "end": 116100000,
        "type": "gpos50"
      },
      {
        "id": "p13.3",
        "start": 107200001,
        "end": 111800000,
        "type": "gneg"
      },
      {
        "id": "p21.1",
        "start": 102200001,
        "end": 107200000,
        "type": "gpos100"
      },
      {
        "id": "p21.2",
        "start": 99700001,
        "end": 102200000,
        "type": "gneg"
      },
      {
        "id": "p21.3",
        "start": 94700001,
        "end": 99700000,
        "type": "gpos75"
      },
      {
        "id": "p22.1",
        "start": 92000001,
        "end": 94700000,
        "type": "gneg"
      },
      {
        "id": "p22.2",
        "start": 88400001,
        "end": 92000000,
        "type": "gpos75"
      },
      {
        "id": "p22.3",
        "start": 84900001,
        "end": 88400000,
        "type": "gneg"
      },
      {
        "id": "p31.1",
        "start": 69700001,
        "end": 84900000,
        "type": "gpos100"
      },
      {
        "id": "p31.2",
        "start": 68900001,
        "end": 69700000,
        "type": "gneg"
      },
      {
        "id": "p31.3",
        "start": 61300001,
        "end": 68900000,
        "type": "gpos50"
      },
      {
        "id": "p32.1",
        "start": 59000001,
        "end": 61300000,
        "type": "gneg"
      },
      {
        "id": "p32.2",
        "start": 56100001,
        "end": 59000000,
        "type": "gpos50"
      },
      {
        "id": "p32.3",
        "start": 50700001,
        "end": 56100000,
        "type": "gneg"
      },
      {
        "id": "p33",
        "start": 46800001,
        "end": 50700000,
        "type": "gpos75"
      },
      {
        "id": "p34.1",
        "start": 44100001,
        "end": 46800000,
        "type": "gneg"
      },
      {
        "id": "p34.2",
        "start": 40100001,
        "end": 44100000,
        "type": "gpos25"
      },
      {
        "id": "p34.3",
        "start": 34600001,
        "end": 40100000,
        "type": "gneg"
      },
      {
        "id": "p35.1",
        "start": 32400001,
        "end": 34600000,
        "type": "gpos25"
      },
      {
        "id": "p35.2",
        "start": 30200001,
        "end": 32400000,
        "type": "gneg"
      },
      {
        "id": "p35.3",
        "start": 28000001,
        "end": 30200000,
        "type": "gpos25"
      },
      {
        "id": "p36.11",
        "start": 23900001,
        "end": 28000000,
        "type": "gneg"
      },
      {
        "id": "p36.12",
        "start": 20400001,
        "end": 23900000,
        "type": "gpos25"
      },
      {
        "id": "p36.13",
        "start": 16200001,
        "end": 20400000,
        "type": "gneg"
      },
      {
        "id": "p36.21",
        "start": 12700001,
        "end": 16200000,
        "type": "gpos50"
      },
      {
        "id": "p36.22",
        "start": 9200001,
        "end": 12700000,
        "type": "gneg"
      },
      {
        "id": "p36.23",
        "start": 7200001,
        "end": 9200000,
        "type": "gpos25"
      },
      {
        "id": "p36.31",
        "start": 5400001,
        "end": 7200000,
        "type": "gneg"
      },
      {
        "id": "p36.32",
        "start": 2300001,
        "end": 5400000,
        "type": "gpos25"
      },
      {
        "id": "p36.33",
        "start": 1,
        "end": 2300000,
        "type": "gneg"
      },
      {
        "id": "q11",
        "start": 125000001,
        "end": 128900000,
        "type": "acen"
      },
      {
        "id": "q12",
        "start": 128900001,
        "end": 142600000,
        "type": "gvar"
      },
      {
        "id": "q21.1",
        "start": 142600001,
        "end": 147000000,
        "type": "gneg"
      },
      {
        "id": "q21.2",
        "start": 147000001,
        "end": 150300000,
        "type": "gpos50"
      },
      {
        "id": "q21.3",
        "start": 150300001,
        "end": 155000000,
        "type": "gneg"
      },
      {
        "id": "q22",
        "start": 155000001,
        "end": 156500000,
        "type": "gpos50"
      },
      {
        "id": "q23.1",
        "start": 156500001,
        "end": 159100000,
        "type": "gneg"
      },
      {
        "id": "q23.2",
        "start": 159100001,
        "end": 160500000,
        "type": "gpos50"
      },
      {
        "id": "q23.3",
        "start": 160500001,
        "end": 165500000,
        "type": "gneg"
      },
      {
        "id": "q24.1",
        "start": 165500001,
        "end": 167200000,
        "type": "gpos50"
      },
      {
        "id": "q24.2",
        "start": 167200001,
        "end": 170900000,
        "type": "gneg"
      },
      {
        "id": "q24.3",
        "start": 170900001,
        "end": 172900000,
        "type": "gpos75"
      },
      {
        "id": "q25.1",
        "start": 172900001,
        "end": 176000000,
        "type": "gneg"
      },
      {
        "id": "q25.2",
        "start": 176000001,
        "end": 180300000,
        "type": "gpos50"
      },
      {
        "id": "q25.3",
        "start": 180300001,
        "end": 185800000,
        "type": "gneg"
      },
      {
        "id": "q31.1",
        "start": 185800001,
        "end": 190800000,
        "type": "gpos100"
      },
      {
        "id": "q31.2",
        "start": 190800001,
        "end": 193800000,
        "type": "gneg"
      },
      {
        "id": "q31.3",
        "start": 193800001,
        "end": 198700000,
        "type": "gpos100"
      },
      {
        "id": "q32.1",
        "start": 198700001,
        "end": 207200000,
        "type": "gneg"
      },
      {
        "id": "q32.2",
        "start": 207200001,
        "end": 211500000,
        "type": "gpos25"
      },
      {
        "id": "q32.3",
        "start": 211500001,
        "end": 214500000,
        "type": "gneg"
      },
      {
        "id": "q41",
        "start": 214500001,
        "end": 224100000,
        "type": "gpos100"
      },
      {
        "id": "q42.11",
        "start": 224100001,
        "end": 224600000,
        "type": "gneg"
      },
      {
        "id": "q42.12",
        "start": 224600001,
        "end": 227000000,
        "type": "gpos25"
      },
      {
        "id": "q42.13",
        "start": 227000001,
        "end": 230700000,
        "type": "gneg"
      },
      {
        "id": "q42.2",
        "start": 230700001,
        "end": 234700000,
        "type": "gpos50"
      },
      {
        "id": "q42.3",
        "start": 234700001,
        "end": 236600000,
        "type": "gneg"
      },
      {
        "id": "q43",
        "start": 236600001,
        "end": 243700000,
        "type": "gpos75"
      },
      {
        "id": "q44",
        "start": 243700001,
        "end": 249250621,
        "type": "gneg"
      }
    ]
  },
  "2": {
    "size": 243199373,
    "bands": [
      {
        "id": "p11.1",
        "start": 90500001,
        "end": 93300000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 83300001,
        "end": 90500000,
        "type": "gneg"
      },
      {
        "id": "p12",
        "start": 75000001,
        "end": 83300000,
        "type": "gpos100"
      },
      {
        "id": "p13.1",
        "start": 73500001,
        "end": 75000000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 71500001,
        "end": 73500000,
        "type": "gpos50"
      },
      {
        "id": "p13.3",
        "start": 68600001,
        "end": 71500000,
        "type": "gneg"
      },
      {
        "id": "p14",
        "start": 64100001,
        "end": 68600000,
        "type": "gpos50"
      },
      {
        "id": "p15",
        "start": 61300001,
        "end": 64100000,
        "type": "gneg"
      },
      {
        "id": "p16.1",
        "start": 55000001,
        "end": 61300000,
        "type": "gpos100"
      },
      {
        "id": "p16.2",
        "start": 52900001,
        "end": 55000000,
        "type": "gneg"
      },
      {
        "id": "p16.3",
        "start": 47800001,
        "end": 52900000,
        "type": "gpos100"
      },
      {
        "id": "p21",
        "start": 41800001,
        "end": 47800000,
        "type": "gneg"
      },
      {
        "id": "p22.1",
        "start": 38600001,
        "end": 41800000,
        "type": "gpos50"
      },
      {
        "id": "p22.2",
        "start": 36600001,
        "end": 38600000,
        "type": "gneg"
      },
      {
        "id": "p22.3",
        "start": 32100001,
        "end": 36600000,
        "type": "gpos75"
      },
      {
        "id": "p23.1",
        "start": 30000001,
        "end": 32100000,
        "type": "gneg"
      },
      {
        "id": "p23.2",
        "start": 27900001,
        "end": 30000000,
        "type": "gpos25"
      },
      {
        "id": "p23.3",
        "start": 24000001,
        "end": 27900000,
        "type": "gneg"
      },
      {
        "id": "p24.1",
        "start": 19200001,
        "end": 24000000,
        "type": "gpos75"
      },
      {
        "id": "p24.2",
        "start": 16700001,
        "end": 19200000,
        "type": "gneg"
      },
      {
        "id": "p24.3",
        "start": 12200001,
        "end": 16700000,
        "type": "gpos75"
      },
      {
        "id": "p25.1",
        "start": 7100001,
        "end": 12200000,
        "type": "gneg"
      },
      {
        "id": "p25.2",
        "start": 4400001,
        "end": 7100000,
        "type": "gpos50"
      },
      {
        "id": "p25.3",
        "start": 1,
        "end": 4400000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 93300001,
        "end": 96800000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 96800001,
        "end": 102700000,
        "type": "gneg"
      },
      {
        "id": "q12.1",
        "start": 102700001,
        "end": 106000000,
        "type": "gpos50"
      },
      {
        "id": "q12.2",
        "start": 106000001,
        "end": 107500000,
        "type": "gneg"
      },
      {
        "id": "q12.3",
        "start": 107500001,
        "end": 110200000,
        "type": "gpos25"
      },
      {
        "id": "q13",
        "start": 110200001,
        "end": 114400000,
        "type": "gneg"
      },
      {
        "id": "q14.1",
        "start": 114400001,
        "end": 118800000,
        "type": "gpos50"
      },
      {
        "id": "q14.2",
        "start": 118800001,
        "end": 122400000,
        "type": "gneg"
      },
      {
        "id": "q14.3",
        "start": 122400001,
        "end": 129900000,
        "type": "gpos50"
      },
      {
        "id": "q21.1",
        "start": 129900001,
        "end": 132500000,
        "type": "gneg"
      },
      {
        "id": "q21.2",
        "start": 132500001,
        "end": 135100000,
        "type": "gpos25"
      },
      {
        "id": "q21.3",
        "start": 135100001,
        "end": 136800000,
        "type": "gneg"
      },
      {
        "id": "q22.1",
        "start": 136800001,
        "end": 142200000,
        "type": "gpos100"
      },
      {
        "id": "q22.2",
        "start": 142200001,
        "end": 144100000,
        "type": "gneg"
      },
      {
        "id": "q22.3",
        "start": 144100001,
        "end": 148700000,
        "type": "gpos100"
      },
      {
        "id": "q23.1",
        "start": 148700001,
        "end": 149900000,
        "type": "gneg"
      },
      {
        "id": "q23.2",
        "start": 149900001,
        "end": 150500000,
        "type": "gpos25"
      },
      {
        "id": "q23.3",
        "start": 150500001,
        "end": 154900000,
        "type": "gneg"
      },
      {
        "id": "q24.1",
        "start": 154900001,
        "end": 159800000,
        "type": "gpos75"
      },
      {
        "id": "q24.2",
        "start": 159800001,
        "end": 163700000,
        "type": "gneg"
      },
      {
        "id": "q24.3",
        "start": 163700001,
        "end": 169700000,
        "type": "gpos75"
      },
      {
        "id": "q31.1",
        "start": 169700001,
        "end": 178000000,
        "type": "gneg"
      },
      {
        "id": "q31.2",
        "start": 178000001,
        "end": 180600000,
        "type": "gpos50"
      },
      {
        "id": "q31.3",
        "start": 180600001,
        "end": 183000000,
        "type": "gneg"
      },
      {
        "id": "q32.1",
        "start": 183000001,
        "end": 189400000,
        "type": "gpos75"
      },
      {
        "id": "q32.2",
        "start": 189400001,
        "end": 191900000,
        "type": "gneg"
      },
      {
        "id": "q32.3",
        "start": 191900001,
        "end": 197400000,
        "type": "gpos75"
      },
      {
        "id": "q33.1",
        "start": 197400001,
        "end": 203300000,
        "type": "gneg"
      },
      {
        "id": "q33.2",
        "start": 203300001,
        "end": 204900000,
        "type": "gpos50"
      },
      {
        "id": "q33.3",
        "start": 204900001,
        "end": 209000000,
        "type": "gneg"
      },
      {
        "id": "q34",
        "start": 209000001,
        "end": 215300000,
        "type": "gpos100"
      },
      {
        "id": "q35",
        "start": 215300001,
        "end": 221500000,
        "type": "gneg"
      },
      {
        "id": "q36.1",
        "start": 221500001,
        "end": 225200000,
        "type": "gpos75"
      },
      {
        "id": "q36.2",
        "start": 225200001,
        "end": 226100000,
        "type": "gneg"
      },
      {
        "id": "q36.3",
        "start": 226100001,
        "end": 231000000,
        "type": "gpos100"
      },
      {
        "id": "q37.1",
        "start": 231000001,
        "end": 235600000,
        "type": "gneg"
      },
      {
        "id": "q37.2",
        "start": 235600001,
        "end": 237300000,
        "type": "gpos50"
      },
      {
        "id": "q37.3",
        "start": 237300001,
        "end": 243199373,
        "type": "gneg"
      }
    ]
  },
  "3": {
    "size": 198022430,
    "bands": [
      {
        "id": "p11.1",
        "start": 87900001,
        "end": 91000000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 87200001,
        "end": 87900000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 83500001,
        "end": 87200000,
        "type": "gpos75"
      },
      {
        "id": "p12.2",
        "start": 79800001,
        "end": 83500000,
        "type": "gneg"
      },
      {
        "id": "p12.3",
        "start": 74200001,
        "end": 79800000,
        "type": "gpos75"
      },
      {
        "id": "p13",
        "start": 69800001,
        "end": 74200000,
        "type": "gneg"
      },
      {
        "id": "p14.1",
        "start": 63700001,
        "end": 69800000,
        "type": "gpos50"
      },
      {
        "id": "p14.2",
        "start": 58600001,
        "end": 63700000,
        "type": "gneg"
      },
      {
        "id": "p14.3",
        "start": 54400001,
        "end": 58600000,
        "type": "gpos50"
      },
      {
        "id": "p21.1",
        "start": 52300001,
        "end": 54400000,
        "type": "gneg"
      },
      {
        "id": "p21.2",
        "start": 50600001,
        "end": 52300000,
        "type": "gpos25"
      },
      {
        "id": "p21.31",
        "start": 44200001,
        "end": 50600000,
        "type": "gneg"
      },
      {
        "id": "p21.32",
        "start": 44100001,
        "end": 44200000,
        "type": "gpos50"
      },
      {
        "id": "p21.33",
        "start": 43700001,
        "end": 44100000,
        "type": "gneg"
      },
      {
        "id": "p22.1",
        "start": 39400001,
        "end": 43700000,
        "type": "gpos75"
      },
      {
        "id": "p22.2",
        "start": 36500001,
        "end": 39400000,
        "type": "gneg"
      },
      {
        "id": "p22.3",
        "start": 32100001,
        "end": 36500000,
        "type": "gpos50"
      },
      {
        "id": "p23",
        "start": 30900001,
        "end": 32100000,
        "type": "gneg"
      },
      {
        "id": "p24.1",
        "start": 26400001,
        "end": 30900000,
        "type": "gpos75"
      },
      {
        "id": "p24.2",
        "start": 23900001,
        "end": 26400000,
        "type": "gneg"
      },
      {
        "id": "p24.3",
        "start": 16400001,
        "end": 23900000,
        "type": "gpos100"
      },
      {
        "id": "p25.1",
        "start": 13300001,
        "end": 16400000,
        "type": "gneg"
      },
      {
        "id": "p25.2",
        "start": 11800001,
        "end": 13300000,
        "type": "gpos25"
      },
      {
        "id": "p25.3",
        "start": 8700001,
        "end": 11800000,
        "type": "gneg"
      },
      {
        "id": "p26.1",
        "start": 4000001,
        "end": 8700000,
        "type": "gpos50"
      },
      {
        "id": "p26.2",
        "start": 2800001,
        "end": 4000000,
        "type": "gneg"
      },
      {
        "id": "p26.3",
        "start": 1,
        "end": 2800000,
        "type": "gpos50"
      },
      {
        "id": "q11.1",
        "start": 91000001,
        "end": 93900000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 93900001,
        "end": 98300000,
        "type": "gvar"
      },
      {
        "id": "q12.1",
        "start": 98300001,
        "end": 100000000,
        "type": "gneg"
      },
      {
        "id": "q12.2",
        "start": 100000001,
        "end": 100900000,
        "type": "gpos25"
      },
      {
        "id": "q12.3",
        "start": 100900001,
        "end": 102800000,
        "type": "gneg"
      },
      {
        "id": "q13.11",
        "start": 102800001,
        "end": 106200000,
        "type": "gpos75"
      },
      {
        "id": "q13.12",
        "start": 106200001,
        "end": 107900000,
        "type": "gneg"
      },
      {
        "id": "q13.13",
        "start": 107900001,
        "end": 111300000,
        "type": "gpos50"
      },
      {
        "id": "q13.2",
        "start": 111300001,
        "end": 113500000,
        "type": "gneg"
      },
      {
        "id": "q13.31",
        "start": 113500001,
        "end": 117300000,
        "type": "gpos75"
      },
      {
        "id": "q13.32",
        "start": 117300001,
        "end": 119000000,
        "type": "gneg"
      },
      {
        "id": "q13.33",
        "start": 119000001,
        "end": 121900000,
        "type": "gpos75"
      },
      {
        "id": "q21.1",
        "start": 121900001,
        "end": 123800000,
        "type": "gneg"
      },
      {
        "id": "q21.2",
        "start": 123800001,
        "end": 125800000,
        "type": "gpos25"
      },
      {
        "id": "q21.3",
        "start": 125800001,
        "end": 129200000,
        "type": "gneg"
      },
      {
        "id": "q22.1",
        "start": 129200001,
        "end": 133700000,
        "type": "gpos25"
      },
      {
        "id": "q22.2",
        "start": 133700001,
        "end": 135700000,
        "type": "gneg"
      },
      {
        "id": "q22.3",
        "start": 135700001,
        "end": 138700000,
        "type": "gpos25"
      },
      {
        "id": "q23",
        "start": 138700001,
        "end": 142800000,
        "type": "gneg"
      },
      {
        "id": "q24",
        "start": 142800001,
        "end": 148900000,
        "type": "gpos100"
      },
      {
        "id": "q25.1",
        "start": 148900001,
        "end": 152100000,
        "type": "gneg"
      },
      {
        "id": "q25.2",
        "start": 152100001,
        "end": 155000000,
        "type": "gpos50"
      },
      {
        "id": "q25.31",
        "start": 155000001,
        "end": 157000000,
        "type": "gneg"
      },
      {
        "id": "q25.32",
        "start": 157000001,
        "end": 159000000,
        "type": "gpos50"
      },
      {
        "id": "q25.33",
        "start": 159000001,
        "end": 160700000,
        "type": "gneg"
      },
      {
        "id": "q26.1",
        "start": 160700001,
        "end": 167600000,
        "type": "gpos100"
      },
      {
        "id": "q26.2",
        "start": 167600001,
        "end": 170900000,
        "type": "gneg"
      },
      {
        "id": "q26.31",
        "start": 170900001,
        "end": 175700000,
        "type": "gpos75"
      },
      {
        "id": "q26.32",
        "start": 175700001,
        "end": 179000000,
        "type": "gneg"
      },
      {
        "id": "q26.33",
        "start": 179000001,
        "end": 182700000,
        "type": "gpos75"
      },
      {
        "id": "q27.1",
        "start": 182700001,
        "end": 184500000,
        "type": "gneg"
      },
      {
        "id": "q27.2",
        "start": 184500001,
        "end": 186000000,
        "type": "gpos25"
      },
      {
        "id": "q27.3",
        "start": 186000001,
        "end": 187900000,
        "type": "gneg"
      },
      {
        "id": "q28",
        "start": 187900001,
        "end": 192300000,
        "type": "gpos75"
      },
      {
        "id": "q29",
        "start": 192300001,
        "end": 198022430,
        "type": "gneg"
      }
    ]
  },
  "4": {
    "size": 191154276,
    "bands": [
      {
        "id": "p11",
        "start": 48200001,
        "end": 50400000,
        "type": "acen"
      },
      {
        "id": "p12",
        "start": 44600001,
        "end": 48200000,
        "type": "gneg"
      },
      {
        "id": "p13",
        "start": 41200001,
        "end": 44600000,
        "type": "gpos50"
      },
      {
        "id": "p14",
        "start": 35800001,
        "end": 41200000,
        "type": "gneg"
      },
      {
        "id": "p15.1",
        "start": 27700001,
        "end": 35800000,
        "type": "gpos100"
      },
      {
        "id": "p15.2",
        "start": 21300001,
        "end": 27700000,
        "type": "gneg"
      },
      {
        "id": "p15.31",
        "start": 17800001,
        "end": 21300000,
        "type": "gpos75"
      },
      {
        "id": "p15.32",
        "start": 15200001,
        "end": 17800000,
        "type": "gneg"
      },
      {
        "id": "p15.33",
        "start": 11300001,
        "end": 15200000,
        "type": "gpos50"
      },
      {
        "id": "p16.1",
        "start": 6000001,
        "end": 11300000,
        "type": "gneg"
      },
      {
        "id": "p16.2",
        "start": 4500001,
        "end": 6000000,
        "type": "gpos25"
      },
      {
        "id": "p16.3",
        "start": 1,
        "end": 4500000,
        "type": "gneg"
      },
      {
        "id": "q11",
        "start": 50400001,
        "end": 52700000,
        "type": "acen"
      },
      {
        "id": "q12",
        "start": 52700001,
        "end": 59500000,
        "type": "gneg"
      },
      {
        "id": "q13.1",
        "start": 59500001,
        "end": 66600000,
        "type": "gpos100"
      },
      {
        "id": "q13.2",
        "start": 66600001,
        "end": 70500000,
        "type": "gneg"
      },
      {
        "id": "q13.3",
        "start": 70500001,
        "end": 76300000,
        "type": "gpos75"
      },
      {
        "id": "q21.1",
        "start": 76300001,
        "end": 78900000,
        "type": "gneg"
      },
      {
        "id": "q21.21",
        "start": 78900001,
        "end": 82400000,
        "type": "gpos50"
      },
      {
        "id": "q21.22",
        "start": 82400001,
        "end": 84100000,
        "type": "gneg"
      },
      {
        "id": "q21.23",
        "start": 84100001,
        "end": 86900000,
        "type": "gpos25"
      },
      {
        "id": "q21.3",
        "start": 86900001,
        "end": 88000000,
        "type": "gneg"
      },
      {
        "id": "q22.1",
        "start": 88000001,
        "end": 93700000,
        "type": "gpos75"
      },
      {
        "id": "q22.2",
        "start": 93700001,
        "end": 95100000,
        "type": "gneg"
      },
      {
        "id": "q22.3",
        "start": 95100001,
        "end": 98800000,
        "type": "gpos75"
      },
      {
        "id": "q23",
        "start": 98800001,
        "end": 101100000,
        "type": "gneg"
      },
      {
        "id": "q24",
        "start": 101100001,
        "end": 107700000,
        "type": "gpos50"
      },
      {
        "id": "q25",
        "start": 107700001,
        "end": 114100000,
        "type": "gneg"
      },
      {
        "id": "q26",
        "start": 114100001,
        "end": 120800000,
        "type": "gpos75"
      },
      {
        "id": "q27",
        "start": 120800001,
        "end": 123800000,
        "type": "gneg"
      },
      {
        "id": "q28.1",
        "start": 123800001,
        "end": 128800000,
        "type": "gpos50"
      },
      {
        "id": "q28.2",
        "start": 128800001,
        "end": 131100000,
        "type": "gneg"
      },
      {
        "id": "q28.3",
        "start": 131100001,
        "end": 139500000,
        "type": "gpos100"
      },
      {
        "id": "q31.1",
        "start": 139500001,
        "end": 141500000,
        "type": "gneg"
      },
      {
        "id": "q31.21",
        "start": 141500001,
        "end": 146800000,
        "type": "gpos25"
      },
      {
        "id": "q31.22",
        "start": 146800001,
        "end": 148500000,
        "type": "gneg"
      },
      {
        "id": "q31.23",
        "start": 148500001,
        "end": 151100000,
        "type": "gpos25"
      },
      {
        "id": "q31.3",
        "start": 151100001,
        "end": 155600000,
        "type": "gneg"
      },
      {
        "id": "q32.1",
        "start": 155600001,
        "end": 161800000,
        "type": "gpos100"
      },
      {
        "id": "q32.2",
        "start": 161800001,
        "end": 164500000,
        "type": "gneg"
      },
      {
        "id": "q32.3",
        "start": 164500001,
        "end": 170100000,
        "type": "gpos100"
      },
      {
        "id": "q33",
        "start": 170100001,
        "end": 171900000,
        "type": "gneg"
      },
      {
        "id": "q34.1",
        "start": 171900001,
        "end": 176300000,
        "type": "gpos75"
      },
      {
        "id": "q34.2",
        "start": 176300001,
        "end": 177500000,
        "type": "gneg"
      },
      {
        "id": "q34.3",
        "start": 177500001,
        "end": 183200000,
        "type": "gpos100"
      },
      {
        "id": "q35.1",
        "start": 183200001,
        "end": 187100000,
        "type": "gneg"
      },
      {
        "id": "q35.2",
        "start": 187100001,
        "end": 191154276,
        "type": "gpos25"
      }
    ]
  },
  "5": {
    "size": 180915260,
    "bands": [
      {
        "id": "p11",
        "start": 46100001,
        "end": 48400000,
        "type": "acen"
      },
      {
        "id": "p12",
        "start": 42500001,
        "end": 46100000,
        "type": "gpos50"
      },
      {
        "id": "p13.1",
        "start": 38400001,
        "end": 42500000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 33800001,
        "end": 38400000,
        "type": "gpos25"
      },
      {
        "id": "p13.3",
        "start": 28900001,
        "end": 33800000,
        "type": "gneg"
      },
      {
        "id": "p14.1",
        "start": 24600001,
        "end": 28900000,
        "type": "gpos100"
      },
      {
        "id": "p14.2",
        "start": 23300001,
        "end": 24600000,
        "type": "gneg"
      },
      {
        "id": "p14.3",
        "start": 18400001,
        "end": 23300000,
        "type": "gpos100"
      },
      {
        "id": "p15.1",
        "start": 15000001,
        "end": 18400000,
        "type": "gneg"
      },
      {
        "id": "p15.2",
        "start": 9800001,
        "end": 15000000,
        "type": "gpos50"
      },
      {
        "id": "p15.31",
        "start": 6300001,
        "end": 9800000,
        "type": "gneg"
      },
      {
        "id": "p15.32",
        "start": 4500001,
        "end": 6300000,
        "type": "gpos25"
      },
      {
        "id": "p15.33",
        "start": 1,
        "end": 4500000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 48400001,
        "end": 50700000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 50700001,
        "end": 58900000,
        "type": "gneg"
      },
      {
        "id": "q12.1",
        "start": 58900001,
        "end": 62900000,
        "type": "gpos75"
      },
      {
        "id": "q12.2",
        "start": 62900001,
        "end": 63200000,
        "type": "gneg"
      },
      {
        "id": "q12.3",
        "start": 63200001,
        "end": 66700000,
        "type": "gpos75"
      },
      {
        "id": "q13.1",
        "start": 66700001,
        "end": 68400000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 68400001,
        "end": 73300000,
        "type": "gpos50"
      },
      {
        "id": "q13.3",
        "start": 73300001,
        "end": 76900000,
        "type": "gneg"
      },
      {
        "id": "q14.1",
        "start": 76900001,
        "end": 81400000,
        "type": "gpos50"
      },
      {
        "id": "q14.2",
        "start": 81400001,
        "end": 82800000,
        "type": "gneg"
      },
      {
        "id": "q14.3",
        "start": 82800001,
        "end": 92300000,
        "type": "gpos100"
      },
      {
        "id": "q15",
        "start": 92300001,
        "end": 98200000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 98200001,
        "end": 102800000,
        "type": "gpos100"
      },
      {
        "id": "q21.2",
        "start": 102800001,
        "end": 104500000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 104500001,
        "end": 109600000,
        "type": "gpos100"
      },
      {
        "id": "q22.1",
        "start": 109600001,
        "end": 111500000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 111500001,
        "end": 113100000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 113100001,
        "end": 115200000,
        "type": "gneg"
      },
      {
        "id": "q23.1",
        "start": 115200001,
        "end": 121400000,
        "type": "gpos100"
      },
      {
        "id": "q23.2",
        "start": 121400001,
        "end": 127300000,
        "type": "gneg"
      },
      {
        "id": "q23.3",
        "start": 127300001,
        "end": 130600000,
        "type": "gpos100"
      },
      {
        "id": "q31.1",
        "start": 130600001,
        "end": 136200000,
        "type": "gneg"
      },
      {
        "id": "q31.2",
        "start": 136200001,
        "end": 139500000,
        "type": "gpos25"
      },
      {
        "id": "q31.3",
        "start": 139500001,
        "end": 144500000,
        "type": "gneg"
      },
      {
        "id": "q32",
        "start": 144500001,
        "end": 149800000,
        "type": "gpos75"
      },
      {
        "id": "q33.1",
        "start": 149800001,
        "end": 152700000,
        "type": "gneg"
      },
      {
        "id": "q33.2",
        "start": 152700001,
        "end": 155700000,
        "type": "gpos50"
      },
      {
        "id": "q33.3",
        "start": 155700001,
        "end": 159900000,
        "type": "gneg"
      },
      {
        "id": "q34",
        "start": 159900001,
        "end": 168500000,
        "type": "gpos100"
      },
      {
        "id": "q35.1",
        "start": 168500001,
        "end": 172800000,
        "type": "gneg"
      },
      {
        "id": "q35.2",
        "start": 172800001,
        "end": 176600000,
        "type": "gpos25"
      },
      {
        "id": "q35.3",
        "start": 176600001,
        "end": 180915260,
        "type": "gneg"
      }
    ]
  },
  "6": {
    "size": 171115067,
    "bands": [
      {
        "id": "p11.1",
        "start": 58700001,
        "end": 61000000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 57000001,
        "end": 58700000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 52900001,
        "end": 57000000,
        "type": "gpos100"
      },
      {
        "id": "p12.2",
        "start": 51800001,
        "end": 52900000,
        "type": "gneg"
      },
      {
        "id": "p12.3",
        "start": 46200001,
        "end": 51800000,
        "type": "gpos100"
      },
      {
        "id": "p21.1",
        "start": 40500001,
        "end": 46200000,
        "type": "gneg"
      },
      {
        "id": "p21.2",
        "start": 36600001,
        "end": 40500000,
        "type": "gpos25"
      },
      {
        "id": "p21.31",
        "start": 33500001,
        "end": 36600000,
        "type": "gneg"
      },
      {
        "id": "p21.32",
        "start": 32100001,
        "end": 33500000,
        "type": "gpos25"
      },
      {
        "id": "p21.33",
        "start": 30400001,
        "end": 32100000,
        "type": "gneg"
      },
      {
        "id": "p22.1",
        "start": 27000001,
        "end": 30400000,
        "type": "gpos50"
      },
      {
        "id": "p22.2",
        "start": 25200001,
        "end": 27000000,
        "type": "gneg"
      },
      {
        "id": "p22.3",
        "start": 15200001,
        "end": 25200000,
        "type": "gpos75"
      },
      {
        "id": "p23",
        "start": 13400001,
        "end": 15200000,
        "type": "gneg"
      },
      {
        "id": "p24.1",
        "start": 11600001,
        "end": 13400000,
        "type": "gpos25"
      },
      {
        "id": "p24.2",
        "start": 10600001,
        "end": 11600000,
        "type": "gneg"
      },
      {
        "id": "p24.3",
        "start": 7100001,
        "end": 10600000,
        "type": "gpos50"
      },
      {
        "id": "p25.1",
        "start": 4200001,
        "end": 7100000,
        "type": "gneg"
      },
      {
        "id": "p25.2",
        "start": 2300001,
        "end": 4200000,
        "type": "gpos25"
      },
      {
        "id": "p25.3",
        "start": 1,
        "end": 2300000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 61000001,
        "end": 63300000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 63300001,
        "end": 63400000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 63400001,
        "end": 70000000,
        "type": "gpos100"
      },
      {
        "id": "q13",
        "start": 70000001,
        "end": 75900000,
        "type": "gneg"
      },
      {
        "id": "q14.1",
        "start": 75900001,
        "end": 83900000,
        "type": "gpos50"
      },
      {
        "id": "q14.2",
        "start": 83900001,
        "end": 84900000,
        "type": "gneg"
      },
      {
        "id": "q14.3",
        "start": 84900001,
        "end": 88000000,
        "type": "gpos50"
      },
      {
        "id": "q15",
        "start": 88000001,
        "end": 93100000,
        "type": "gneg"
      },
      {
        "id": "q16.1",
        "start": 93100001,
        "end": 99500000,
        "type": "gpos100"
      },
      {
        "id": "q16.2",
        "start": 99500001,
        "end": 100600000,
        "type": "gneg"
      },
      {
        "id": "q16.3",
        "start": 100600001,
        "end": 105500000,
        "type": "gpos100"
      },
      {
        "id": "q21",
        "start": 105500001,
        "end": 114600000,
        "type": "gneg"
      },
      {
        "id": "q22.1",
        "start": 114600001,
        "end": 118300000,
        "type": "gpos75"
      },
      {
        "id": "q22.2",
        "start": 118300001,
        "end": 118500000,
        "type": "gneg"
      },
      {
        "id": "q22.31",
        "start": 118500001,
        "end": 126100000,
        "type": "gpos100"
      },
      {
        "id": "q22.32",
        "start": 126100001,
        "end": 127100000,
        "type": "gneg"
      },
      {
        "id": "q22.33",
        "start": 127100001,
        "end": 130300000,
        "type": "gpos75"
      },
      {
        "id": "q23.1",
        "start": 130300001,
        "end": 131200000,
        "type": "gneg"
      },
      {
        "id": "q23.2",
        "start": 131200001,
        "end": 135200000,
        "type": "gpos50"
      },
      {
        "id": "q23.3",
        "start": 135200001,
        "end": 139000000,
        "type": "gneg"
      },
      {
        "id": "q24.1",
        "start": 139000001,
        "end": 142800000,
        "type": "gpos75"
      },
      {
        "id": "q24.2",
        "start": 142800001,
        "end": 145600000,
        "type": "gneg"
      },
      {
        "id": "q24.3",
        "start": 145600001,
        "end": 149000000,
        "type": "gpos75"
      },
      {
        "id": "q25.1",
        "start": 149000001,
        "end": 152500000,
        "type": "gneg"
      },
      {
        "id": "q25.2",
        "start": 152500001,
        "end": 155500000,
        "type": "gpos50"
      },
      {
        "id": "q25.3",
        "start": 155500001,
        "end": 161000000,
        "type": "gneg"
      },
      {
        "id": "q26",
        "start": 161000001,
        "end": 164500000,
        "type": "gpos50"
      },
      {
        "id": "q27",
        "start": 164500001,
        "end": 171115067,
        "type": "gneg"
      }
    ]
  },
  "7": {
    "size": 159138663,
    "bands": [
      {
        "id": "p11.1",
        "start": 58000001,
        "end": 59900000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 54000001,
        "end": 58000000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 50500001,
        "end": 54000000,
        "type": "gpos75"
      },
      {
        "id": "p12.2",
        "start": 49000001,
        "end": 50500000,
        "type": "gneg"
      },
      {
        "id": "p12.3",
        "start": 45400001,
        "end": 49000000,
        "type": "gpos75"
      },
      {
        "id": "p13",
        "start": 43300001,
        "end": 45400000,
        "type": "gneg"
      },
      {
        "id": "p14.1",
        "start": 37200001,
        "end": 43300000,
        "type": "gpos75"
      },
      {
        "id": "p14.2",
        "start": 35000001,
        "end": 37200000,
        "type": "gneg"
      },
      {
        "id": "p14.3",
        "start": 28800001,
        "end": 35000000,
        "type": "gpos75"
      },
      {
        "id": "p15.1",
        "start": 28000001,
        "end": 28800000,
        "type": "gneg"
      },
      {
        "id": "p15.2",
        "start": 25500001,
        "end": 28000000,
        "type": "gpos50"
      },
      {
        "id": "p15.3",
        "start": 20900001,
        "end": 25500000,
        "type": "gneg"
      },
      {
        "id": "p21.1",
        "start": 16500001,
        "end": 20900000,
        "type": "gpos100"
      },
      {
        "id": "p21.2",
        "start": 13800001,
        "end": 16500000,
        "type": "gneg"
      },
      {
        "id": "p21.3",
        "start": 7300001,
        "end": 13800000,
        "type": "gpos100"
      },
      {
        "id": "p22.1",
        "start": 4500001,
        "end": 7300000,
        "type": "gneg"
      },
      {
        "id": "p22.2",
        "start": 2800001,
        "end": 4500000,
        "type": "gpos25"
      },
      {
        "id": "p22.3",
        "start": 1,
        "end": 2800000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 59900001,
        "end": 61700000,
        "type": "acen"
      },
      {
        "id": "q11.21",
        "start": 61700001,
        "end": 67000000,
        "type": "gneg"
      },
      {
        "id": "q11.22",
        "start": 67000001,
        "end": 72200000,
        "type": "gpos50"
      },
      {
        "id": "q11.23",
        "start": 72200001,
        "end": 77500000,
        "type": "gneg"
      },
      {
        "id": "q21.11",
        "start": 77500001,
        "end": 86400000,
        "type": "gpos100"
      },
      {
        "id": "q21.12",
        "start": 86400001,
        "end": 88200000,
        "type": "gneg"
      },
      {
        "id": "q21.13",
        "start": 88200001,
        "end": 91100000,
        "type": "gpos75"
      },
      {
        "id": "q21.2",
        "start": 91100001,
        "end": 92800000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 92800001,
        "end": 98000000,
        "type": "gpos75"
      },
      {
        "id": "q22.1",
        "start": 98000001,
        "end": 103800000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 103800001,
        "end": 104500000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 104500001,
        "end": 107400000,
        "type": "gneg"
      },
      {
        "id": "q31.1",
        "start": 107400001,
        "end": 114600000,
        "type": "gpos75"
      },
      {
        "id": "q31.2",
        "start": 114600001,
        "end": 117400000,
        "type": "gneg"
      },
      {
        "id": "q31.31",
        "start": 117400001,
        "end": 121100000,
        "type": "gpos75"
      },
      {
        "id": "q31.32",
        "start": 121100001,
        "end": 123800000,
        "type": "gneg"
      },
      {
        "id": "q31.33",
        "start": 123800001,
        "end": 127100000,
        "type": "gpos75"
      },
      {
        "id": "q32.1",
        "start": 127100001,
        "end": 129200000,
        "type": "gneg"
      },
      {
        "id": "q32.2",
        "start": 129200001,
        "end": 130400000,
        "type": "gpos25"
      },
      {
        "id": "q32.3",
        "start": 130400001,
        "end": 132600000,
        "type": "gneg"
      },
      {
        "id": "q33",
        "start": 132600001,
        "end": 138200000,
        "type": "gpos50"
      },
      {
        "id": "q34",
        "start": 138200001,
        "end": 143100000,
        "type": "gneg"
      },
      {
        "id": "q35",
        "start": 143100001,
        "end": 147900000,
        "type": "gpos75"
      },
      {
        "id": "q36.1",
        "start": 147900001,
        "end": 152600000,
        "type": "gneg"
      },
      {
        "id": "q36.2",
        "start": 152600001,
        "end": 155100000,
        "type": "gpos25"
      },
      {
        "id": "q36.3",
        "start": 155100001,
        "end": 159138663,
        "type": "gneg"
      }
    ]
  },
  "8": {
    "size": 146364022,
    "bands": [
      {
        "id": "p11.1",
        "start": 43100001,
        "end": 45600000,
        "type": "acen"
      },
      {
        "id": "p11.21",
        "start": 39700001,
        "end": 43100000,
        "type": "gneg"
      },
      {
        "id": "p11.22",
        "start": 38300001,
        "end": 39700000,
        "type": "gpos25"
      },
      {
        "id": "p11.23",
        "start": 36500001,
        "end": 38300000,
        "type": "gneg"
      },
      {
        "id": "p12",
        "start": 28800001,
        "end": 36500000,
        "type": "gpos75"
      },
      {
        "id": "p21.1",
        "start": 27400001,
        "end": 28800000,
        "type": "gneg"
      },
      {
        "id": "p21.2",
        "start": 23300001,
        "end": 27400000,
        "type": "gpos50"
      },
      {
        "id": "p21.3",
        "start": 19000001,
        "end": 23300000,
        "type": "gneg"
      },
      {
        "id": "p22",
        "start": 12700001,
        "end": 19000000,
        "type": "gpos100"
      },
      {
        "id": "p23.1",
        "start": 6200001,
        "end": 12700000,
        "type": "gneg"
      },
      {
        "id": "p23.2",
        "start": 2200001,
        "end": 6200000,
        "type": "gpos75"
      },
      {
        "id": "p23.3",
        "start": 1,
        "end": 2200000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 45600001,
        "end": 48100000,
        "type": "acen"
      },
      {
        "id": "q11.21",
        "start": 48100001,
        "end": 52200000,
        "type": "gneg"
      },
      {
        "id": "q11.22",
        "start": 52200001,
        "end": 52600000,
        "type": "gpos75"
      },
      {
        "id": "q11.23",
        "start": 52600001,
        "end": 55500000,
        "type": "gneg"
      },
      {
        "id": "q12.1",
        "start": 55500001,
        "end": 61600000,
        "type": "gpos50"
      },
      {
        "id": "q12.2",
        "start": 61600001,
        "end": 62200000,
        "type": "gneg"
      },
      {
        "id": "q12.3",
        "start": 62200001,
        "end": 66000000,
        "type": "gpos50"
      },
      {
        "id": "q13.1",
        "start": 66000001,
        "end": 68000000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 68000001,
        "end": 70500000,
        "type": "gpos50"
      },
      {
        "id": "q13.3",
        "start": 70500001,
        "end": 73900000,
        "type": "gneg"
      },
      {
        "id": "q21.11",
        "start": 73900001,
        "end": 78300000,
        "type": "gpos100"
      },
      {
        "id": "q21.12",
        "start": 78300001,
        "end": 80100000,
        "type": "gneg"
      },
      {
        "id": "q21.13",
        "start": 80100001,
        "end": 84600000,
        "type": "gpos75"
      },
      {
        "id": "q21.2",
        "start": 84600001,
        "end": 86900000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 86900001,
        "end": 93300000,
        "type": "gpos100"
      },
      {
        "id": "q22.1",
        "start": 93300001,
        "end": 99000000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 99000001,
        "end": 101600000,
        "type": "gpos25"
      },
      {
        "id": "q22.3",
        "start": 101600001,
        "end": 106200000,
        "type": "gneg"
      },
      {
        "id": "q23.1",
        "start": 106200001,
        "end": 110500000,
        "type": "gpos75"
      },
      {
        "id": "q23.2",
        "start": 110500001,
        "end": 112100000,
        "type": "gneg"
      },
      {
        "id": "q23.3",
        "start": 112100001,
        "end": 117700000,
        "type": "gpos100"
      },
      {
        "id": "q24.11",
        "start": 117700001,
        "end": 119200000,
        "type": "gneg"
      },
      {
        "id": "q24.12",
        "start": 119200001,
        "end": 122500000,
        "type": "gpos50"
      },
      {
        "id": "q24.13",
        "start": 122500001,
        "end": 127300000,
        "type": "gneg"
      },
      {
        "id": "q24.21",
        "start": 127300001,
        "end": 131500000,
        "type": "gpos50"
      },
      {
        "id": "q24.22",
        "start": 131500001,
        "end": 136400000,
        "type": "gneg"
      },
      {
        "id": "q24.23",
        "start": 136400001,
        "end": 139900000,
        "type": "gpos75"
      },
      {
        "id": "q24.3",
        "start": 139900001,
        "end": 146364022,
        "type": "gneg"
      }
    ]
  },
  "9": {
    "size": 141213431,
    "bands": [
      {
        "id": "p11.1",
        "start": 47300001,
        "end": 49000000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 43600001,
        "end": 47300000,
        "type": "gneg"
      },
      {
        "id": "p12",
        "start": 41000001,
        "end": 43600000,
        "type": "gpos50"
      },
      {
        "id": "p13.1",
        "start": 38400001,
        "end": 41000000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 36300001,
        "end": 38400000,
        "type": "gpos25"
      },
      {
        "id": "p13.3",
        "start": 33200001,
        "end": 36300000,
        "type": "gneg"
      },
      {
        "id": "p21.1",
        "start": 28000001,
        "end": 33200000,
        "type": "gpos100"
      },
      {
        "id": "p21.2",
        "start": 25600001,
        "end": 28000000,
        "type": "gneg"
      },
      {
        "id": "p21.3",
        "start": 19900001,
        "end": 25600000,
        "type": "gpos100"
      },
      {
        "id": "p22.1",
        "start": 18500001,
        "end": 19900000,
        "type": "gneg"
      },
      {
        "id": "p22.2",
        "start": 16600001,
        "end": 18500000,
        "type": "gpos25"
      },
      {
        "id": "p22.3",
        "start": 14200001,
        "end": 16600000,
        "type": "gneg"
      },
      {
        "id": "p23",
        "start": 9000001,
        "end": 14200000,
        "type": "gpos75"
      },
      {
        "id": "p24.1",
        "start": 4600001,
        "end": 9000000,
        "type": "gneg"
      },
      {
        "id": "p24.2",
        "start": 2200001,
        "end": 4600000,
        "type": "gpos25"
      },
      {
        "id": "p24.3",
        "start": 1,
        "end": 2200000,
        "type": "gneg"
      },
      {
        "id": "q11",
        "start": 49000001,
        "end": 50700000,
        "type": "acen"
      },
      {
        "id": "q12",
        "start": 50700001,
        "end": 65900000,
        "type": "gvar"
      },
      {
        "id": "q13",
        "start": 65900001,
        "end": 68700000,
        "type": "gneg"
      },
      {
        "id": "q21.11",
        "start": 68700001,
        "end": 72200000,
        "type": "gpos25"
      },
      {
        "id": "q21.12",
        "start": 72200001,
        "end": 74000000,
        "type": "gneg"
      },
      {
        "id": "q21.13",
        "start": 74000001,
        "end": 79200000,
        "type": "gpos50"
      },
      {
        "id": "q21.2",
        "start": 79200001,
        "end": 81100000,
        "type": "gneg"
      },
      {
        "id": "q21.31",
        "start": 81100001,
        "end": 84100000,
        "type": "gpos50"
      },
      {
        "id": "q21.32",
        "start": 84100001,
        "end": 86900000,
        "type": "gneg"
      },
      {
        "id": "q21.33",
        "start": 86900001,
        "end": 90400000,
        "type": "gpos50"
      },
      {
        "id": "q22.1",
        "start": 90400001,
        "end": 91800000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 91800001,
        "end": 93900000,
        "type": "gpos25"
      },
      {
        "id": "q22.31",
        "start": 93900001,
        "end": 96600000,
        "type": "gneg"
      },
      {
        "id": "q22.32",
        "start": 96600001,
        "end": 99300000,
        "type": "gpos25"
      },
      {
        "id": "q22.33",
        "start": 99300001,
        "end": 102600000,
        "type": "gneg"
      },
      {
        "id": "q31.1",
        "start": 102600001,
        "end": 108200000,
        "type": "gpos100"
      },
      {
        "id": "q31.2",
        "start": 108200001,
        "end": 111300000,
        "type": "gneg"
      },
      {
        "id": "q31.3",
        "start": 111300001,
        "end": 114900000,
        "type": "gpos25"
      },
      {
        "id": "q32",
        "start": 114900001,
        "end": 117700000,
        "type": "gneg"
      },
      {
        "id": "q33.1",
        "start": 117700001,
        "end": 122500000,
        "type": "gpos75"
      },
      {
        "id": "q33.2",
        "start": 122500001,
        "end": 125800000,
        "type": "gneg"
      },
      {
        "id": "q33.3",
        "start": 125800001,
        "end": 130300000,
        "type": "gpos25"
      },
      {
        "id": "q34.11",
        "start": 130300001,
        "end": 133500000,
        "type": "gneg"
      },
      {
        "id": "q34.12",
        "start": 133500001,
        "end": 134000000,
        "type": "gpos25"
      },
      {
        "id": "q34.13",
        "start": 134000001,
        "end": 135900000,
        "type": "gneg"
      },
      {
        "id": "q34.2",
        "start": 135900001,
        "end": 137400000,
        "type": "gpos25"
      },
      {
        "id": "q34.3",
        "start": 137400001,
        "end": 141213431,
        "type": "gneg"
      }
    ]
  },
  "10": {
    "size": 135534747,
    "bands": [
      {
        "id": "p11.1",
        "start": 38000001,
        "end": 40200000,
        "type": "acen"
      },
      {
        "id": "p11.21",
        "start": 34400001,
        "end": 38000000,
        "type": "gneg"
      },
      {
        "id": "p11.22",
        "start": 31300001,
        "end": 34400000,
        "type": "gpos25"
      },
      {
        "id": "p11.23",
        "start": 29600001,
        "end": 31300000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 24600001,
        "end": 29600000,
        "type": "gpos50"
      },
      {
        "id": "p12.2",
        "start": 22600001,
        "end": 24600000,
        "type": "gneg"
      },
      {
        "id": "p12.31",
        "start": 18700001,
        "end": 22600000,
        "type": "gpos75"
      },
      {
        "id": "p12.32",
        "start": 18600001,
        "end": 18700000,
        "type": "gneg"
      },
      {
        "id": "p12.33",
        "start": 17300001,
        "end": 18600000,
        "type": "gpos75"
      },
      {
        "id": "p13",
        "start": 12200001,
        "end": 17300000,
        "type": "gneg"
      },
      {
        "id": "p14",
        "start": 6600001,
        "end": 12200000,
        "type": "gpos75"
      },
      {
        "id": "p15.1",
        "start": 3800001,
        "end": 6600000,
        "type": "gneg"
      },
      {
        "id": "p15.2",
        "start": 3000001,
        "end": 3800000,
        "type": "gpos25"
      },
      {
        "id": "p15.3",
        "start": 1,
        "end": 3000000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 40200001,
        "end": 42300000,
        "type": "acen"
      },
      {
        "id": "q11.21",
        "start": 42300001,
        "end": 46100000,
        "type": "gneg"
      },
      {
        "id": "q11.22",
        "start": 46100001,
        "end": 49900000,
        "type": "gpos25"
      },
      {
        "id": "q11.23",
        "start": 49900001,
        "end": 52900000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 52900001,
        "end": 61200000,
        "type": "gpos100"
      },
      {
        "id": "q21.2",
        "start": 61200001,
        "end": 64500000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 64500001,
        "end": 70600000,
        "type": "gpos100"
      },
      {
        "id": "q22.1",
        "start": 70600001,
        "end": 74900000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 74900001,
        "end": 77700000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 77700001,
        "end": 82000000,
        "type": "gneg"
      },
      {
        "id": "q23.1",
        "start": 82000001,
        "end": 87900000,
        "type": "gpos100"
      },
      {
        "id": "q23.2",
        "start": 87900001,
        "end": 89500000,
        "type": "gneg"
      },
      {
        "id": "q23.31",
        "start": 89500001,
        "end": 92900000,
        "type": "gpos75"
      },
      {
        "id": "q23.32",
        "start": 92900001,
        "end": 94100000,
        "type": "gneg"
      },
      {
        "id": "q23.33",
        "start": 94100001,
        "end": 97000000,
        "type": "gpos50"
      },
      {
        "id": "q24.1",
        "start": 97000001,
        "end": 99300000,
        "type": "gneg"
      },
      {
        "id": "q24.2",
        "start": 99300001,
        "end": 101900000,
        "type": "gpos50"
      },
      {
        "id": "q24.31",
        "start": 101900001,
        "end": 103000000,
        "type": "gneg"
      },
      {
        "id": "q24.32",
        "start": 103000001,
        "end": 104900000,
        "type": "gpos25"
      },
      {
        "id": "q24.33",
        "start": 104900001,
        "end": 105800000,
        "type": "gneg"
      },
      {
        "id": "q25.1",
        "start": 105800001,
        "end": 111900000,
        "type": "gpos100"
      },
      {
        "id": "q25.2",
        "start": 111900001,
        "end": 114900000,
        "type": "gneg"
      },
      {
        "id": "q25.3",
        "start": 114900001,
        "end": 119100000,
        "type": "gpos75"
      },
      {
        "id": "q26.11",
        "start": 119100001,
        "end": 121700000,
        "type": "gneg"
      },
      {
        "id": "q26.12",
        "start": 121700001,
        "end": 123100000,
        "type": "gpos50"
      },
      {
        "id": "q26.13",
        "start": 123100001,
        "end": 127500000,
        "type": "gneg"
      },
      {
        "id": "q26.2",
        "start": 127500001,
        "end": 130600000,
        "type": "gpos50"
      },
      {
        "id": "q26.3",
        "start": 130600001,
        "end": 135534747,
        "type": "gneg"
      }
    ]
  },
  "11": {
    "size": 135006516,
    "bands": [
      {
        "id": "p11.11",
        "start": 51600001,
        "end": 53700000,
        "type": "acen"
      },
      {
        "id": "p11.12",
        "start": 48800001,
        "end": 51600000,
        "type": "gpos75"
      },
      {
        "id": "p11.2",
        "start": 43500001,
        "end": 48800000,
        "type": "gneg"
      },
      {
        "id": "p12",
        "start": 36400001,
        "end": 43500000,
        "type": "gpos100"
      },
      {
        "id": "p13",
        "start": 31000001,
        "end": 36400000,
        "type": "gneg"
      },
      {
        "id": "p14.1",
        "start": 27200001,
        "end": 31000000,
        "type": "gpos75"
      },
      {
        "id": "p14.2",
        "start": 26100001,
        "end": 27200000,
        "type": "gneg"
      },
      {
        "id": "p14.3",
        "start": 21700001,
        "end": 26100000,
        "type": "gpos100"
      },
      {
        "id": "p15.1",
        "start": 16200001,
        "end": 21700000,
        "type": "gneg"
      },
      {
        "id": "p15.2",
        "start": 12700001,
        "end": 16200000,
        "type": "gpos50"
      },
      {
        "id": "p15.3",
        "start": 10700001,
        "end": 12700000,
        "type": "gneg"
      },
      {
        "id": "p15.4",
        "start": 2800001,
        "end": 10700000,
        "type": "gpos50"
      },
      {
        "id": "p15.5",
        "start": 1,
        "end": 2800000,
        "type": "gneg"
      },
      {
        "id": "q11",
        "start": 53700001,
        "end": 55700000,
        "type": "acen"
      },
      {
        "id": "q12.1",
        "start": 55700001,
        "end": 59900000,
        "type": "gpos75"
      },
      {
        "id": "q12.2",
        "start": 59900001,
        "end": 61700000,
        "type": "gneg"
      },
      {
        "id": "q12.3",
        "start": 61700001,
        "end": 63400000,
        "type": "gpos25"
      },
      {
        "id": "q13.1",
        "start": 63400001,
        "end": 65900000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 65900001,
        "end": 68400000,
        "type": "gpos25"
      },
      {
        "id": "q13.3",
        "start": 68400001,
        "end": 70400000,
        "type": "gneg"
      },
      {
        "id": "q13.4",
        "start": 70400001,
        "end": 75200000,
        "type": "gpos50"
      },
      {
        "id": "q13.5",
        "start": 75200001,
        "end": 77100000,
        "type": "gneg"
      },
      {
        "id": "q14.1",
        "start": 77100001,
        "end": 85600000,
        "type": "gpos100"
      },
      {
        "id": "q14.2",
        "start": 85600001,
        "end": 88300000,
        "type": "gneg"
      },
      {
        "id": "q14.3",
        "start": 88300001,
        "end": 92800000,
        "type": "gpos100"
      },
      {
        "id": "q21",
        "start": 92800001,
        "end": 97200000,
        "type": "gneg"
      },
      {
        "id": "q22.1",
        "start": 97200001,
        "end": 102100000,
        "type": "gpos100"
      },
      {
        "id": "q22.2",
        "start": 102100001,
        "end": 102900000,
        "type": "gneg"
      },
      {
        "id": "q22.3",
        "start": 102900001,
        "end": 110400000,
        "type": "gpos100"
      },
      {
        "id": "q23.1",
        "start": 110400001,
        "end": 112500000,
        "type": "gneg"
      },
      {
        "id": "q23.2",
        "start": 112500001,
        "end": 114500000,
        "type": "gpos50"
      },
      {
        "id": "q23.3",
        "start": 114500001,
        "end": 121200000,
        "type": "gneg"
      },
      {
        "id": "q24.1",
        "start": 121200001,
        "end": 123900000,
        "type": "gpos50"
      },
      {
        "id": "q24.2",
        "start": 123900001,
        "end": 127800000,
        "type": "gneg"
      },
      {
        "id": "q24.3",
        "start": 127800001,
        "end": 130800000,
        "type": "gpos50"
      },
      {
        "id": "q25",
        "start": 130800001,
        "end": 135006516,
        "type": "gneg"
      }
    ]
  },
  "12": {
    "size": 133851895,
    "bands": [
      {
        "id": "p11.1",
        "start": 33300001,
        "end": 35800000,
        "type": "acen"
      },
      {
        "id": "p11.21",
        "start": 30700001,
        "end": 33300000,
        "type": "gneg"
      },
      {
        "id": "p11.22",
        "start": 27800001,
        "end": 30700000,
        "type": "gpos50"
      },
      {
        "id": "p11.23",
        "start": 26500001,
        "end": 27800000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 21300001,
        "end": 26500000,
        "type": "gpos100"
      },
      {
        "id": "p12.2",
        "start": 20000001,
        "end": 21300000,
        "type": "gneg"
      },
      {
        "id": "p12.3",
        "start": 14800001,
        "end": 20000000,
        "type": "gpos100"
      },
      {
        "id": "p13.1",
        "start": 12800001,
        "end": 14800000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 10100001,
        "end": 12800000,
        "type": "gpos75"
      },
      {
        "id": "p13.31",
        "start": 5400001,
        "end": 10100000,
        "type": "gneg"
      },
      {
        "id": "p13.32",
        "start": 3300001,
        "end": 5400000,
        "type": "gpos25"
      },
      {
        "id": "p13.33",
        "start": 1,
        "end": 3300000,
        "type": "gneg"
      },
      {
        "id": "q11",
        "start": 35800001,
        "end": 38200000,
        "type": "acen"
      },
      {
        "id": "q12",
        "start": 38200001,
        "end": 46400000,
        "type": "gpos100"
      },
      {
        "id": "q13.11",
        "start": 46400001,
        "end": 49100000,
        "type": "gneg"
      },
      {
        "id": "q13.12",
        "start": 49100001,
        "end": 51500000,
        "type": "gpos25"
      },
      {
        "id": "q13.13",
        "start": 51500001,
        "end": 54900000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 54900001,
        "end": 56600000,
        "type": "gpos25"
      },
      {
        "id": "q13.3",
        "start": 56600001,
        "end": 58100000,
        "type": "gneg"
      },
      {
        "id": "q14.1",
        "start": 58100001,
        "end": 63100000,
        "type": "gpos75"
      },
      {
        "id": "q14.2",
        "start": 63100001,
        "end": 65100000,
        "type": "gneg"
      },
      {
        "id": "q14.3",
        "start": 65100001,
        "end": 67700000,
        "type": "gpos50"
      },
      {
        "id": "q15",
        "start": 67700001,
        "end": 71500000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 71500001,
        "end": 75700000,
        "type": "gpos75"
      },
      {
        "id": "q21.2",
        "start": 75700001,
        "end": 80300000,
        "type": "gneg"
      },
      {
        "id": "q21.31",
        "start": 80300001,
        "end": 86700000,
        "type": "gpos100"
      },
      {
        "id": "q21.32",
        "start": 86700001,
        "end": 89000000,
        "type": "gneg"
      },
      {
        "id": "q21.33",
        "start": 89000001,
        "end": 92600000,
        "type": "gpos100"
      },
      {
        "id": "q22",
        "start": 92600001,
        "end": 96200000,
        "type": "gneg"
      },
      {
        "id": "q23.1",
        "start": 96200001,
        "end": 101600000,
        "type": "gpos75"
      },
      {
        "id": "q23.2",
        "start": 101600001,
        "end": 103800000,
        "type": "gneg"
      },
      {
        "id": "q23.3",
        "start": 103800001,
        "end": 109000000,
        "type": "gpos50"
      },
      {
        "id": "q24.11",
        "start": 109000001,
        "end": 111700000,
        "type": "gneg"
      },
      {
        "id": "q24.12",
        "start": 111700001,
        "end": 112300000,
        "type": "gpos25"
      },
      {
        "id": "q24.13",
        "start": 112300001,
        "end": 114300000,
        "type": "gneg"
      },
      {
        "id": "q24.21",
        "start": 114300001,
        "end": 116800000,
        "type": "gpos50"
      },
      {
        "id": "q24.22",
        "start": 116800001,
        "end": 118100000,
        "type": "gneg"
      },
      {
        "id": "q24.23",
        "start": 118100001,
        "end": 120700000,
        "type": "gpos50"
      },
      {
        "id": "q24.31",
        "start": 120700001,
        "end": 125900000,
        "type": "gneg"
      },
      {
        "id": "q24.32",
        "start": 125900001,
        "end": 129300000,
        "type": "gpos50"
      },
      {
        "id": "q24.33",
        "start": 129300001,
        "end": 133851895,
        "type": "gneg"
      }
    ]
  },
  "13": {
    "size": 115169878,
    "bands": [
      {
        "id": "p11.1",
        "start": 16300001,
        "end": 17900000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 10000001,
        "end": 16300000,
        "type": "gvar"
      },
      {
        "id": "p12",
        "start": 4500001,
        "end": 10000000,
        "type": "stalk"
      },
      {
        "id": "p13",
        "start": 1,
        "end": 4500000,
        "type": "gvar"
      },
      {
        "id": "q11",
        "start": 17900001,
        "end": 19500000,
        "type": "acen"
      },
      {
        "id": "q12.11",
        "start": 19500001,
        "end": 23300000,
        "type": "gneg"
      },
      {
        "id": "q12.12",
        "start": 23300001,
        "end": 25500000,
        "type": "gpos25"
      },
      {
        "id": "q12.13",
        "start": 25500001,
        "end": 27800000,
        "type": "gneg"
      },
      {
        "id": "q12.2",
        "start": 27800001,
        "end": 28900000,
        "type": "gpos25"
      },
      {
        "id": "q12.3",
        "start": 28900001,
        "end": 32200000,
        "type": "gneg"
      },
      {
        "id": "q13.1",
        "start": 32200001,
        "end": 34000000,
        "type": "gpos50"
      },
      {
        "id": "q13.2",
        "start": 34000001,
        "end": 35500000,
        "type": "gneg"
      },
      {
        "id": "q13.3",
        "start": 35500001,
        "end": 40100000,
        "type": "gpos75"
      },
      {
        "id": "q14.11",
        "start": 40100001,
        "end": 45200000,
        "type": "gneg"
      },
      {
        "id": "q14.12",
        "start": 45200001,
        "end": 45800000,
        "type": "gpos25"
      },
      {
        "id": "q14.13",
        "start": 45800001,
        "end": 47300000,
        "type": "gneg"
      },
      {
        "id": "q14.2",
        "start": 47300001,
        "end": 50900000,
        "type": "gpos50"
      },
      {
        "id": "q14.3",
        "start": 50900001,
        "end": 55300000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 55300001,
        "end": 59600000,
        "type": "gpos100"
      },
      {
        "id": "q21.2",
        "start": 59600001,
        "end": 62300000,
        "type": "gneg"
      },
      {
        "id": "q21.31",
        "start": 62300001,
        "end": 65700000,
        "type": "gpos75"
      },
      {
        "id": "q21.32",
        "start": 65700001,
        "end": 68600000,
        "type": "gneg"
      },
      {
        "id": "q21.33",
        "start": 68600001,
        "end": 73300000,
        "type": "gpos100"
      },
      {
        "id": "q22.1",
        "start": 73300001,
        "end": 75400000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 75400001,
        "end": 77200000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 77200001,
        "end": 79000000,
        "type": "gneg"
      },
      {
        "id": "q31.1",
        "start": 79000001,
        "end": 87700000,
        "type": "gpos100"
      },
      {
        "id": "q31.2",
        "start": 87700001,
        "end": 90000000,
        "type": "gneg"
      },
      {
        "id": "q31.3",
        "start": 90000001,
        "end": 95000000,
        "type": "gpos100"
      },
      {
        "id": "q32.1",
        "start": 95000001,
        "end": 98200000,
        "type": "gneg"
      },
      {
        "id": "q32.2",
        "start": 98200001,
        "end": 99300000,
        "type": "gpos25"
      },
      {
        "id": "q32.3",
        "start": 99300001,
        "end": 101700000,
        "type": "gneg"
      },
      {
        "id": "q33.1",
        "start": 101700001,
        "end": 104800000,
        "type": "gpos100"
      },
      {
        "id": "q33.2",
        "start": 104800001,
        "end": 107000000,
        "type": "gneg"
      },
      {
        "id": "q33.3",
        "start": 107000001,
        "end": 110300000,
        "type": "gpos100"
      },
      {
        "id": "q34",
        "start": 110300001,
        "end": 115169878,
        "type": "gneg"
      }
    ]
  },
  "14": {
    "size": 107349540,
    "bands": [
      {
        "id": "p11.1",
        "start": 16100001,
        "end": 17600000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 8100001,
        "end": 16100000,
        "type": "gvar"
      },
      {
        "id": "p12",
        "start": 3700001,
        "end": 8100000,
        "type": "stalk"
      },
      {
        "id": "p13",
        "start": 1,
        "end": 3700000,
        "type": "gvar"
      },
      {
        "id": "q11.1",
        "start": 17600001,
        "end": 19100000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 19100001,
        "end": 24600000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 24600001,
        "end": 33300000,
        "type": "gpos100"
      },
      {
        "id": "q13.1",
        "start": 33300001,
        "end": 35300000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 35300001,
        "end": 36600000,
        "type": "gpos50"
      },
      {
        "id": "q13.3",
        "start": 36600001,
        "end": 37800000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 37800001,
        "end": 43500000,
        "type": "gpos100"
      },
      {
        "id": "q21.2",
        "start": 43500001,
        "end": 47200000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 47200001,
        "end": 50900000,
        "type": "gpos100"
      },
      {
        "id": "q22.1",
        "start": 50900001,
        "end": 54100000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 54100001,
        "end": 55500000,
        "type": "gpos25"
      },
      {
        "id": "q22.3",
        "start": 55500001,
        "end": 58100000,
        "type": "gneg"
      },
      {
        "id": "q23.1",
        "start": 58100001,
        "end": 62100000,
        "type": "gpos75"
      },
      {
        "id": "q23.2",
        "start": 62100001,
        "end": 64800000,
        "type": "gneg"
      },
      {
        "id": "q23.3",
        "start": 64800001,
        "end": 67900000,
        "type": "gpos50"
      },
      {
        "id": "q24.1",
        "start": 67900001,
        "end": 70200000,
        "type": "gneg"
      },
      {
        "id": "q24.2",
        "start": 70200001,
        "end": 73800000,
        "type": "gpos50"
      },
      {
        "id": "q24.3",
        "start": 73800001,
        "end": 79300000,
        "type": "gneg"
      },
      {
        "id": "q31.1",
        "start": 79300001,
        "end": 83600000,
        "type": "gpos100"
      },
      {
        "id": "q31.2",
        "start": 83600001,
        "end": 84900000,
        "type": "gneg"
      },
      {
        "id": "q31.3",
        "start": 84900001,
        "end": 89800000,
        "type": "gpos100"
      },
      {
        "id": "q32.11",
        "start": 89800001,
        "end": 91900000,
        "type": "gneg"
      },
      {
        "id": "q32.12",
        "start": 91900001,
        "end": 94700000,
        "type": "gpos25"
      },
      {
        "id": "q32.13",
        "start": 94700001,
        "end": 96300000,
        "type": "gneg"
      },
      {
        "id": "q32.2",
        "start": 96300001,
        "end": 101400000,
        "type": "gpos50"
      },
      {
        "id": "q32.31",
        "start": 101400001,
        "end": 103200000,
        "type": "gneg"
      },
      {
        "id": "q32.32",
        "start": 103200001,
        "end": 104000000,
        "type": "gpos50"
      },
      {
        "id": "q32.33",
        "start": 104000001,
        "end": 107349540,
        "type": "gneg"
      }
    ]
  },
  "15": {
    "size": 102531392,
    "bands": [
      {
        "id": "p11.1",
        "start": 15800001,
        "end": 19000000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 8700001,
        "end": 15800000,
        "type": "gvar"
      },
      {
        "id": "p12",
        "start": 3900001,
        "end": 8700000,
        "type": "stalk"
      },
      {
        "id": "p13",
        "start": 1,
        "end": 3900000,
        "type": "gvar"
      },
      {
        "id": "q11.1",
        "start": 19000001,
        "end": 20700000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 20700001,
        "end": 25700000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 25700001,
        "end": 28100000,
        "type": "gpos50"
      },
      {
        "id": "q13.1",
        "start": 28100001,
        "end": 30300000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 30300001,
        "end": 31200000,
        "type": "gpos50"
      },
      {
        "id": "q13.3",
        "start": 31200001,
        "end": 33600000,
        "type": "gneg"
      },
      {
        "id": "q14",
        "start": 33600001,
        "end": 40100000,
        "type": "gpos75"
      },
      {
        "id": "q15.1",
        "start": 40100001,
        "end": 42800000,
        "type": "gneg"
      },
      {
        "id": "q15.2",
        "start": 42800001,
        "end": 43600000,
        "type": "gpos25"
      },
      {
        "id": "q15.3",
        "start": 43600001,
        "end": 44800000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 44800001,
        "end": 49500000,
        "type": "gpos75"
      },
      {
        "id": "q21.2",
        "start": 49500001,
        "end": 52900000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 52900001,
        "end": 59100000,
        "type": "gpos75"
      },
      {
        "id": "q22.1",
        "start": 59100001,
        "end": 59300000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 59300001,
        "end": 63700000,
        "type": "gpos25"
      },
      {
        "id": "q22.31",
        "start": 63700001,
        "end": 67200000,
        "type": "gneg"
      },
      {
        "id": "q22.32",
        "start": 67200001,
        "end": 67300000,
        "type": "gpos25"
      },
      {
        "id": "q22.33",
        "start": 67300001,
        "end": 67500000,
        "type": "gneg"
      },
      {
        "id": "q23",
        "start": 67500001,
        "end": 72700000,
        "type": "gpos25"
      },
      {
        "id": "q24.1",
        "start": 72700001,
        "end": 75200000,
        "type": "gneg"
      },
      {
        "id": "q24.2",
        "start": 75200001,
        "end": 76600000,
        "type": "gpos25"
      },
      {
        "id": "q24.3",
        "start": 76600001,
        "end": 78300000,
        "type": "gneg"
      },
      {
        "id": "q25.1",
        "start": 78300001,
        "end": 81700000,
        "type": "gpos50"
      },
      {
        "id": "q25.2",
        "start": 81700001,
        "end": 85200000,
        "type": "gneg"
      },
      {
        "id": "q25.3",
        "start": 85200001,
        "end": 89100000,
        "type": "gpos50"
      },
      {
        "id": "q26.1",
        "start": 89100001,
        "end": 94300000,
        "type": "gneg"
      },
      {
        "id": "q26.2",
        "start": 94300001,
        "end": 98500000,
        "type": "gpos50"
      },
      {
        "id": "q26.3",
        "start": 98500001,
        "end": 102531392,
        "type": "gneg"
      }
    ]
  },
  "16": {
    "size": 90354753,
    "bands": [
      {
        "id": "p11.1",
        "start": 34600001,
        "end": 36600000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 28100001,
        "end": 34600000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 24200001,
        "end": 28100000,
        "type": "gpos50"
      },
      {
        "id": "p12.2",
        "start": 21200001,
        "end": 24200000,
        "type": "gneg"
      },
      {
        "id": "p12.3",
        "start": 16800001,
        "end": 21200000,
        "type": "gpos50"
      },
      {
        "id": "p13.11",
        "start": 14800001,
        "end": 16800000,
        "type": "gneg"
      },
      {
        "id": "p13.12",
        "start": 12600001,
        "end": 14800000,
        "type": "gpos50"
      },
      {
        "id": "p13.13",
        "start": 10500001,
        "end": 12600000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 7900001,
        "end": 10500000,
        "type": "gpos50"
      },
      {
        "id": "p13.3",
        "start": 1,
        "end": 7900000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 36600001,
        "end": 38600000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 38600001,
        "end": 47000000,
        "type": "gvar"
      },
      {
        "id": "q12.1",
        "start": 47000001,
        "end": 52600000,
        "type": "gneg"
      },
      {
        "id": "q12.2",
        "start": 52600001,
        "end": 56700000,
        "type": "gpos50"
      },
      {
        "id": "q13",
        "start": 56700001,
        "end": 57400000,
        "type": "gneg"
      },
      {
        "id": "q21",
        "start": 57400001,
        "end": 66700000,
        "type": "gpos100"
      },
      {
        "id": "q22.1",
        "start": 66700001,
        "end": 70800000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 70800001,
        "end": 72900000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 72900001,
        "end": 74100000,
        "type": "gneg"
      },
      {
        "id": "q23.1",
        "start": 74100001,
        "end": 79200000,
        "type": "gpos75"
      },
      {
        "id": "q23.2",
        "start": 79200001,
        "end": 81700000,
        "type": "gneg"
      },
      {
        "id": "q23.3",
        "start": 81700001,
        "end": 84200000,
        "type": "gpos50"
      },
      {
        "id": "q24.1",
        "start": 84200001,
        "end": 87100000,
        "type": "gneg"
      },
      {
        "id": "q24.2",
        "start": 87100001,
        "end": 88700000,
        "type": "gpos25"
      },
      {
        "id": "q24.3",
        "start": 88700001,
        "end": 90354753,
        "type": "gneg"
      }
    ]
  },
  "17": {
    "size": 81195210,
    "bands": [
      {
        "id": "p11.1",
        "start": 22200001,
        "end": 24000000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 16000001,
        "end": 22200000,
        "type": "gneg"
      },
      {
        "id": "p12",
        "start": 10700001,
        "end": 16000000,
        "type": "gpos75"
      },
      {
        "id": "p13.1",
        "start": 6500001,
        "end": 10700000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 3300001,
        "end": 6500000,
        "type": "gpos50"
      },
      {
        "id": "p13.3",
        "start": 1,
        "end": 3300000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 24000001,
        "end": 25800000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 25800001,
        "end": 31800000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 31800001,
        "end": 38100000,
        "type": "gpos50"
      },
      {
        "id": "q21.1",
        "start": 38100001,
        "end": 38400000,
        "type": "gneg"
      },
      {
        "id": "q21.2",
        "start": 38400001,
        "end": 40900000,
        "type": "gpos25"
      },
      {
        "id": "q21.31",
        "start": 40900001,
        "end": 44900000,
        "type": "gneg"
      },
      {
        "id": "q21.32",
        "start": 44900001,
        "end": 47400000,
        "type": "gpos25"
      },
      {
        "id": "q21.33",
        "start": 47400001,
        "end": 50200000,
        "type": "gneg"
      },
      {
        "id": "q22",
        "start": 50200001,
        "end": 57600000,
        "type": "gpos75"
      },
      {
        "id": "q23.1",
        "start": 57600001,
        "end": 58300000,
        "type": "gneg"
      },
      {
        "id": "q23.2",
        "start": 58300001,
        "end": 61100000,
        "type": "gpos75"
      },
      {
        "id": "q23.3",
        "start": 61100001,
        "end": 62600000,
        "type": "gneg"
      },
      {
        "id": "q24.1",
        "start": 62600001,
        "end": 64200000,
        "type": "gpos50"
      },
      {
        "id": "q24.2",
        "start": 64200001,
        "end": 67100000,
        "type": "gneg"
      },
      {
        "id": "q24.3",
        "start": 67100001,
        "end": 70900000,
        "type": "gpos75"
      },
      {
        "id": "q25.1",
        "start": 70900001,
        "end": 74800000,
        "type": "gneg"
      },
      {
        "id": "q25.2",
        "start": 74800001,
        "end": 75300000,
        "type": "gpos25"
      },
      {
        "id": "q25.3",
        "start": 75300001,
        "end": 81195210,
        "type": "gneg"
      }
    ]
  },
  "18": {
    "size": 78077248,
    "bands": [
      {
        "id": "p11.1",
        "start": 15400001,
        "end": 17200000,
        "type": "acen"
      },
      {
        "id": "p11.21",
        "start": 10900001,
        "end": 15400000,
        "type": "gneg"
      },
      {
        "id": "p11.22",
        "start": 8500001,
        "end": 10900000,
        "type": "gpos25"
      },
      {
        "id": "p11.23",
        "start": 7100001,
        "end": 8500000,
        "type": "gneg"
      },
      {
        "id": "p11.31",
        "start": 2900001,
        "end": 7100000,
        "type": "gpos50"
      },
      {
        "id": "p11.32",
        "start": 1,
        "end": 2900000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 17200001,
        "end": 19000000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 19000001,
        "end": 25000000,
        "type": "gneg"
      },
      {
        "id": "q12.1",
        "start": 25000001,
        "end": 32700000,
        "type": "gpos100"
      },
      {
        "id": "q12.2",
        "start": 32700001,
        "end": 37200000,
        "type": "gneg"
      },
      {
        "id": "q12.3",
        "start": 37200001,
        "end": 43500000,
        "type": "gpos75"
      },
      {
        "id": "q21.1",
        "start": 43500001,
        "end": 48200000,
        "type": "gneg"
      },
      {
        "id": "q21.2",
        "start": 48200001,
        "end": 53800000,
        "type": "gpos75"
      },
      {
        "id": "q21.31",
        "start": 53800001,
        "end": 56200000,
        "type": "gneg"
      },
      {
        "id": "q21.32",
        "start": 56200001,
        "end": 59000000,
        "type": "gpos50"
      },
      {
        "id": "q21.33",
        "start": 59000001,
        "end": 61600000,
        "type": "gneg"
      },
      {
        "id": "q22.1",
        "start": 61600001,
        "end": 66800000,
        "type": "gpos100"
      },
      {
        "id": "q22.2",
        "start": 66800001,
        "end": 68700000,
        "type": "gneg"
      },
      {
        "id": "q22.3",
        "start": 68700001,
        "end": 73100000,
        "type": "gpos25"
      },
      {
        "id": "q23",
        "start": 73100001,
        "end": 78077248,
        "type": "gneg"
      }
    ]
  },
  "19": {
    "size": 59128983,
    "bands": [
      {
        "id": "p11",
        "start": 24400001,
        "end": 26500000,
        "type": "acen"
      },
      {
        "id": "p12",
        "start": 20000001,
        "end": 24400000,
        "type": "gvar"
      },
      {
        "id": "p13.11",
        "start": 16300001,
        "end": 20000000,
        "type": "gneg"
      },
      {
        "id": "p13.12",
        "start": 14000001,
        "end": 16300000,
        "type": "gpos25"
      },
      {
        "id": "p13.13",
        "start": 13900001,
        "end": 14000000,
        "type": "gneg"
      },
      {
        "id": "p13.2",
        "start": 6900001,
        "end": 13900000,
        "type": "gpos25"
      },
      {
        "id": "p13.3",
        "start": 1,
        "end": 6900000,
        "type": "gneg"
      },
      {
        "id": "q11",
        "start": 26500001,
        "end": 28600000,
        "type": "acen"
      },
      {
        "id": "q12",
        "start": 28600001,
        "end": 32400000,
        "type": "gvar"
      },
      {
        "id": "q13.11",
        "start": 32400001,
        "end": 35500000,
        "type": "gneg"
      },
      {
        "id": "q13.12",
        "start": 35500001,
        "end": 38300000,
        "type": "gpos25"
      },
      {
        "id": "q13.13",
        "start": 38300001,
        "end": 38700000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 38700001,
        "end": 43400000,
        "type": "gpos25"
      },
      {
        "id": "q13.31",
        "start": 43400001,
        "end": 45200000,
        "type": "gneg"
      },
      {
        "id": "q13.32",
        "start": 45200001,
        "end": 48000000,
        "type": "gpos25"
      },
      {
        "id": "q13.33",
        "start": 48000001,
        "end": 51400000,
        "type": "gneg"
      },
      {
        "id": "q13.41",
        "start": 51400001,
        "end": 53600000,
        "type": "gpos25"
      },
      {
        "id": "q13.42",
        "start": 53600001,
        "end": 56300000,
        "type": "gneg"
      },
      {
        "id": "q13.43",
        "start": 56300001,
        "end": 59128983,
        "type": "gpos25"
      }
    ]
  },
  "20": {
    "size": 63025520,
    "bands": [
      {
        "id": "p11.1",
        "start": 25600001,
        "end": 27500000,
        "type": "acen"
      },
      {
        "id": "p11.21",
        "start": 22300001,
        "end": 25600000,
        "type": "gneg"
      },
      {
        "id": "p11.22",
        "start": 21300001,
        "end": 22300000,
        "type": "gpos25"
      },
      {
        "id": "p11.23",
        "start": 17900001,
        "end": 21300000,
        "type": "gneg"
      },
      {
        "id": "p12.1",
        "start": 12100001,
        "end": 17900000,
        "type": "gpos75"
      },
      {
        "id": "p12.2",
        "start": 9200001,
        "end": 12100000,
        "type": "gneg"
      },
      {
        "id": "p12.3",
        "start": 5100001,
        "end": 9200000,
        "type": "gpos75"
      },
      {
        "id": "p13",
        "start": 1,
        "end": 5100000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 27500001,
        "end": 29400000,
        "type": "acen"
      },
      {
        "id": "q11.21",
        "start": 29400001,
        "end": 32100000,
        "type": "gneg"
      },
      {
        "id": "q11.22",
        "start": 32100001,
        "end": 34400000,
        "type": "gpos25"
      },
      {
        "id": "q11.23",
        "start": 34400001,
        "end": 37600000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 37600001,
        "end": 41700000,
        "type": "gpos75"
      },
      {
        "id": "q13.11",
        "start": 41700001,
        "end": 42100000,
        "type": "gneg"
      },
      {
        "id": "q13.12",
        "start": 42100001,
        "end": 46400000,
        "type": "gpos25"
      },
      {
        "id": "q13.13",
        "start": 46400001,
        "end": 49800000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 49800001,
        "end": 55000000,
        "type": "gpos75"
      },
      {
        "id": "q13.31",
        "start": 55000001,
        "end": 56500000,
        "type": "gneg"
      },
      {
        "id": "q13.32",
        "start": 56500001,
        "end": 58400000,
        "type": "gpos50"
      },
      {
        "id": "q13.33",
        "start": 58400001,
        "end": 63025520,
        "type": "gneg"
      }
    ]
  },
  "21": {
    "size": 48129895,
    "bands": [
      {
        "id": "p11.1",
        "start": 10900001,
        "end": 13200000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 6800001,
        "end": 10900000,
        "type": "gvar"
      },
      {
        "id": "p12",
        "start": 2800001,
        "end": 6800000,
        "type": "stalk"
      },
      {
        "id": "p13",
        "start": 1,
        "end": 2800000,
        "type": "gvar"
      },
      {
        "id": "q11.1",
        "start": 13200001,
        "end": 14300000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 14300001,
        "end": 16400000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 16400001,
        "end": 24000000,
        "type": "gpos100"
      },
      {
        "id": "q21.2",
        "start": 24000001,
        "end": 26800000,
        "type": "gneg"
      },
      {
        "id": "q21.3",
        "start": 26800001,
        "end": 31500000,
        "type": "gpos75"
      },
      {
        "id": "q22.11",
        "start": 31500001,
        "end": 35800000,
        "type": "gneg"
      },
      {
        "id": "q22.12",
        "start": 35800001,
        "end": 37800000,
        "type": "gpos50"
      },
      {
        "id": "q22.13",
        "start": 37800001,
        "end": 39700000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 39700001,
        "end": 42600000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 42600001,
        "end": 48129895,
        "type": "gneg"
      }
    ]
  },
  "22": {
    "size": 51304566,
    "bands": [
      {
        "id": "p11.1",
        "start": 12200001,
        "end": 14700000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 8300001,
        "end": 12200000,
        "type": "gvar"
      },
      {
        "id": "p12",
        "start": 3800001,
        "end": 8300000,
        "type": "stalk"
      },
      {
        "id": "p13",
        "start": 1,
        "end": 3800000,
        "type": "gvar"
      },
      {
        "id": "q11.1",
        "start": 14700001,
        "end": 17900000,
        "type": "acen"
      },
      {
        "id": "q11.21",
        "start": 17900001,
        "end": 22200000,
        "type": "gneg"
      },
      {
        "id": "q11.22",
        "start": 22200001,
        "end": 23500000,
        "type": "gpos25"
      },
      {
        "id": "q11.23",
        "start": 23500001,
        "end": 25900000,
        "type": "gneg"
      },
      {
        "id": "q12.1",
        "start": 25900001,
        "end": 29600000,
        "type": "gpos50"
      },
      {
        "id": "q12.2",
        "start": 29600001,
        "end": 32200000,
        "type": "gneg"
      },
      {
        "id": "q12.3",
        "start": 32200001,
        "end": 37600000,
        "type": "gpos50"
      },
      {
        "id": "q13.1",
        "start": 37600001,
        "end": 41000000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 41000001,
        "end": 44200000,
        "type": "gpos50"
      },
      {
        "id": "q13.31",
        "start": 44200001,
        "end": 48400000,
        "type": "gneg"
      },
      {
        "id": "q13.32",
        "start": 48400001,
        "end": 49400000,
        "type": "gpos50"
      },
      {
        "id": "q13.33",
        "start": 49400001,
        "end": 51304566,
        "type": "gneg"
      }
    ]
  },
  "X": {
    "size": 155270560,
    "bands": [
      {
        "id": "p11.1",
        "start": 58100001,
        "end": 60600000,
        "type": "acen"
      },
      {
        "id": "p11.21",
        "start": 54800001,
        "end": 58100000,
        "type": "gneg"
      },
      {
        "id": "p11.22",
        "start": 49800001,
        "end": 54800000,
        "type": "gpos25"
      },
      {
        "id": "p11.23",
        "start": 46400001,
        "end": 49800000,
        "type": "gneg"
      },
      {
        "id": "p11.3",
        "start": 42400001,
        "end": 46400000,
        "type": "gpos75"
      },
      {
        "id": "p11.4",
        "start": 37600001,
        "end": 42400000,
        "type": "gneg"
      },
      {
        "id": "p21.1",
        "start": 31500001,
        "end": 37600000,
        "type": "gpos100"
      },
      {
        "id": "p21.2",
        "start": 29300001,
        "end": 31500000,
        "type": "gneg"
      },
      {
        "id": "p21.3",
        "start": 24900001,
        "end": 29300000,
        "type": "gpos100"
      },
      {
        "id": "p22.11",
        "start": 21900001,
        "end": 24900000,
        "type": "gneg"
      },
      {
        "id": "p22.12",
        "start": 19300001,
        "end": 21900000,
        "type": "gpos50"
      },
      {
        "id": "p22.13",
        "start": 17100001,
        "end": 19300000,
        "type": "gneg"
      },
      {
        "id": "p22.2",
        "start": 9500001,
        "end": 17100000,
        "type": "gpos50"
      },
      {
        "id": "p22.31",
        "start": 6000001,
        "end": 9500000,
        "type": "gneg"
      },
      {
        "id": "p22.32",
        "start": 4300001,
        "end": 6000000,
        "type": "gpos50"
      },
      {
        "id": "p22.33",
        "start": 1,
        "end": 4300000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 60600001,
        "end": 63000000,
        "type": "acen"
      },
      {
        "id": "q11.2",
        "start": 63000001,
        "end": 64600000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 64600001,
        "end": 67800000,
        "type": "gpos50"
      },
      {
        "id": "q13.1",
        "start": 67800001,
        "end": 71800000,
        "type": "gneg"
      },
      {
        "id": "q13.2",
        "start": 71800001,
        "end": 73900000,
        "type": "gpos50"
      },
      {
        "id": "q13.3",
        "start": 73900001,
        "end": 76000000,
        "type": "gneg"
      },
      {
        "id": "q21.1",
        "start": 76000001,
        "end": 84600000,
        "type": "gpos100"
      },
      {
        "id": "q21.2",
        "start": 84600001,
        "end": 86200000,
        "type": "gneg"
      },
      {
        "id": "q21.31",
        "start": 86200001,
        "end": 91800000,
        "type": "gpos100"
      },
      {
        "id": "q21.32",
        "start": 91800001,
        "end": 93500000,
        "type": "gneg"
      },
      {
        "id": "q21.33",
        "start": 93500001,
        "end": 98300000,
        "type": "gpos75"
      },
      {
        "id": "q22.1",
        "start": 98300001,
        "end": 102600000,
        "type": "gneg"
      },
      {
        "id": "q22.2",
        "start": 102600001,
        "end": 103700000,
        "type": "gpos50"
      },
      {
        "id": "q22.3",
        "start": 103700001,
        "end": 108700000,
        "type": "gneg"
      },
      {
        "id": "q23",
        "start": 108700001,
        "end": 116500000,
        "type": "gpos75"
      },
      {
        "id": "q24",
        "start": 116500001,
        "end": 120900000,
        "type": "gneg"
      },
      {
        "id": "q25",
        "start": 120900001,
        "end": 128700000,
        "type": "gpos100"
      },
      {
        "id": "q26.1",
        "start": 128700001,
        "end": 130400000,
        "type": "gneg"
      },
      {
        "id": "q26.2",
        "start": 130400001,
        "end": 133600000,
        "type": "gpos25"
      },
      {
        "id": "q26.3",
        "start": 133600001,
        "end": 138000000,
        "type": "gneg"
      },
      {
        "id": "q27.1",
        "start": 138000001,
        "end": 140300000,
        "type": "gpos75"
      },
      {
        "id": "q27.2",
        "start": 140300001,
        "end": 142100000,
        "type": "gneg"
      },
      {
        "id": "q27.3",
        "start": 142100001,
        "end": 147100000,
        "type": "gpos100"
      },
      {
        "id": "q28",
        "start": 147100001,
        "end": 155270560,
        "type": "gneg"
      }
    ]
  },
  "Y": {
    "size": 59373566,
    "bands": [
      {
        "id": "p11.1",
        "start": 11600001,
        "end": 12500000,
        "type": "acen"
      },
      {
        "id": "p11.2",
        "start": 3000001,
        "end": 11600000,
        "type": "gneg"
      },
      {
        "id": "p11.31",
        "start": 2500001,
        "end": 3000000,
        "type": "gpos50"
      },
      {
        "id": "p11.32",
        "start": 1,
        "end": 2500000,
        "type": "gneg"
      },
      {
        "id": "q11.1",
        "start": 12500001,
        "end": 13400000,
        "type": "acen"
      },
      {
        "id": "q11.21",
        "start": 13400001,
        "end": 15100000,
        "type": "gneg"
      },
      {
        "id": "q11.221",
        "start": 15100001,
        "end": 19800000,
        "type": "gpos50"
      },
      {
        "id": "q11.222",
        "start": 19800001,
        "end": 22100000,
        "type": "gneg"
      },
      {
        "id": "q11.223",
        "start": 22100001,
        "end": 26200000,
        "type": "gpos50"
      },
      {
        "id": "q11.23",
        "start": 26200001,
        "end": 28800000,
        "type": "gneg"
      },
      {
        "id": "q12",
        "start": 28800001,
        "end": 59373566,
        "type": "gvar"
      }
    ]
  }
};




var grcm38 = {
  "1": {
    "size": 195471971,
    "bands": [
      {
        "id": "A1",
        "start": 2973781,
        "end": 8840440,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 8840441,
        "end": 12278389,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 12278390,
        "end": 20136559,
        "type": "gpos33"
      },
      {
        "id": "A4",
        "start": 20136560,
        "end": 22101101,
        "type": "gneg"
      },
      {
        "id": "A5",
        "start": 22101102,
        "end": 30941542,
        "type": "gpos100"
      },
      {
        "id": "B",
        "start": 30941543,
        "end": 43219933,
        "type": "gneg"
      },
      {
        "id": "C1.1",
        "start": 43219934,
        "end": 54516051,
        "type": "gpos66"
      },
      {
        "id": "C1.2",
        "start": 54516052,
        "end": 55989458,
        "type": "gneg"
      },
      {
        "id": "C1.3",
        "start": 55989459,
        "end": 59427408,
        "type": "gpos66"
      },
      {
        "id": "C2",
        "start": 59427409,
        "end": 65321034,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 65321035,
        "end": 74652611,
        "type": "gpos33"
      },
      {
        "id": "C4",
        "start": 74652612,
        "end": 80055103,
        "type": "gneg"
      },
      {
        "id": "C5",
        "start": 80055104,
        "end": 87422136,
        "type": "gpos33"
      },
      {
        "id": "cenp",
        "start": 991261,
        "end": 1982520,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1982521,
        "end": 2973780,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 87422137,
        "end": 99700527,
        "type": "gneg"
      },
      {
        "id": "E1.1",
        "start": 99700528,
        "end": 102647341,
        "type": "gpos33"
      },
      {
        "id": "E1.2",
        "start": 102647342,
        "end": 103629611,
        "type": "gneg"
      },
      {
        "id": "E2.1",
        "start": 103629612,
        "end": 112470053,
        "type": "gpos100"
      },
      {
        "id": "E2.2",
        "start": 112470054,
        "end": 113943460,
        "type": "gneg"
      },
      {
        "id": "E2.3",
        "start": 113943461,
        "end": 125730714,
        "type": "gpos100"
      },
      {
        "id": "E3",
        "start": 125730715,
        "end": 128677528,
        "type": "gneg"
      },
      {
        "id": "E4",
        "start": 128677529,
        "end": 139482511,
        "type": "gpos66"
      },
      {
        "id": "F",
        "start": 139482512,
        "end": 147340680,
        "type": "gneg"
      },
      {
        "id": "G1",
        "start": 147340681,
        "end": 151760902,
        "type": "gpos100"
      },
      {
        "id": "G2",
        "start": 151760903,
        "end": 152743172,
        "type": "gneg"
      },
      {
        "id": "G3",
        "start": 152743173,
        "end": 157163393,
        "type": "gpos100"
      },
      {
        "id": "H1",
        "start": 157163394,
        "end": 160110206,
        "type": "gneg"
      },
      {
        "id": "H2.1",
        "start": 160110207,
        "end": 164039291,
        "type": "gpos33"
      },
      {
        "id": "H2.2",
        "start": 164039292,
        "end": 165512698,
        "type": "gneg"
      },
      {
        "id": "H2.3",
        "start": 165512699,
        "end": 169932918,
        "type": "gpos33"
      },
      {
        "id": "H3",
        "start": 169932919,
        "end": 175826546,
        "type": "gneg"
      },
      {
        "id": "H4",
        "start": 175826547,
        "end": 181720173,
        "type": "gpos33"
      },
      {
        "id": "H5",
        "start": 181720174,
        "end": 188104936,
        "type": "gneg"
      },
      {
        "id": "H6",
        "start": 188104937,
        "end": 195471971,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 991260,
        "type": "tip"
      }
    ]
  },
  "2": {
    "size": 182113224,
    "bands": [
      {
        "id": "A1",
        "start": 3006028,
        "end": 14080919,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 14080920,
        "end": 16427738,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 16427739,
        "end": 29100566,
        "type": "gpos33"
      },
      {
        "id": "B",
        "start": 29100567,
        "end": 48344489,
        "type": "gneg"
      },
      {
        "id": "C1.1",
        "start": 48344490,
        "end": 60547952,
        "type": "gpos100"
      },
      {
        "id": "C1.2",
        "start": 60547953,
        "end": 61017316,
        "type": "gneg"
      },
      {
        "id": "C1.3",
        "start": 61017317,
        "end": 68527140,
        "type": "gpos100"
      },
      {
        "id": "C2",
        "start": 68527141,
        "end": 71812688,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 71812689,
        "end": 81199967,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 1002010,
        "end": 2004018,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2004019,
        "end": 3006027,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 81199968,
        "end": 88709791,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 88709792,
        "end": 101382619,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 101382620,
        "end": 105137530,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 105137531,
        "end": 113116719,
        "type": "gpos33"
      },
      {
        "id": "E4",
        "start": 113116720,
        "end": 115932902,
        "type": "gneg"
      },
      {
        "id": "E5",
        "start": 115932903,
        "end": 123912089,
        "type": "gpos66"
      },
      {
        "id": "F1",
        "start": 123912090,
        "end": 131891278,
        "type": "gneg"
      },
      {
        "id": "F2",
        "start": 131891279,
        "end": 134707461,
        "type": "gpos33"
      },
      {
        "id": "F3",
        "start": 134707462,
        "end": 141278557,
        "type": "gneg"
      },
      {
        "id": "G1",
        "start": 141278558,
        "end": 146910925,
        "type": "gpos100"
      },
      {
        "id": "G2",
        "start": 146910926,
        "end": 147849652,
        "type": "gneg"
      },
      {
        "id": "G3",
        "start": 147849653,
        "end": 152543293,
        "type": "gpos100"
      },
      {
        "id": "H1",
        "start": 152543294,
        "end": 159114388,
        "type": "gneg"
      },
      {
        "id": "H2",
        "start": 159114389,
        "end": 163338664,
        "type": "gpos33"
      },
      {
        "id": "H3",
        "start": 163338665,
        "end": 173664671,
        "type": "gneg"
      },
      {
        "id": "H4",
        "start": 173664672,
        "end": 182113224,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1002009,
        "type": "tip"
      }
    ]
  },
  "3": {
    "size": 160039680,
    "bands": [
      {
        "id": "A1",
        "start": 3008269,
        "end": 18541181,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 18541182,
        "end": 20492885,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 20492886,
        "end": 35618586,
        "type": "gpos66"
      },
      {
        "id": "B",
        "start": 35618587,
        "end": 46840881,
        "type": "gneg"
      },
      {
        "id": "C",
        "start": 46840882,
        "end": 56599398,
        "type": "gpos100"
      },
      {
        "id": "cenp",
        "start": 1002757,
        "end": 2005512,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2005513,
        "end": 3008268,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 56599399,
        "end": 60990731,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 60990732,
        "end": 69773396,
        "type": "gpos33"
      },
      {
        "id": "E2",
        "start": 69773397,
        "end": 72700951,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 72700952,
        "end": 83923246,
        "type": "gpos100"
      },
      {
        "id": "F1",
        "start": 83923247,
        "end": 93193837,
        "type": "gneg"
      },
      {
        "id": "F2.1",
        "start": 93193838,
        "end": 97585169,
        "type": "gpos33"
      },
      {
        "id": "F2.2",
        "start": 97585170,
        "end": 106367835,
        "type": "gneg"
      },
      {
        "id": "F2.3",
        "start": 106367836,
        "end": 108319539,
        "type": "gpos33"
      },
      {
        "id": "F3",
        "start": 108319540,
        "end": 115150501,
        "type": "gneg"
      },
      {
        "id": "G1",
        "start": 115150502,
        "end": 126860721,
        "type": "gpos100"
      },
      {
        "id": "G2",
        "start": 126860722,
        "end": 128812424,
        "type": "gneg"
      },
      {
        "id": "G3",
        "start": 128812425,
        "end": 138570942,
        "type": "gpos66"
      },
      {
        "id": "H1",
        "start": 138570943,
        "end": 143938126,
        "type": "gneg"
      },
      {
        "id": "H2",
        "start": 143938127,
        "end": 148329459,
        "type": "gpos33"
      },
      {
        "id": "H3",
        "start": 148329460,
        "end": 154184569,
        "type": "gneg"
      },
      {
        "id": "H4",
        "start": 154184570,
        "end": 160039680,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1002756,
        "type": "tip"
      }
    ]
  },
  "4": {
    "size": 156508116,
    "bands": [
      {
        "id": "A1",
        "start": 3016925,
        "end": 14882673,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 14882674,
        "end": 17763190,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 17763191,
        "end": 28325088,
        "type": "gpos100"
      },
      {
        "id": "A4",
        "start": 28325089,
        "end": 30245433,
        "type": "gneg"
      },
      {
        "id": "A5",
        "start": 30245434,
        "end": 43687847,
        "type": "gpos66"
      },
      {
        "id": "B1",
        "start": 43687848,
        "end": 51849313,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 51849314,
        "end": 55209917,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 55209918,
        "end": 63371383,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 63371384,
        "end": 69612504,
        "type": "gpos33"
      },
      {
        "id": "C2",
        "start": 69612505,
        "end": 72012935,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 72012936,
        "end": 84015092,
        "type": "gpos100"
      },
      {
        "id": "C4",
        "start": 84015093,
        "end": 89776127,
        "type": "gneg"
      },
      {
        "id": "C5",
        "start": 89776128,
        "end": 97457507,
        "type": "gpos66"
      },
      {
        "id": "C6",
        "start": 97457508,
        "end": 105618973,
        "type": "gneg"
      },
      {
        "id": "C7",
        "start": 105618974,
        "end": 110899922,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 1005642,
        "end": 2011283,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2011284,
        "end": 3016924,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 110899923,
        "end": 117621129,
        "type": "gneg"
      },
      {
        "id": "D2.1",
        "start": 117621130,
        "end": 120501647,
        "type": "gpos33"
      },
      {
        "id": "D2.2",
        "start": 120501648,
        "end": 131063544,
        "type": "gneg"
      },
      {
        "id": "D2.3",
        "start": 131063545,
        "end": 133944061,
        "type": "gpos33"
      },
      {
        "id": "D3",
        "start": 133944062,
        "end": 141625441,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 141625442,
        "end": 147866562,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 147866563,
        "end": 156508116,
        "type": "gneg"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1005641,
        "type": "tip"
      }
    ]
  },
  "5": {
    "size": 151834684,
    "bands": [
      {
        "id": "A1",
        "start": 2986183,
        "end": 14895174,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 14895175,
        "end": 16336642,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 16336643,
        "end": 25465943,
        "type": "gpos66"
      },
      {
        "id": "B1",
        "start": 25465944,
        "end": 33634265,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 33634266,
        "end": 35556222,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 35556223,
        "end": 50451397,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 50451398,
        "end": 58619719,
        "type": "gpos33"
      },
      {
        "id": "C2",
        "start": 58619720,
        "end": 61022166,
        "type": "gneg"
      },
      {
        "id": "C3.1",
        "start": 61022167,
        "end": 71592935,
        "type": "gpos100"
      },
      {
        "id": "C3.2",
        "start": 71592936,
        "end": 73514894,
        "type": "gneg"
      },
      {
        "id": "C3.3",
        "start": 73514895,
        "end": 77839299,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 995395,
        "end": 1990788,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1990789,
        "end": 2986182,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 77839300,
        "end": 81683215,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 81683216,
        "end": 91293005,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 91293006,
        "end": 93695452,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 93695453,
        "end": 99461326,
        "type": "gpos33"
      },
      {
        "id": "E4",
        "start": 99461327,
        "end": 101863775,
        "type": "gneg"
      },
      {
        "id": "E5",
        "start": 101863776,
        "end": 107629649,
        "type": "gpos33"
      },
      {
        "id": "F",
        "start": 107629650,
        "end": 124927270,
        "type": "gneg"
      },
      {
        "id": "G1.1",
        "start": 124927271,
        "end": 126849229,
        "type": "gpos33"
      },
      {
        "id": "G1.2",
        "start": 126849230,
        "end": 127810207,
        "type": "gneg"
      },
      {
        "id": "G1.3",
        "start": 127810208,
        "end": 130693144,
        "type": "gpos33"
      },
      {
        "id": "G2",
        "start": 130693145,
        "end": 146068809,
        "type": "gneg"
      },
      {
        "id": "G3",
        "start": 146068810,
        "end": 151834684,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 995394,
        "type": "tip"
      }
    ]
  },
  "6": {
    "size": 149736546,
    "bands": [
      {
        "id": "A1",
        "start": 3004405,
        "end": 16637393,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 16637394,
        "end": 21530744,
        "type": "gneg"
      },
      {
        "id": "A3.1",
        "start": 21530745,
        "end": 27402766,
        "type": "gpos100"
      },
      {
        "id": "A3.2",
        "start": 27402767,
        "end": 28381436,
        "type": "gneg"
      },
      {
        "id": "A3.3",
        "start": 28381437,
        "end": 34253457,
        "type": "gpos100"
      },
      {
        "id": "B1",
        "start": 34253458,
        "end": 41593484,
        "type": "gneg"
      },
      {
        "id": "B2.1",
        "start": 41593485,
        "end": 44529494,
        "type": "gpos66"
      },
      {
        "id": "B2.2",
        "start": 44529495,
        "end": 45997500,
        "type": "gneg"
      },
      {
        "id": "B2.3",
        "start": 45997501,
        "end": 50890851,
        "type": "gpos66"
      },
      {
        "id": "B3",
        "start": 50890852,
        "end": 62634894,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 62634895,
        "end": 74378937,
        "type": "gpos100"
      },
      {
        "id": "C2",
        "start": 74378938,
        "end": 76825612,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 76825613,
        "end": 86122980,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 1001469,
        "end": 2002936,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2002937,
        "end": 3004404,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 86122981,
        "end": 94441677,
        "type": "gneg"
      },
      {
        "id": "D2",
        "start": 94441678,
        "end": 95909682,
        "type": "gpos33"
      },
      {
        "id": "D3",
        "start": 95909683,
        "end": 103249709,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 103249710,
        "end": 108632395,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 108632396,
        "end": 109611066,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 109611067,
        "end": 116951092,
        "type": "gpos100"
      },
      {
        "id": "F1",
        "start": 116951093,
        "end": 122823113,
        "type": "gneg"
      },
      {
        "id": "F2",
        "start": 122823114,
        "end": 125269789,
        "type": "gpos33"
      },
      {
        "id": "F3",
        "start": 125269790,
        "end": 132120481,
        "type": "gneg"
      },
      {
        "id": "G1",
        "start": 132120482,
        "end": 139460507,
        "type": "gpos66"
      },
      {
        "id": "G2",
        "start": 139460508,
        "end": 142885854,
        "type": "gneg"
      },
      {
        "id": "G3",
        "start": 142885855,
        "end": 149736546,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1001468,
        "type": "tip"
      }
    ]
  },
  "7": {
    "size": 145441459,
    "bands": [
      {
        "id": "A1",
        "start": 2860683,
        "end": 15202939,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 15202940,
        "end": 18243527,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 18243528,
        "end": 28378820,
        "type": "gpos33"
      },
      {
        "id": "B1",
        "start": 28378821,
        "end": 34459996,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 34459997,
        "end": 37500585,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 37500585,
        "end": 47635877,
        "type": "gneg"
      },
      {
        "id": "B4",
        "start": 47635878,
        "end": 54223818,
        "type": "gpos33"
      },
      {
        "id": "B5",
        "start": 54223819,
        "end": 60811759,
        "type": "gneg"
      },
      {
        "id": "C",
        "start": 60811760,
        "end": 71453817,
        "type": "gpos100"
      },
      {
        "id": "cenp",
        "start": 953561,
        "end": 1907121,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1907122,
        "end": 2860682,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 71453818,
        "end": 77028228,
        "type": "gneg"
      },
      {
        "id": "D2",
        "start": 77028229,
        "end": 80575581,
        "type": "gpos66"
      },
      {
        "id": "D3",
        "start": 80575582,
        "end": 90204109,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 90204110,
        "end": 99832638,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 99832639,
        "end": 102366461,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 102366462,
        "end": 111488225,
        "type": "gpos33"
      },
      {
        "id": "F1",
        "start": 111488226,
        "end": 118582930,
        "type": "gneg"
      },
      {
        "id": "F2",
        "start": 118582931,
        "end": 123143812,
        "type": "gpos33"
      },
      {
        "id": "F3",
        "start": 123143813,
        "end": 137333224,
        "type": "gneg"
      },
      {
        "id": "F4",
        "start": 137333225,
        "end": 140880576,
        "type": "gpos33"
      },
      {
        "id": "F5",
        "start": 140880577,
        "end": 145441459,
        "type": "gneg"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 953560,
        "type": "tip"
      }
    ]
  },
  "8": {
    "size": 129401213,
    "bands": [
      {
        "id": "A1.1",
        "start": 2946767,
        "end": 15940728,
        "type": "gpos100"
      },
      {
        "id": "A1.2",
        "start": 15940729,
        "end": 16878419,
        "type": "gneg"
      },
      {
        "id": "A1.3",
        "start": 16878420,
        "end": 20160333,
        "type": "gpos33"
      },
      {
        "id": "A2",
        "start": 20160334,
        "end": 29537233,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 29537234,
        "end": 33756838,
        "type": "gpos33"
      },
      {
        "id": "A4",
        "start": 33756839,
        "end": 44071427,
        "type": "gneg"
      },
      {
        "id": "B1.1",
        "start": 44071428,
        "end": 48291032,
        "type": "gpos66"
      },
      {
        "id": "B1.2",
        "start": 48291033,
        "end": 50166412,
        "type": "gneg"
      },
      {
        "id": "B1.3",
        "start": 50166413,
        "end": 55792551,
        "type": "gpos66"
      },
      {
        "id": "B2",
        "start": 55792552,
        "end": 59543311,
        "type": "gneg"
      },
      {
        "id": "B3.1",
        "start": 59543312,
        "end": 67044831,
        "type": "gpos100"
      },
      {
        "id": "B3.2",
        "start": 67044832,
        "end": 67982520,
        "type": "gneg"
      },
      {
        "id": "B3.3",
        "start": 67982521,
        "end": 74546350,
        "type": "gpos100"
      },
      {
        "id": "C1",
        "start": 74546351,
        "end": 80172490,
        "type": "gneg"
      },
      {
        "id": "C2",
        "start": 80172491,
        "end": 84860939,
        "type": "gpos33"
      },
      {
        "id": "C3",
        "start": 84860940,
        "end": 90018235,
        "type": "gneg"
      },
      {
        "id": "C4",
        "start": 90018236,
        "end": 91424769,
        "type": "gpos33"
      },
      {
        "id": "C5",
        "start": 91424770,
        "end": 95644374,
        "type": "gneg"
      },
      {
        "id": "cenp",
        "start": 982256,
        "end": 1964510,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1964511,
        "end": 2946766,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 95644375,
        "end": 103145894,
        "type": "gpos100"
      },
      {
        "id": "D2",
        "start": 103145895,
        "end": 104083583,
        "type": "gneg"
      },
      {
        "id": "D3",
        "start": 104083584,
        "end": 110647414,
        "type": "gpos33"
      },
      {
        "id": "E1",
        "start": 110647414,
        "end": 123775073,
        "type": "gneg"
      },
      {
        "id": "E2",
        "start": 123775074,
        "end": 129401213,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 982255,
        "type": "tip"
      }
    ]
  },
  "9": {
    "size": 124595110,
    "bands": [
      {
        "id": "A1",
        "start": 3012548,
        "end": 14412120,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 14412121,
        "end": 19526099,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 19526100,
        "end": 24175170,
        "type": "gpos33"
      },
      {
        "id": "A4",
        "start": 24175171,
        "end": 38122383,
        "type": "gneg"
      },
      {
        "id": "A5.1",
        "start": 38122384,
        "end": 44166176,
        "type": "gpos66"
      },
      {
        "id": "A5.2",
        "start": 44166177,
        "end": 46490712,
        "type": "gneg"
      },
      {
        "id": "A5.3",
        "start": 46490713,
        "end": 54859040,
        "type": "gpos66"
      },
      {
        "id": "B",
        "start": 54859041,
        "end": 63227368,
        "type": "gneg"
      },
      {
        "id": "C",
        "start": 63227369,
        "end": 69736068,
        "type": "gpos33"
      },
      {
        "id": "cenp",
        "start": 1004183,
        "end": 2008364,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2008365,
        "end": 3012547,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 69736069,
        "end": 77639490,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 77639491,
        "end": 82753467,
        "type": "gpos33"
      },
      {
        "id": "E2",
        "start": 82753468,
        "end": 84613096,
        "type": "gneg"
      },
      {
        "id": "E3.1",
        "start": 84613097,
        "end": 91121796,
        "type": "gpos100"
      },
      {
        "id": "E3.2",
        "start": 91121797,
        "end": 91586703,
        "type": "gneg"
      },
      {
        "id": "E3.3",
        "start": 91586704,
        "end": 100884845,
        "type": "gpos100"
      },
      {
        "id": "E4",
        "start": 100884846,
        "end": 101814660,
        "type": "gpos66"
      },
      {
        "id": "F1",
        "start": 101814661,
        "end": 108323360,
        "type": "gneg"
      },
      {
        "id": "F2",
        "start": 108323361,
        "end": 111112803,
        "type": "gpos33"
      },
      {
        "id": "F3",
        "start": 111112804,
        "end": 119946038,
        "type": "gneg"
      },
      {
        "id": "F4",
        "start": 119946039,
        "end": 124595110,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1004182,
        "type": "tip"
      }
    ]
  },
  "10": {
    "size": 130694993,
    "bands": [
      {
        "id": "A1",
        "start": 3016195,
        "end": 12822904,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 12822905,
        "end": 17754791,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 17754792,
        "end": 23673055,
        "type": "gpos33"
      },
      {
        "id": "A4",
        "start": 23673056,
        "end": 33536827,
        "type": "gneg"
      },
      {
        "id": "B1",
        "start": 33536828,
        "end": 41427846,
        "type": "gpos100"
      },
      {
        "id": "B2",
        "start": 41427847,
        "end": 48332487,
        "type": "gneg"
      },
      {
        "id": "B3",
        "start": 48332488,
        "end": 56223505,
        "type": "gpos100"
      },
      {
        "id": "B4",
        "start": 56223506,
        "end": 64114524,
        "type": "gneg"
      },
      {
        "id": "B5.1",
        "start": 64114525,
        "end": 68060033,
        "type": "gpos100"
      },
      {
        "id": "B5.2",
        "start": 68060034,
        "end": 68553222,
        "type": "gneg"
      },
      {
        "id": "B5.3",
        "start": 68553223,
        "end": 74964674,
        "type": "gpos100"
      },
      {
        "id": "C1",
        "start": 74964675,
        "end": 89267145,
        "type": "gneg"
      },
      {
        "id": "C2",
        "start": 89267146,
        "end": 96171787,
        "type": "gpos33"
      },
      {
        "id": "C3",
        "start": 96171788,
        "end": 99130918,
        "type": "gneg"
      },
      {
        "id": "cenp",
        "start": 1005399,
        "end": 2010796,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2010797,
        "end": 3016194,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 99130919,
        "end": 111953823,
        "type": "gpos100"
      },
      {
        "id": "D2",
        "start": 111953824,
        "end": 124776728,
        "type": "gneg"
      },
      {
        "id": "D3",
        "start": 124776729,
        "end": 130694993,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1005398,
        "type": "tip"
      }
    ]
  },
  "11": {
    "size": 122082543,
    "bands": [
      {
        "id": "A1",
        "start": 3005877,
        "end": 13046988,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 13046989,
        "end": 17240663,
        "type": "gneg"
      },
      {
        "id": "A3.1",
        "start": 17240664,
        "end": 21900302,
        "type": "gpos100"
      },
      {
        "id": "A3.2",
        "start": 21900303,
        "end": 25628014,
        "type": "gneg"
      },
      {
        "id": "A3.3",
        "start": 25628015,
        "end": 30287653,
        "type": "gpos100"
      },
      {
        "id": "A4",
        "start": 30287654,
        "end": 36345184,
        "type": "gneg"
      },
      {
        "id": "A5",
        "start": 36345185,
        "end": 43334642,
        "type": "gpos100"
      },
      {
        "id": "B1.1",
        "start": 43334643,
        "end": 47994281,
        "type": "gneg"
      },
      {
        "id": "B1.2",
        "start": 47994282,
        "end": 49858137,
        "type": "gpos33"
      },
      {
        "id": "B1.3",
        "start": 49858138,
        "end": 60109343,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 60109344,
        "end": 62905126,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 62905127,
        "end": 70826512,
        "type": "gneg"
      },
      {
        "id": "B4",
        "start": 70826513,
        "end": 74088260,
        "type": "gpos33"
      },
      {
        "id": "B5",
        "start": 74088261,
        "end": 82009646,
        "type": "gneg"
      },
      {
        "id": "C",
        "start": 82009647,
        "end": 90396996,
        "type": "gpos100"
      },
      {
        "id": "cenp",
        "start": 1001959,
        "end": 2003917,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2003918,
        "end": 3005876,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 90396997,
        "end": 102512058,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 102512059,
        "end": 110433444,
        "type": "gpos66"
      },
      {
        "id": "E2",
        "start": 110433445,
        "end": 122082543,
        "type": "gneg"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1001958,
        "type": "tip"
      }
    ]
  },
  "12": {
    "size": 120129022,
    "bands": [
      {
        "id": "A1.1",
        "start": 2972080,
        "end": 17601321,
        "type": "gpos100"
      },
      {
        "id": "A1.2",
        "start": 17601322,
        "end": 21121586,
        "type": "gneg"
      },
      {
        "id": "A1.3",
        "start": 21121587,
        "end": 25961949,
        "type": "gpos66"
      },
      {
        "id": "A2",
        "start": 25961949,
        "end": 31682378,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 31682379,
        "end": 39162941,
        "type": "gpos33"
      },
      {
        "id": "B1",
        "start": 39162942,
        "end": 44003304,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 44003305,
        "end": 44883370,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 44883371,
        "end": 51923898,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 51923899,
        "end": 66004956,
        "type": "gpos100"
      },
      {
        "id": "C2",
        "start": 66004957,
        "end": 71285352,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 71285353,
        "end": 80966079,
        "type": "gpos100"
      },
      {
        "id": "cenp",
        "start": 990694,
        "end": 1981386,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1981387,
        "end": 2972079,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 80966080,
        "end": 85366410,
        "type": "gneg"
      },
      {
        "id": "D2",
        "start": 85366411,
        "end": 88446642,
        "type": "gpos33"
      },
      {
        "id": "D3",
        "start": 88446643,
        "end": 95487170,
        "type": "gneg"
      },
      {
        "id": "E",
        "start": 95487171,
        "end": 106047964,
        "type": "gpos100"
      },
      {
        "id": "F1",
        "start": 106047965,
        "end": 114408591,
        "type": "gneg"
      },
      {
        "id": "F2",
        "start": 114408592,
        "end": 120129022,
        "type": "gpos66"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 990693,
        "type": "tip"
      }
    ]
  },
  "13": {
    "size": 120421639,
    "bands": [
      {
        "id": "A1",
        "start": 3003426,
        "end": 16286532,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 16286533,
        "end": 21221846,
        "type": "gneg"
      },
      {
        "id": "A3.1",
        "start": 21221847,
        "end": 29611877,
        "type": "gpos66"
      },
      {
        "id": "A3.2",
        "start": 29611878,
        "end": 33066596,
        "type": "gneg"
      },
      {
        "id": "A3.3",
        "start": 33066597,
        "end": 41456629,
        "type": "gpos33"
      },
      {
        "id": "A4",
        "start": 41456630,
        "end": 44417817,
        "type": "gneg"
      },
      {
        "id": "A5",
        "start": 44417818,
        "end": 52807849,
        "type": "gpos33"
      },
      {
        "id": "B1",
        "start": 52807850,
        "end": 59223756,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 59223757,
        "end": 61691412,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 61691413,
        "end": 69587913,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 69587914,
        "end": 78471477,
        "type": "gpos33"
      },
      {
        "id": "C2",
        "start": 78471478,
        "end": 80939133,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 80939134,
        "end": 94758010,
        "type": "gpos100"
      },
      {
        "id": "cenp",
        "start": 1001142,
        "end": 2002283,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2002284,
        "end": 3003425,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 94758011,
        "end": 106602762,
        "type": "gneg"
      },
      {
        "id": "D2.1",
        "start": 106602763,
        "end": 110551012,
        "type": "gpos33"
      },
      {
        "id": "D2.2",
        "start": 110551013,
        "end": 116473388,
        "type": "gneg"
      },
      {
        "id": "D2.3",
        "start": 116473389,
        "end": 120421639,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1001141,
        "type": "tip"
      }
    ]
  },
  "14": {
    "size": 124902244,
    "bands": [
      {
        "id": "A1",
        "start": 2992989,
        "end": 14988268,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 14988269,
        "end": 19484749,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 19484750,
        "end": 29976538,
        "type": "gpos33"
      },
      {
        "id": "B",
        "start": 29976539,
        "end": 43465980,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 43465981,
        "end": 51959333,
        "type": "gpos100"
      },
      {
        "id": "C2",
        "start": 51959334,
        "end": 54956987,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 54956988,
        "end": 59953076,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 997663,
        "end": 1995325,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1995326,
        "end": 2992988,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 59953077,
        "end": 68946037,
        "type": "gneg"
      },
      {
        "id": "D2",
        "start": 68946038,
        "end": 72942909,
        "type": "gpos33"
      },
      {
        "id": "D3",
        "start": 72942910,
        "end": 84933525,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 84933526,
        "end": 88930397,
        "type": "gpos66"
      },
      {
        "id": "E2.1",
        "start": 88930398,
        "end": 98922576,
        "type": "gpos100"
      },
      {
        "id": "E2.2",
        "start": 98922577,
        "end": 99921795,
        "type": "gneg"
      },
      {
        "id": "E2.3",
        "start": 99921795,
        "end": 107415929,
        "type": "gpos100"
      },
      {
        "id": "E3",
        "start": 107415930,
        "end": 110913192,
        "type": "gneg"
      },
      {
        "id": "E4",
        "start": 110913193,
        "end": 120905371,
        "type": "gpos100"
      },
      {
        "id": "E5",
        "start": 120905372,
        "end": 124902244,
        "type": "gneg"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 997662,
        "type": "tip"
      }
    ]
  },
  "15": {
    "size": 104043685,
    "bands": [
      {
        "id": "A1",
        "start": 3015906,
        "end": 16500319,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 16500320,
        "end": 24292137,
        "type": "gneg"
      },
      {
        "id": "B1",
        "start": 24292138,
        "end": 29792243,
        "type": "gpos33"
      },
      {
        "id": "B2",
        "start": 29792244,
        "end": 32083955,
        "type": "gneg"
      },
      {
        "id": "B3.1",
        "start": 32083956,
        "end": 43084168,
        "type": "gpos100"
      },
      {
        "id": "B3.2",
        "start": 43084169,
        "end": 44917537,
        "type": "gneg"
      },
      {
        "id": "B3.3",
        "start": 44917538,
        "end": 49959301,
        "type": "gpos66"
      },
      {
        "id": "C",
        "start": 49959302,
        "end": 53626039,
        "type": "gneg"
      },
      {
        "id": "cenp",
        "start": 1005302,
        "end": 2010603,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2010604,
        "end": 3015905,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 53626040,
        "end": 66459622,
        "type": "gpos100"
      },
      {
        "id": "D2",
        "start": 66459623,
        "end": 68751333,
        "type": "gneg"
      },
      {
        "id": "D3",
        "start": 68751334,
        "end": 77459835,
        "type": "gpos66"
      },
      {
        "id": "E1",
        "start": 77459836,
        "end": 83876626,
        "type": "gneg"
      },
      {
        "id": "E2",
        "start": 83876627,
        "end": 87085022,
        "type": "gpos33"
      },
      {
        "id": "E3",
        "start": 87085023,
        "end": 95793524,
        "type": "gneg"
      },
      {
        "id": "F1",
        "start": 95793525,
        "end": 101293631,
        "type": "gpos66"
      },
      {
        "id": "F2",
        "start": 101293632,
        "end": 102210316,
        "type": "gneg"
      },
      {
        "id": "F3",
        "start": 102210317,
        "end": 104043685,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1005301,
        "type": "tip"
      }
    ]
  },
  "16": {
    "size": 98207768,
    "bands": [
      {
        "id": "A1",
        "start": 2996602,
        "end": 15432649,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 15432650,
        "end": 16367961,
        "type": "gneg"
      },
      {
        "id": "A3",
        "start": 16367962,
        "end": 20576864,
        "type": "gpos33"
      },
      {
        "id": "B1",
        "start": 20576865,
        "end": 26188738,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 26188739,
        "end": 32268266,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 32268267,
        "end": 38347794,
        "type": "gneg"
      },
      {
        "id": "B4",
        "start": 38347795,
        "end": 44894979,
        "type": "gpos33"
      },
      {
        "id": "B5",
        "start": 44894980,
        "end": 53780444,
        "type": "gneg"
      },
      {
        "id": "C1.1",
        "start": 53780445,
        "end": 57989348,
        "type": "gpos66"
      },
      {
        "id": "C1.2",
        "start": 57989349,
        "end": 58924660,
        "type": "gneg"
      },
      {
        "id": "C1.3",
        "start": 58924661,
        "end": 66874813,
        "type": "gpos66"
      },
      {
        "id": "C2",
        "start": 66874814,
        "end": 70616061,
        "type": "gneg"
      },
      {
        "id": "C3.1",
        "start": 70616062,
        "end": 79033870,
        "type": "gpos100"
      },
      {
        "id": "C3.2",
        "start": 79033871,
        "end": 79501525,
        "type": "gneg"
      },
      {
        "id": "C3.3",
        "start": 79501526,
        "end": 91660583,
        "type": "gpos100"
      },
      {
        "id": "C4",
        "start": 91660584,
        "end": 98207768,
        "type": "gneg"
      },
      {
        "id": "cenp",
        "start": 998868,
        "end": 1997734,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1997735,
        "end": 2996601,
        "type": "acen"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 998867,
        "type": "tip"
      }
    ]
  },
  "17": {
    "size": 94987271,
    "bands": [
      {
        "id": "A1",
        "start": 2991014,
        "end": 13943085,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 13943086,
        "end": 16121691,
        "type": "gneg"
      },
      {
        "id": "A3.1",
        "start": 16121692,
        "end": 17428856,
        "type": "gpos33"
      },
      {
        "id": "A3.2",
        "start": 17428857,
        "end": 21786070,
        "type": "gneg"
      },
      {
        "id": "A3.3",
        "start": 21786071,
        "end": 31371942,
        "type": "gpos66"
      },
      {
        "id": "B1",
        "start": 31371943,
        "end": 40086370,
        "type": "gneg"
      },
      {
        "id": "B2",
        "start": 40086371,
        "end": 41393535,
        "type": "gpos33"
      },
      {
        "id": "B3",
        "start": 41393536,
        "end": 45750749,
        "type": "gneg"
      },
      {
        "id": "C",
        "start": 45750750,
        "end": 55772342,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 997005,
        "end": 1994009,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1994010,
        "end": 2991013,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 55772343,
        "end": 60129556,
        "type": "gneg"
      },
      {
        "id": "E1.1",
        "start": 60129557,
        "end": 67972542,
        "type": "gpos100"
      },
      {
        "id": "E1.2",
        "start": 67972543,
        "end": 68843984,
        "type": "gneg"
      },
      {
        "id": "E1.3",
        "start": 68843985,
        "end": 73201199,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 73201200,
        "end": 78429856,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 78429857,
        "end": 82787070,
        "type": "gpos33"
      },
      {
        "id": "E4",
        "start": 82787071,
        "end": 88887170,
        "type": "gneg"
      },
      {
        "id": "E5",
        "start": 88887171,
        "end": 94987271,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 997004,
        "type": "tip"
      }
    ]
  },
  "18": {
    "size": 90702639,
    "bands": [
      {
        "id": "A1",
        "start": 2997707,
        "end": 19406145,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 19406146,
        "end": 29531091,
        "type": "gneg"
      },
      {
        "id": "B1",
        "start": 29531092,
        "end": 35437309,
        "type": "gpos66"
      },
      {
        "id": "B2",
        "start": 35437310,
        "end": 37124800,
        "type": "gneg"
      },
      {
        "id": "B3",
        "start": 37124801,
        "end": 45562255,
        "type": "gpos100"
      },
      {
        "id": "C",
        "start": 45562256,
        "end": 49780983,
        "type": "gneg"
      },
      {
        "id": "cenp",
        "start": 999236,
        "end": 1998471,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 1998472,
        "end": 2997706,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 49780984,
        "end": 53999710,
        "type": "gpos100"
      },
      {
        "id": "D2",
        "start": 53999711,
        "end": 54421582,
        "type": "gneg"
      },
      {
        "id": "D3",
        "start": 54421583,
        "end": 60749673,
        "type": "gpos100"
      },
      {
        "id": "E1",
        "start": 60749674,
        "end": 67921510,
        "type": "gneg"
      },
      {
        "id": "E2",
        "start": 67921511,
        "end": 75093346,
        "type": "gpos33"
      },
      {
        "id": "E3",
        "start": 75093347,
        "end": 83530801,
        "type": "gneg"
      },
      {
        "id": "E4",
        "start": 83530802,
        "end": 90702639,
        "type": "gpos33"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 999235,
        "type": "tip"
      }
    ]
  },
  "19": {
    "size": 61431566,
    "bands": [
      {
        "id": "A",
        "start": 3004360,
        "end": 16680093,
        "type": "gpos100"
      },
      {
        "id": "B",
        "start": 16680094,
        "end": 25630388,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 25630389,
        "end": 34987514,
        "type": "gpos66"
      },
      {
        "id": "C2",
        "start": 34987515,
        "end": 38242166,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 38242167,
        "end": 47599292,
        "type": "gpos66"
      },
      {
        "id": "cenp",
        "start": 1001454,
        "end": 2002906,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2002907,
        "end": 3004359,
        "type": "acen"
      },
      {
        "id": "D1",
        "start": 47599293,
        "end": 51667607,
        "type": "gneg"
      },
      {
        "id": "D2",
        "start": 51667608,
        "end": 58990576,
        "type": "gpos33"
      },
      {
        "id": "D3",
        "start": 58990577,
        "end": 61431566,
        "type": "gneg"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1001453,
        "type": "tip"
      }
    ]
  },
  "X": {
    "size": 171031299,
    "bands": [
      {
        "id": "A1.1",
        "start": 3078866,
        "end": 15772338,
        "type": "gpos100"
      },
      {
        "id": "A1.2",
        "start": 15772339,
        "end": 18236766,
        "type": "gneg"
      },
      {
        "id": "A1.3",
        "start": 18236767,
        "end": 21194079,
        "type": "gpos33"
      },
      {
        "id": "A2",
        "start": 21194080,
        "end": 28094478,
        "type": "gneg"
      },
      {
        "id": "A3.1",
        "start": 28094479,
        "end": 33516219,
        "type": "gpos66"
      },
      {
        "id": "A3.2",
        "start": 33516220,
        "end": 34501990,
        "type": "gneg"
      },
      {
        "id": "A3.3",
        "start": 34501991,
        "end": 39923731,
        "type": "gpos66"
      },
      {
        "id": "A4",
        "start": 39923732,
        "end": 47809901,
        "type": "gneg"
      },
      {
        "id": "A5",
        "start": 47809902,
        "end": 56188956,
        "type": "gpos66"
      },
      {
        "id": "A6",
        "start": 56188957,
        "end": 63089355,
        "type": "gneg"
      },
      {
        "id": "A7.1",
        "start": 63089356,
        "end": 69496866,
        "type": "gpos66"
      },
      {
        "id": "A7.2",
        "start": 69496868,
        "end": 70975524,
        "type": "gneg"
      },
      {
        "id": "A7.3",
        "start": 70975525,
        "end": 77383036,
        "type": "gpos66"
      },
      {
        "id": "B",
        "start": 77383037,
        "end": 82311892,
        "type": "gneg"
      },
      {
        "id": "C1",
        "start": 82311893,
        "end": 91183833,
        "type": "gpos100"
      },
      {
        "id": "C2",
        "start": 91183834,
        "end": 92169603,
        "type": "gneg"
      },
      {
        "id": "C3",
        "start": 92169604,
        "end": 101041544,
        "type": "gpos100"
      },
      {
        "id": "cenp",
        "start": 1026289,
        "end": 2052577,
        "type": "acen"
      },
      {
        "id": "cenq",
        "start": 2052578,
        "end": 3078865,
        "type": "acen"
      },
      {
        "id": "D",
        "start": 101041545,
        "end": 109913485,
        "type": "gneg"
      },
      {
        "id": "E1",
        "start": 109913486,
        "end": 120264082,
        "type": "gpos100"
      },
      {
        "id": "E2",
        "start": 120264084,
        "end": 121249853,
        "type": "gneg"
      },
      {
        "id": "E3",
        "start": 121249854,
        "end": 135050651,
        "type": "gpos100"
      },
      {
        "id": "F1",
        "start": 135050652,
        "end": 141458162,
        "type": "gneg"
      },
      {
        "id": "F2",
        "start": 141458163,
        "end": 148851447,
        "type": "gpos33"
      },
      {
        "id": "F3",
        "start": 148851448,
        "end": 156244730,
        "type": "gneg"
      },
      {
        "id": "F4",
        "start": 156244731,
        "end": 163638014,
        "type": "gpos33"
      },
      {
        "id": "F5",
        "start": 163638015,
        "end": 171031299,
        "type": "gneg"
      },
      {
        "id": "tip",
        "start": 1,
        "end": 1026288,
        "type": "tip"
      }
    ]
  },
  "Y": {
    "size": 91744698,
    "bands": [
      {
        "id": "A1",
        "start": 5,
        "end": 20642552,
        "type": "gpos100"
      },
      {
        "id": "A2",
        "start": 20642557,
        "end": 32684047,
        "type": "gpos66"
      },
      {
        "id": "B",
        "start": 32684053,
        "end": 45298941,
        "type": "gpos33"
      },
      {
        "id": "C1",
        "start": 45298947,
        "end": 54473414,
        "type": "gpos100"
      },
      {
        "id": "C2",
        "start": 54473420,
        "end": 61927667,
        "type": "gpos33"
      },
      {
        "id": "C3",
        "start": 61927673,
        "end": 72248949,
        "type": "gpos100"
      },
      {
        "id": "D",
        "start": 72248955,
        "end": 83143629,
        "type": "gpos33"
      },
      {
        "id": "E",
        "start": 83143635,
        "end": 91744698,
        "type": "gpos66"
      }
    ]
  }
};




/*
	Base.js, version 1.1
	Copyright 2006-2007, Dean Edwards
	License: http://www.opensource.org/licenses/mit-license.php
*/

var Base = function() {
	// dummy
};

Base.extend = function(_instance, _static) { // subclass
	var extend = Base.prototype.extend;
	
	// build the prototype
	Base._prototyping = true;
	var proto = new this;
	extend.call(proto, _instance);
	delete Base._prototyping;
	
	// create the wrapper for the constructor function
	//var constructor = proto.constructor.valueOf(); //-dean
	var constructor = proto.constructor;
	var klass = proto.constructor = function() {
		if (!Base._prototyping) {
			if (this._constructing || this.constructor == klass) { // instantiation
				this._constructing = true;
				constructor.apply(this, arguments);
				delete this._constructing;
			} else if (arguments[0] != null) { // casting
				return (arguments[0].extend || extend).call(arguments[0], proto);
			}
		}
	};
	
	// build the class interface
	klass.ancestor = this;
	klass.extend = this.extend;
	klass.forEach = this.forEach;
	klass.implement = this.implement;
	klass.prototype = proto;
	klass.toString = this.toString;
	klass.valueOf = function(type) {
		//return (type == "object") ? klass : constructor; //-dean
		return (type == "object") ? klass : constructor.valueOf();
	};
	extend.call(klass, _static);
	// class initialisation
	if (typeof klass.init == "function") klass.init();
	return klass;
};

Base.prototype = {	
	extend: function(source, value) {
		if (arguments.length > 1) { // extending with a name/value pair
			var ancestor = this[source];
			if (ancestor && (typeof value == "function") && // overriding a method?
				// the valueOf() comparison is to avoid circular references
				(!ancestor.valueOf || ancestor.valueOf() != value.valueOf()) &&
				/\bbase\b/.test(value)) {
				// get the underlying method
				var method = value.valueOf();
				// override
				value = function() {
					var previous = this.base || Base.prototype.base;
					this.base = ancestor;
					var returnValue = method.apply(this, arguments);
					this.base = previous;
					return returnValue;
				};
				// point to the underlying method
				value.valueOf = function(type) {
					return (type == "object") ? value : method;
				};
				value.toString = Base.toString;
			}
			this[source] = value;
		} else if (source) { // extending with an object literal
			var extend = Base.prototype.extend;
			// if this object has a customised extend method then use it
			if (!Base._prototyping && typeof this != "function") {
				extend = this.extend || extend;
			}
			var proto = {toSource: null};
			// do the "toString" and other methods manually
			var hidden = ["constructor", "toString", "valueOf"];
			// if we are prototyping then include the constructor
			var i = Base._prototyping ? 0 : 1;
			while (key = hidden[i++]) {
				if (source[key] != proto[key]) {
					extend.call(this, key, source[key]);

				}
			}
			// copy each of the source object's properties to this object
			for (var key in source) {
				if (!proto[key]) extend.call(this, key, source[key]);
			}
		}
		return this;
	},

	base: function() {
		// call this method from any other method to invoke that method's ancestor
	}
};

// initialise
Base = Base.extend({
	constructor: function() {
		this.extend(arguments[0]);
	}
}, {
	ancestor: Object,
	version: "1.1",
	
	forEach: function(object, block, context) {
		for (var key in object) {
			if (this.prototype[key] === undefined) {
				block.call(context, object[key], key, object);
			}
		}
	},
		
	implement: function() {
		for (var i = 0; i < arguments.length; i++) {
			if (typeof arguments[i] == "function") {
				// if it's a function, call it
				arguments[i](this.prototype);
			} else {
				// add the interface using the extend method
				this.prototype.extend(arguments[i]);
			}
		}
		return this;
	},
	
	toString: function() {
		return String(this.valueOf());
	}
});




/****************************************************************************** 
	rtree.js - General-Purpose Non-Recursive Javascript R-Tree Library
	Version 0.6.2, December 5st 2009

  Copyright (c) 2009 Jon-Carlos Rivera
  
  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:
  
  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	Jon-Carlos Rivera - imbcmdth@hotmail.com
******************************************************************************/

/**
 * RTree - A simple r-tree structure for great results.
 * @constructor
 */
var RTree = function(width){
	// Variables to control tree-dimensions
	var _Min_Width = 3;  // Minimum width of any node before a merge
	var _Max_Width = 6;  // Maximum width of any node before a split
	if(!isNaN(width)){ _Min_Width = Math.floor(width/2.0); _Max_Width = width;}
	// Start with an empty root-tree
	var _T = {x:0, y:0, w:0, h:0, id:"root", nodes:[] };
    
	var isArray = function(o) {
		return Object.prototype.toString.call(o) === '[object Array]'; 
	};

	/* @function
	 * @description Function to generate unique strings for element IDs
	 * @param {String} n			The prefix to use for the IDs generated.
	 * @return {String}				A guarenteed unique ID.
	 */
    var _name_to_id = (function() {
        // hide our idCache inside this closure
        var idCache = {};

        // return the api: our function that returns a unique string with incrementing number appended to given idPrefix
        return function(idPrefix) {
            var idVal = 0;
            if(idPrefix in idCache) {
                idVal = idCache[idPrefix]++;
            } else {
                idCache[idPrefix] = 0;
            }
            return idPrefix + "_" + idVal;
        }
    })();

	// This is my special addition to the world of r-trees
	// every other (simple) method I found produced crap trees
	// this skews insertions to prefering squarer and emptier nodes
	RTree.Rectangle.squarified_ratio = function(l, w, fill) {
	  // Area of new enlarged rectangle
	  var lperi = (l + w) / 2.0; // Average size of a side of the new rectangle
	  var larea = l * w; // Area of new rectangle
	  // return the ratio of the perimeter to the area - the closer to 1 we are, 
	  // the more "square" a rectangle is. conversly, when approaching zero the 
	  // more elongated a rectangle is
	  var lgeo = larea / (lperi*lperi);
	  return(larea * fill / lgeo); 
	};
	
	/* find the best specific node(s) for object to be deleted from
	 * [ leaf node parent ] = _remove_subtree(rectangle, object, root)
	 * @private
	 */
	var _remove_subtree = function(rect, obj, root) {
		var hit_stack = []; // Contains the elements that overlap
		var count_stack = []; // Contains the elements that overlap
		var ret_array = [];
		var current_depth = 1;
		
		if(!rect || !RTree.Rectangle.overlap_rectangle(rect, root))
		 return ret_array;

		var ret_obj = {x:rect.x, y:rect.y, w:rect.w, h:rect.h, target:obj};
		
		count_stack.push(root.nodes.length);
		hit_stack.push(root);

		do {
			var tree = hit_stack.pop();
			var i = count_stack.pop()-1;
			
		  if("target" in ret_obj) { // We are searching for a target
				while(i >= 0)	{
					var ltree = tree.nodes[i];
					if(RTree.Rectangle.overlap_rectangle(ret_obj, ltree)) {
						if( (ret_obj.target && "leaf" in ltree && ltree.leaf === ret_obj.target)
							||(!ret_obj.target && ("leaf" in ltree || RTree.Rectangle.contains_rectangle(ltree, ret_obj)))) { // A Match !!
				  		// Yup we found a match...
				  		// we can cancel search and start walking up the list
				  		if("nodes" in ltree) {// If we are deleting a node not a leaf...
				  			ret_array = _search_subtree(ltree, true, [], ltree);
				  			tree.nodes.splice(i, 1); 
				  		} else {
								ret_array = tree.nodes.splice(i, 1); 
							}
							// Resize MBR down...
							RTree.Rectangle.make_MBR(tree.nodes, tree);
							delete ret_obj.target;
							if(tree.nodes.length < _Min_Width) { // Underflow
								ret_obj.nodes = _search_subtree(tree, true, [], tree);
							}
							break;
			  		}/*	else if("load" in ltree) { // A load
				  	}*/	else if("nodes" in ltree) { // Not a Leaf
				  		current_depth += 1;
				  		count_stack.push(i);
				  		hit_stack.push(tree);
				  		tree = ltree;
				  		i = ltree.nodes.length;
				  	}
				  }
					i -= 1;
				}
			} else if("nodes" in ret_obj) { // We are unsplitting
				tree.nodes.splice(i+1, 1); // Remove unsplit node
				// ret_obj.nodes contains a list of elements removed from the tree so far
				if(tree.nodes.length > 0)
					RTree.Rectangle.make_MBR(tree.nodes, tree);
				for(var t = 0;t<ret_obj.nodes.length;t++)
					_insert_subtree(ret_obj.nodes[t], tree);
				ret_obj.nodes.length = 0;
				if(hit_stack.length == 0 && tree.nodes.length <= 1) { // Underflow..on root!
					ret_obj.nodes = _search_subtree(tree, true, ret_obj.nodes, tree);
					tree.nodes.length = 0;
					hit_stack.push(tree);
					count_stack.push(1);
				} else if(hit_stack.length > 0 && tree.nodes.length < _Min_Width) { // Underflow..AGAIN!
					ret_obj.nodes = _search_subtree(tree, true, ret_obj.nodes, tree);
					tree.nodes.length = 0;						
				}else {
					delete ret_obj.nodes; // Just start resizing
				}
			} else { // we are just resizing
				RTree.Rectangle.make_MBR(tree.nodes, tree);
			}
			current_depth -= 1;
		}while(hit_stack.length > 0);
		
		return(ret_array);
	};

	/* choose the best damn node for rectangle to be inserted into
	 * [ leaf node parent ] = _choose_leaf_subtree(rectangle, root to start search at)
	 * @private
	 */
	var _choose_leaf_subtree = function(rect, root) {
		var best_choice_index = -1;
		var best_choice_stack = [];
		var best_choice_area;
		
		var load_callback = function(local_tree, local_node){
			return(function(data) { 
				local_tree._attach_data(local_node, data);
			});
		};
	
		best_choice_stack.push(root);
		var nodes = root.nodes;	

		do {	
			if(best_choice_index != -1)	{
				best_choice_stack.push(nodes[best_choice_index]);
				nodes = nodes[best_choice_index].nodes;
				best_choice_index = -1;
			}
	
			for(var i = nodes.length-1; i >= 0; i--) {
				var ltree = nodes[i];
				if("leaf" in ltree) {  
					// Bail out of everything and start inserting
					best_choice_index = -1;
					break;
			  } /*else if(ltree.load) {
  				throw( "Can't insert into partially loaded tree ... yet!");
  				//jQuery.getJSON(ltree.load, load_callback(this, ltree));
  				//delete ltree.load;
  			}*/
			  // Area of new enlarged rectangle
			  var old_lratio = RTree.Rectangle.squarified_ratio(ltree.w, ltree.h, ltree.nodes.length+1);

			  // Enlarge rectangle to fit new rectangle
			  var nw = Math.max(ltree.x+ltree.w, rect.x+rect.w) - Math.min(ltree.x, rect.x);
			  var nh = Math.max(ltree.y+ltree.h, rect.y+rect.h) - Math.min(ltree.y, rect.y);
			  
			  // Area of new enlarged rectangle
			  var lratio = RTree.Rectangle.squarified_ratio(nw, nh, ltree.nodes.length+2);
			  
			  if(best_choice_index < 0 || Math.abs(lratio - old_lratio) < best_choice_area) {
			  	best_choice_area = Math.abs(lratio - old_lratio); best_choice_index = i;
			  }
			}
		}while(best_choice_index != -1);

		return(best_choice_stack);
	};

	/* split a set of nodes into two roughly equally-filled nodes
	 * [ an array of two new arrays of nodes ] = linear_split(array of nodes)
	 * @private
	 */
	var _linear_split = function(nodes) {
		var n = _pick_linear(nodes);
		while(nodes.length > 0)	{
			_pick_next(nodes, n[0], n[1]);
		}
		return(n);
	};
	
	/* insert the best source rectangle into the best fitting parent node: a or b
	 * [] = pick_next(array of source nodes, target node array a, target node array b)
	 * @private
	 */
	var _pick_next = function(nodes, a, b) {
	  // Area of new enlarged rectangle
		var area_a = RTree.Rectangle.squarified_ratio(a.w, a.h, a.nodes.length+1);
		var area_b = RTree.Rectangle.squarified_ratio(b.w, b.h, b.nodes.length+1);
		var high_area_delta;
		var high_area_node;
		var lowest_growth_group;
		
		for(var i = nodes.length-1; i>=0;i--) {
			var l = nodes[i];
			var new_area_a = {};
			new_area_a.x = Math.min(a.x, l.x); new_area_a.y = Math.min(a.y, l.y);
			new_area_a.w = Math.max(a.x+a.w, l.x+l.w) - new_area_a.x;	new_area_a.h = Math.max(a.y+a.h, l.y+l.h) - new_area_a.y;
			var change_new_area_a = Math.abs(RTree.Rectangle.squarified_ratio(new_area_a.w, new_area_a.h, a.nodes.length+2) - area_a);
	
			var new_area_b = {};
			new_area_b.x = Math.min(b.x, l.x); new_area_b.y = Math.min(b.y, l.y);
			new_area_b.w = Math.max(b.x+b.w, l.x+l.w) - new_area_b.x;	new_area_b.h = Math.max(b.y+b.h, l.y+l.h) - new_area_b.y;
			var change_new_area_b = Math.abs(RTree.Rectangle.squarified_ratio(new_area_b.w, new_area_b.h, b.nodes.length+2) - area_b);

			if( !high_area_node || !high_area_delta || Math.abs( change_new_area_b - change_new_area_a ) < high_area_delta ) {
				high_area_node = i;
				high_area_delta = Math.abs(change_new_area_b-change_new_area_a);
				lowest_growth_group = change_new_area_b < change_new_area_a ? b : a;
			}
		}
		var temp_node = nodes.splice(high_area_node, 1)[0];
		if(a.nodes.length + nodes.length + 1 <= _Min_Width)	{
			a.nodes.push(temp_node);
			RTree.Rectangle.expand_rectangle(a, temp_node);
		}	else if(b.nodes.length + nodes.length + 1 <= _Min_Width) {
			b.nodes.push(temp_node);
			RTree.Rectangle.expand_rectangle(b, temp_node);
		}
		else {
			lowest_growth_group.nodes.push(temp_node);
			RTree.Rectangle.expand_rectangle(lowest_growth_group, temp_node);
		}
	};

	/* pick the "best" two starter nodes to use as seeds using the "linear" criteria
	 * [ an array of two new arrays of nodes ] = pick_linear(array of source nodes)
	 * @private
	 */
	var _pick_linear = function(nodes) {
		var lowest_high_x = nodes.length-1;
		var highest_low_x = 0;
		var lowest_high_y = nodes.length-1;
		var highest_low_y = 0;
        var t1, t2;
		
		for(var i = nodes.length-2; i>=0;i--)	{
			var l = nodes[i];
			if(l.x > nodes[highest_low_x].x ) highest_low_x = i;
			else if(l.x+l.w < nodes[lowest_high_x].x+nodes[lowest_high_x].w) lowest_high_x = i;
			if(l.y > nodes[highest_low_y].y ) highest_low_y = i;
			else if(l.y+l.h < nodes[lowest_high_y].y+nodes[lowest_high_y].h) lowest_high_y = i;
		}
		var dx = Math.abs((nodes[lowest_high_x].x+nodes[lowest_high_x].w) - nodes[highest_low_x].x);
		var dy = Math.abs((nodes[lowest_high_y].y+nodes[lowest_high_y].h) - nodes[highest_low_y].y);
		if( dx > dy )	{ 
			if(lowest_high_x > highest_low_x)	{
				t1 = nodes.splice(lowest_high_x, 1)[0];
				t2 = nodes.splice(highest_low_x, 1)[0];
			}	else {
				t2 = nodes.splice(highest_low_x, 1)[0];
				t1 = nodes.splice(lowest_high_x, 1)[0];
			}
		}	else {
			if(lowest_high_y > highest_low_y)	{
				t1 = nodes.splice(lowest_high_y, 1)[0];
				t2 = nodes.splice(highest_low_y, 1)[0];
			}	else {
				t2 = nodes.splice(highest_low_y, 1)[0];
				t1 = nodes.splice(lowest_high_y, 1)[0];
			}
		}
		return([{x:t1.x, y:t1.y, w:t1.w, h:t1.h, nodes:[t1]},
			      {x:t2.x, y:t2.y, w:t2.w, h:t2.h, nodes:[t2]} ]);
	};
	
	var _attach_data = function(node, more_tree){
		node.nodes = more_tree.nodes;
		node.x = more_tree.x; node.y = more_tree.y;
		node.w = more_tree.w; node.h = more_tree.h;
		return(node);
	};

	/* non-recursive internal search function 
	 * [ nodes | objects ] = _search_subtree(rectangle, [return node data], [array to fill], root to begin search at)
	 * @private
	 */
	var _search_subtree = function(rect, return_node, return_array, root) {
		var hit_stack = []; // Contains the elements that overlap
	
		if(!RTree.Rectangle.overlap_rectangle(rect, root))
		 return(return_array);
	
		var load_callback = function(local_tree, local_node){
			return(function(data) { 
				local_tree._attach_data(local_node, data);
			});
		};
	
		hit_stack.push(root.nodes);
	
		do {
			var nodes = hit_stack.pop();
	
			for(var i = nodes.length-1; i >= 0; i--) {
				var ltree = nodes[i];
			  if(RTree.Rectangle.overlap_rectangle(rect, ltree)) {
			  	if("nodes" in ltree) { // Not a Leaf
			  		hit_stack.push(ltree.nodes);
			  	} else if("leaf" in ltree) { // A Leaf !!
			  		if(!return_node)
		  				return_array.push(ltree.leaf);
		  			else
		  				return_array.push(ltree);
		  		}/*	else if("load" in ltree) { // We need to fetch a URL for some more tree data
	  				jQuery.getJSON(ltree.load, load_callback(this, ltree));
	  				delete ltree.load;
	  			//	i++; // Replay this entry
	  			}*/
				}
			}
		}while(hit_stack.length > 0);
		
		return(return_array);
	};
	
	/* non-recursive internal insert function
	 * [] = _insert_subtree(rectangle, object to insert, root to begin insertion at)
	 * @private
	 */
	var _insert_subtree = function(node, root) {
		var bc; // Best Current node
		// Initial insertion is special because we resize the Tree and we don't
		// care about any overflow (seriously, how can the first object overflow?)
		if(root.nodes.length == 0) {
			root.x = node.x; root.y = node.y;
			root.w = node.w; root.h = node.h;
			root.nodes.push(node);
			return;
		}
		
		// Find the best fitting leaf node
		// choose_leaf returns an array of all tree levels (including root)
		// that were traversed while trying to find the leaf
		var tree_stack = _choose_leaf_subtree(node, root);
		var ret_obj = node;//{x:rect.x,y:rect.y,w:rect.w,h:rect.h, leaf:obj};
	
		// Walk back up the tree resizing and inserting as needed
		do {
			//handle the case of an empty node (from a split)
			if(bc && "nodes" in bc && bc.nodes.length == 0) {
				var pbc = bc; // Past bc
				bc = tree_stack.pop();
				for(var t=0;t<bc.nodes.length;t++)
					if(bc.nodes[t] === pbc || bc.nodes[t].nodes.length == 0) {
						bc.nodes.splice(t, 1);
						break;
				}
			} else {
				bc = tree_stack.pop();
			}
			
			// If there is data attached to this ret_obj
			if("leaf" in ret_obj || "nodes" in ret_obj || isArray(ret_obj)) { 
				// Do Insert
				if(isArray(ret_obj)) {
					for(var ai = 0; ai < ret_obj.length; ai++) {
						RTree.Rectangle.expand_rectangle(bc, ret_obj[ai]);
					}
					bc.nodes = bc.nodes.concat(ret_obj); 
				} else {
					RTree.Rectangle.expand_rectangle(bc, ret_obj);
					bc.nodes.push(ret_obj); // Do Insert
				}
	
				if(bc.nodes.length <= _Max_Width)	{ // Start Resizeing Up the Tree
					ret_obj = {x:bc.x,y:bc.y,w:bc.w,h:bc.h};
				}	else { // Otherwise Split this Node
					// linear_split() returns an array containing two new nodes
					// formed from the split of the previous node's overflow
					var a = _linear_split(bc.nodes);
					ret_obj = a;//[1];
					
					if(tree_stack.length < 1)	{ // If are splitting the root..
						bc.nodes.push(a[0]);
						tree_stack.push(bc);     // Reconsider the root element
						ret_obj = a[1];
					} /*else {
						delete bc;
					}*/
				}
			}	else { // Otherwise Do Resize
				//Just keep applying the new bounding rectangle to the parents..
				RTree.Rectangle.expand_rectangle(bc, ret_obj);
				ret_obj = {x:bc.x,y:bc.y,w:bc.w,h:bc.h};
			}
		} while(tree_stack.length > 0);
	};

	/* quick 'n' dirty function for plugins or manually drawing the tree
	 * [ tree ] = RTree.get_tree(): returns the raw tree data. useful for adding
	 * @public
	 * !! DEPRECATED !!
	 */
	this.get_tree = function() {
		return _T;
	};
	
	/* quick 'n' dirty function for plugins or manually loading the tree
	 * [ tree ] = RTree.set_tree(sub-tree, where to attach): returns the raw tree data. useful for adding
	 * @public
	 * !! DEPRECATED !!
	 */
	this.set_tree = function(new_tree, where) {
		if(!where)
			where = _T;
		return(_attach_data(where, new_tree));
	};
	
	/* non-recursive search function 
	 * [ nodes | objects ] = RTree.search(rectangle, [return node data], [array to fill])
	 * @public
	 */
	this.search = function(rect, return_node, return_array) {
		if(arguments.length < 1)
			throw "Wrong number of arguments. RT.Search requires at least a bounding rectangle."

		switch(arguments.length) {
			case 1:
				arguments[1] = false;// Add an "return node" flag - may be removed in future
			case 2:
				arguments[2] = []; // Add an empty array to contain results
			case 3:
				arguments[3] = _T; // Add root node to end of argument list
			default:
				arguments.length = 4;
		}
		return(_search_subtree.apply(this, arguments));
	};
		
	/* partially-recursive toJSON function
	 * [ string ] = RTree.toJSON([rectangle], [tree])
	 * @public
	 */
	this.toJSON = function(rect, tree) {
		var hit_stack = []; // Contains the elements that overlap
		var count_stack = []; // Contains the elements that overlap
		var return_stack = {}; // Contains the elements that overlap
		var max_depth = 3;  // This triggers recursion and tree-splitting
		var current_depth = 1;
		var return_string = "";
		
		if(rect && !RTree.Rectangle.overlap_rectangle(rect, _T))
		 return "";
		
		if(!tree)	{
			count_stack.push(_T.nodes.length);
			hit_stack.push(_T.nodes);
			return_string += "var main_tree = {x:"+_T.x.toFixed()+",y:"+_T.y.toFixed()+",w:"+_T.w.toFixed()+",h:"+_T.h.toFixed()+",nodes:[";
		}	else {
			max_depth += 4;
			count_stack.push(tree.nodes.length);
			hit_stack.push(tree.nodes);
			return_string += "var main_tree = {x:"+tree.x.toFixed()+",y:"+tree.y.toFixed()+",w:"+tree.w.toFixed()+",h:"+tree.h.toFixed()+",nodes:[";
		}
	
		do {
			var nodes = hit_stack.pop();
			var i = count_stack.pop()-1;
			
			if(i >= 0 && i < nodes.length-1)
				return_string += ",";
				
			while(i >= 0)	{
				var ltree = nodes[i];
			  if(!rect || RTree.Rectangle.overlap_rectangle(rect, ltree)) {
			  	if(ltree.nodes) { // Not a Leaf
			  		if(current_depth >= max_depth) {
			  			var len = return_stack.length;
			  			var nam = _name_to_id("saved_subtree");
			  			return_string += "{x:"+ltree.x.toFixed()+",y:"+ltree.y.toFixed()+",w:"+ltree.w.toFixed()+",h:"+ltree.h.toFixed()+",load:'"+nam+".js'}";
			  			return_stack[nam] = this.toJSON(rect, ltree);
							if(i > 0)
								return_string += ","
			  		}	else {
				  		return_string += "{x:"+ltree.x.toFixed()+",y:"+ltree.y.toFixed()+",w:"+ltree.w.toFixed()+",h:"+ltree.h.toFixed()+",nodes:[";
				  		current_depth += 1;
				  		count_stack.push(i);
				  		hit_stack.push(nodes);
				  		nodes = ltree.nodes;
				  		i = ltree.nodes.length;
				  	}
			  	}	else if(ltree.leaf) { // A Leaf !!
			  		var data = ltree.leaf.toJSON ? ltree.leaf.toJSON() : JSON.stringify(ltree.leaf);
		  			return_string += "{x:"+ltree.x.toFixed()+",y:"+ltree.y.toFixed()+",w:"+ltree.w.toFixed()+",h:"+ltree.h.toFixed()+",leaf:" + data + "}";
						if(i > 0)
							return_string += ","
		  		}	else if(ltree.load) { // A load
		  			return_string += "{x:"+ltree.x.toFixed()+",y:"+ltree.y.toFixed()+",w:"+ltree.w.toFixed()+",h:"+ltree.h.toFixed()+",load:'" + ltree.load + "'}";
						if(i > 0)
							return_string += ","
			  	}
				}
				i -= 1;
			}
			if(i < 0)	{
					return_string += "]}"; current_depth -= 1;
			}
		}while(hit_stack.length > 0);
		
		return_string+=";";
		
		for(var my_key in return_stack) {
			return_string += "\nvar " + my_key + " = function(){" + return_stack[my_key] + " return(main_tree);};";
		}
		return(return_string);
	};
	
	/* non-recursive function that deletes a specific
	 * [ number ] = RTree.remove(rectangle, obj)
	 */
	this.remove = function(rect, obj) {
		if(arguments.length < 1)
			throw "Wrong number of arguments. RT.remove requires at least a bounding rectangle."

		switch(arguments.length) {
			case 1:
				arguments[1] = false; // obj == false for conditionals
			case 2:
				arguments[2] = _T; // Add root node to end of argument list
			default:
				arguments.length = 3;
		}
		if(arguments[1] === false) { // Do area-wide delete
			var numberdeleted = 0;
			var ret_array = [];
			do { 
				numberdeleted=ret_array.length; 
				ret_array = ret_array.concat(_remove_subtree.apply(this, arguments));
			}while( numberdeleted !=  ret_array.length);
			return ret_array;
		}
		else { // Delete a specific item
			return(_remove_subtree.apply(this, arguments));
		}
	};
		
	/* non-recursive insert function
	 * [] = RTree.insert(rectangle, object to insert)
	 */
	this.insert = function(rect, obj) {
		if(arguments.length < 2)
			throw "Wrong number of arguments. RT.Insert requires at least a bounding rectangle and an object."
		
		return(_insert_subtree({x:rect.x,y:rect.y,w:rect.w,h:rect.h,leaf:obj}, _T));
	};
	
	/* non-recursive delete function
	 * [deleted object] = RTree.remove(rectangle, [object to delete])
	 */

//End of RTree
};

/* Rectangle - Generic rectangle object - Not yet used */

RTree.Rectangle = function(ix, iy, iw, ih) { // new Rectangle(bounds) or new Rectangle(x, y, w, h)
    var x, x2, y, y2, w, h;

    if(ix.x) {
		x = ix.x; y = ix.y;	
			if(ix.w !== 0 && !ix.w && ix.x2){
				w = ix.x2-ix.x;	h = ix.y2-ix.y;
			}	else {
				w = ix.w;	h = ix.h;
			}
		x2 = x + w; y2 = y + h; // For extra fastitude
	} else {
		x = ix; y = iy;	w = iw;	h = ih;
		x2 = x + w; y2 = y + h; // For extra fastitude
	}

	this.x1 = this.x = function(){return x;};
	this.y1 = this.y = function(){return y;};
	this.x2 = function(){return x2;};
	this.y2 = function(){return y2;};		
	this.w = function(){return w;};
	this.h = function(){return h;};
	
	this.toJSON = function() {
		return('{"x":'+x.toString()+', "y":'+y.toString()+', "w":'+w.toString()+', "h":'+h.toString()+'}');
	};
	
	this.overlap = function(a) {
		return(this.x() < a.x2() && this.x2() > a.x() && this.y() < a.y2() && this.y2() > a.y());
	};
	
	this.expand = function(a) {
		var nx = Math.min(this.x(), a.x());
		var ny = Math.min(this.y(), a.y());
		w = Math.max(this.x2(), a.x2()) - nx;
		h = Math.max(this.y2(), a.y2()) - ny;
		x = nx; y = ny;
		return(this);
	};
	
	this.setRect = function(ix, iy, iw, ih) {
        var x, x2, y, y2, w, h;
		if(ix.x) {
			x = ix.x; y = ix.y;	
			if(ix.w !== 0 && !ix.w && ix.x2) {
				w = ix.x2-ix.x;	h = ix.y2-ix.y;
			}	else {
				w = ix.w;	h = ix.h;
			}
			x2 = x + w; y2 = y + h; // For extra fastitude
		} else {
			x = ix; y = iy;	w = iw;	h = ih;
			x2 = x + w; y2 = y + h; // For extra fastitude
		}
	};
//End of RTree.Rectangle
};


/* returns true if rectangle 1 overlaps rectangle 2
 * [ boolean ] = overlap_rectangle(rectangle a, rectangle b)
 * @static function
 */
RTree.Rectangle.overlap_rectangle = function(a, b) {
	return(a.x < (b.x+b.w) && (a.x+a.w) > b.x && a.y < (b.y+b.h) && (a.y+a.h) > b.y);
};

/* returns true if rectangle a is contained in rectangle b
 * [ boolean ] = contains_rectangle(rectangle a, rectangle b)
 * @static function
 */
RTree.Rectangle.contains_rectangle = function(a, b) {
	return((a.x+a.w) <= (b.x+b.w) && a.x >= b.x && (a.y+a.h) <= (b.y+b.h) && a.y >= b.y);
};

/* expands rectangle A to include rectangle B, rectangle B is untouched
 * [ rectangle a ] = expand_rectangle(rectangle a, rectangle b)
 * @static function
 */
RTree.Rectangle.expand_rectangle = function(a, b)	{
	var nx = Math.min(a.x, b.x);
	var ny = Math.min(a.y, b.y);
	a.w = Math.max(a.x+a.w, b.x+b.w) - nx;
	a.h = Math.max(a.y+a.h, b.y+b.h) - ny;
	a.x = nx; a.y = ny;
	return(a);
};

/* generates a minimally bounding rectangle for all rectangles in
 * array "nodes". If rect is set, it is modified into the MBR. Otherwise,
 * a new rectangle is generated and returned.
 * [ rectangle a ] = make_MBR(rectangle array nodes, rectangle rect)
 * @static function
 */
RTree.Rectangle.make_MBR = function(nodes, rect) {
	if(nodes.length < 1)
		return({x:0, y:0, w:0, h:0});
		//throw "make_MBR: nodes must contain at least one rectangle!";
	if(!rect)
		rect = {x:nodes[0].x, y:nodes[0].y, w:nodes[0].w, h:nodes[0].h};
	else
		rect.x = nodes[0].x; rect.y = nodes[0].y; rect.w = nodes[0].w; rect.h = nodes[0].h;
		
	for(var i = nodes.length-1; i>0; i--)
		RTree.Rectangle.expand_rectangle(rect, nodes[i]);
		
	return(rect);
};



var $         = jQuery; // Make sure we have local $ (this is for combined script in a function)
var Genoverse = Base.extend({
  // Defaults
  urlParamTemplate   : 'r=__CHR__:__START__-__END__', // Overwrite this for your URL style
  width              : 1000,
  height             : 200,
  labelWidth         : 90,
  buffer             : 1,
  longestLabel       : 30,
  defaultLength      : 5000,
  defaultScrollDelta : 100,
  tracks             : [],
  plugins            : [],
  dragAction         : 'scroll', // options are: scroll, select, off
  wheelAction        : 'off',    // options are: zoom, off
  genome             : undefined,
  autoHideMessages   : true,
  trackAutoHeight    : false,
  colors             : {
    background       : '#FFFFFF',
    majorGuideLine   : '#CCCCCC',
    minorGuideLine   : '#E5E5E5',
    sortHandle       : '#CFD4E7'
  },

  // Default coordinates for initial view, overwrite in your config
  chr   : 1,
  start : 1,
  end   : 1000000,

  constructor: function (config) {
    var browser = this;
    
    if (!this.supported()) {
      return this.die('Your browser does not support this functionality');
    }
    
    config.container = $(config.container); // Make sure container is a jquery object, jquery recognises itself automatically
    
    if (!(config.container && config.container.length)) {
      config.container = $('<div id="genoverse">').appendTo('body');
    }

    $.extend(this, config);
    
    $.when(this.loadGenome(), this.loadPlugins()).always(function () {
      Genoverse.wrapFunctions(browser);
      browser.init();
    });
  },

  loadGenome: function () {
    if (typeof this.genome === 'string') {
      var genomeName = this.genome;
      
      return $.ajax({
        url      : this.origin + 'js/genomes/' + genomeName + '.js', 
        dataType : 'script',
        context  : this,
        success  : function () {
          try {
            this.genome = eval(genomeName);
          } catch (e) {
            console.log(e);
            this.die('Unable to load genome ' + genomeName);
          }
        }
      });
    }
  },

  loadPlugins: function () {
    if (typeof LazyLoad === 'undefined') {
      return;
    }
    
    var browser         = this;
    var loadPluginsTask = $.Deferred();
    
    // Load plugins css file
    $.when.apply($, $.map(browser.plugins, function (plugin) {
      var dfd = $.Deferred();
      
      LazyLoad.css(browser.origin + 'css/' + plugin + '.css', function () {
        $.ajax({
          url      : browser.origin + 'js/plugins/' + plugin + '.js',
          dataType : 'text',
          success  : dfd.resolve
        });
      });
      
      return dfd;
    })).done(function () {
      (function (jq, scripts) {
        // Localize variables
        var $ = jq;
        
        for (var i = 0; i < scripts.length; i++) {
          try {
            eval(scripts[i][0]);
          } catch (e) {
            // TODO: add plugin name to this message
            console.log('Error evaluating plugin script: ' + e);
            console.log(scripts[i][0]);
          }
        }
      })($, browser.plugins.length === 1 ? [ arguments ] : arguments);
    }).always(loadPluginsTask.resolve);
    
    return loadPluginsTask;
  },
  
  init: function () {
    var width = this.width;
    
    this.addDomElements(width);
    this.addUserEventHandlers();
    
    this.tracksById       = {};
    this.prev             = {};
    this.urlParamTemplate = this.urlParamTemplate || '';
    this.useHash          = typeof window.history.pushState !== 'function';
    this.textWidth        = document.createElement('canvas').getContext('2d').measureText('W').width;
    this.labelWidth       = this.labelContainer.outerWidth(true);
    this.wrapperLeft      = this.labelWidth - width;
    this.width           -= this.labelWidth;
    this.paramRegex       = this.urlParamTemplate ? new RegExp('([?&;])' + this.urlParamTemplate
      .replace(/(\b(\w+=)?__CHR__(.)?)/,   '$2([\\w\\.]+)$3')
      .replace(/(\b(\w+=)?__START__(.)?)/, '$2(\\d+)$3')
      .replace(/(\b(\w+=)?__END__(.)?)/,   '$2(\\d+)$3') + '([;&])'
    ) : '';
    
    var urlCoords = this.getURLCoords();
    var coords    = urlCoords.chr && urlCoords.start && urlCoords.end ? urlCoords : { chr: this.chr, start: this.start, end: this.end };
    
    this.chr = coords.chr;
    
    if (this.genome && !this.chromosomeSize) {
      this.chromosomeSize = this.genome[this.chr].size;
    }
    
    this.addTracks();
    this.setRange(coords.start, coords.end);
  },
  
  addDomElements: function (width) {
    var browser = this;
    
    this.menus          = $();
    this.labelContainer = $('<ul class="label_container">').appendTo(this.container).sortable({
      items       : 'li:not(.unsortable)',
      handle      : '.handle',
      placeholder : 'label',
      axis        : 'y',
      helper      : 'clone',
      cursor      : 'move',
      update      : $.proxy(this.updateTrackOrder, this),
      start       : function (e, ui) {
        ui.placeholder.css({ height: ui.item.height(), visibility: 'visible', background: browser.colors.sortHandle }).html(ui.item.html());
        ui.helper.hide();
      }
    });
    
    this.wrapper          = $('<div class="gv_wrapper">').appendTo(this.container);
    this.selector         = $('<div class="selector crosshair">').appendTo(this.wrapper);
    this.selectorControls = $(
      '<div class="selector_controls">'               +
      '  <button class="zoomHere">Zoom here</button>' +
      '  <button class="center">Center</button>'      +
      '  <button class="summary">Summary</button>'    +
      '  <button class="cancel">Cancel</button>'      +
      '</div>'
    ).appendTo(this.selector);
    
    this.zoomInHighlight = $(
      '<div class="canvas_zoom i">' +
      '  <div class="t l h"></div>' +
      '  <div class="t r h"></div>' +
      '  <div class="t l v"></div>' +
      '  <div class="t r v"></div>' +
      '  <div class="b l h"></div>' +
      '  <div class="b r h"></div>' +
      '  <div class="b l v"></div>' +
      '  <div class="b r v"></div>' +
      '</div>'
    ).appendTo('body');
    
    this.zoomOutHighlight = this.zoomInHighlight.clone().toggleClass('i o').appendTo('body');
    
    this.container.addClass('canvas_container').width(width);
  },
  
  addUserEventHandlers: function () {
    var browser = this;
    
    this.container.on({
      mousedown: function (e) {
        browser.hideMessages();

        // Only scroll on left click, and do nothing if clicking on a button in selectorControls
        if ((!e.which || e.which === 1) && !(this === browser.selector[0] && e.target !== this)) {
          browser.mousedown(e);
        }
        
        return false;
      },
      mousewheel: function (e, delta, deltaX, deltaY) {
        if (browser.noWheelZoom) {
          return true;
        }
        
        browser.hideMessages();

        if (deltaY === 0 && deltaX !== 0) {
          browser.startDragScroll(e);
          browser.move(-deltaX * 10);
          browser.stopDragScroll(false);          
        } else if (browser.wheelAction === 'zoom') {
          return browser.mousewheelZoom(e, delta);
        }
      },
      dblclick: function (e) {
        browser.hideMessages();
        browser.mousewheelZoom(e, 1);
      }
    }, '.image_container, .selector');
    
    this.selectorControls.on('click', function (e) {
      var pos = browser.getSelectorPosition();
      
      switch (e.target.className) {
        case 'summary'  : browser.summary(pos.start, pos.end); break;
        case 'zoomHere' : browser.setRange(pos.start, pos.end, true); break;
        case 'center'   : browser.moveTo(pos.start, pos.end, true, true);
        case 'cancel'   : browser.cancelSelect(); break;
        default         : break;
      }
    });
    
    $(document).on({
      'mouseup.genoverse'    : $.proxy(this.mouseup,   this),
      'mousemove.genoverse'  : $.proxy(this.mousemove, this),
      'keydown.genoverse'    : $.proxy(this.keydown,   this),
      'keyup.genoverse'      : $.proxy(this.keyup,     this),
      'mousewheel.genoverse' : function (e) {
        if (browser.wheelAction === 'zoom') {
          if (browser.wheelTimeout) {
            clearTimeout(browser.wheelTimeout);
          }
          
          browser.noWheelZoom  = browser.noWheelZoom || e.target !== browser.container[0];
          browser.wheelTimeout = setTimeout(function () { browser.noWheelZoom = false; }, 300);
        }
      }
    });
    
    $(window).on(this.useHash ? 'hashchange.genoverse' : 'popstate.genoverse', $.proxy(this.popState, this));
  },
  
  onTracks: function () {
    var args = $.extend([], arguments);
    var func = args.shift();
    var mvc;
    
    for (var i = 0; i < this.tracks.length; i++) {
      mvc = this.tracks[i]._interface[func];
      
      if (mvc) {
        this.tracks[i][mvc][func].apply(this.tracks[i][mvc], args);
      } else if (this.tracks[i][func]) {
        this.tracks[i][func].apply(this.tracks[i], args);
      }
    }
  },
  
  reset: function () {
    this.onTracks('reset');
    this.scale = 9e99; // arbitrary value so that setScale resets track scales as well
    this.setRange(this.start, this.end);
  },
  
  setWidth: function (width) {
    this.width       = width;
    this.wrapperLeft = this.labelWidth - width;
    this.width      -= this.labelWidth;
    
    this.container.width(width);
    this.onTracks('setWidth', this.width);
    this.reset();
  },
  
  mousewheelZoom: function (e, delta) {
    var browser = this;
    
    clearTimeout(this.zoomDeltaTimeout);
    clearTimeout(this.zoomTimeout);
    
    this.zoomDeltaTimeout = setTimeout(function () {
      if (delta > 0) {
        browser.zoomInHighlight.css({ left: e.pageX - 20, top: e.pageY - 20, display: 'block' }).animate({
          width: 80, height: 80, top: '-=20', left: '-=20'
        }, {
          complete: function () { $(this).css({ width: 40, height: 40, display: 'none' }); }
        });
      } else {
        browser.zoomOutHighlight.css({ left: e.pageX - 40, top: e.pageY - 40, display: 'block' }).animate({
          width: 40, height: 40, top: '+=20', left: '+=20'
        }, {
          complete: function () { $(this).css({ width: 80, height: 80, display: 'none' }); }
        });
      }
    }, 100);
    
    this.zoomTimeout = setTimeout(function () {
      browser[delta > 0 ? 'zoomIn' : 'zoomOut'](e.pageX - browser.container.offset().left - browser.labelWidth);
      
      if (browser.dragAction === 'select') {
        browser.moveSelector(e);
      }
    }, 300);
    
    return false;
  },
  
  startDragScroll: function (e) {
    this.dragging    = 'scroll';
    this.scrolling   = !e;
    this.dragOffset  = e ? e.pageX - this.left : 0;
    this.dragStart   = this.start;
    this.scrollDelta = Math.max(this.scale, this.defaultScrollDelta);
  },
  
  stopDragScroll: function (update) {
    this.dragging  = false;
    this.scrolling = false;
    
    if (update !== false) {
      if (this.start !== this.dragStart) {
        this.updateURL();
      }
      
      this.checkTrackHeights();
    }
  },
  
  startDragSelect: function (e) {
    if (!e) {
      return false;
    }
    
    var x = Math.max(0, e.pageX - this.wrapper.offset().left - 2);
    
    this.dragging        = 'select';
    this.selectorStalled = false;
    this.selectorStart   = x;
    
    this.selector.css({ left: x, width: 0 }).removeClass('crosshair');
    this.selectorControls.hide();
  },
  
  stopDragSelect: function (e) {
    if (!e) {
      return false;
    }
    
    this.dragging        = false;
    this.selectorStalled = true;
    
    if (this.selector.outerWidth(true) < 2) { 
      return this.cancelSelect();
    }
    
    // Calculate the position, so that selectorControls appear near the mouse cursor
    var top = Math.min(e.pageY - this.wrapper.offset().top, this.wrapper.outerHeight(true) - 1.2 * this.selectorControls.outerHeight(true));

    this.selectorControls.css({
      top  : top,
      left : this.selector.outerWidth(true) / 2 - this.selectorControls.outerWidth(true) / 2
    }).show();
  },
  
  cancelSelect: function (keepDragging) {
    if (!keepDragging) {
      this.dragging = false;
    }
    
    this.selectorStalled = false;
    
    this.selector.addClass('crosshair').width(0);
    this.selectorControls.hide();
    
    if (this.dragAction === 'scroll') {
      this.selector.hide();
    }
  },
  
  dragSelect: function (e) {
    var x = e.pageX - this.wrapper.offset().left;

    if (x > this.selectorStart) {
      this.selector.css({ 
        left  : this.selectorStart, 
        width : Math.min(x - this.selectorStart, this.width - this.selectorStart - 1)
      });
    } else {
      this.selector.css({ 
        left  : Math.max(x, 1), 
        width : Math.min(this.selectorStart - x, this.selectorStart - 1)
      });
    }    
  },
  
  setDragAction: function (action, keepSelect) {
    this.dragAction = action;
    
    if (this.dragAction === 'select') {
      this.selector.addClass('crosshair').width(0).show();
    } else if (keepSelect && !this.selector.hasClass('crosshair')) {
      this.selectorStalled = false;
    } else {
      this.cancelSelect();
      this.selector.hide();
    }
  },
  
  toggleSelect: function (on) {
    if (on) {
      this.prev.dragAction = 'scroll';
      this.setDragAction('select');
    } else {
      this.setDragAction(this.prev.dragAction, true);
      delete this.prev.dragAction;
    }
  },
  
  setWheelAction: function (action) {
    this.wheelAction = action;
  },
  
  keydown: function (e) {
    if (e.which === 16 && !this.prev.dragAction && this.dragAction === 'scroll') { // shift key
      this.toggleSelect(true);
    } else if (e.which === 27) { // escape key
      this.cancelSelect();
      this.closeMenus();
    }
  },
  
  keyup: function (e) {
    if (e.which === 16 && this.prev.dragAction) { // shift key
      this.toggleSelect();
    }
  },
  
  mousedown: function (e) {
    if (e.shiftKey) {
      if (this.dragAction === 'scroll') {
        this.toggleSelect(true);
      }
    } else if (this.prev.dragAction) {
      this.toggleSelect();
    }
    
    switch (this.dragAction) {
      case 'select' : this.startDragSelect(e); break;
      case 'scroll' : this.startDragScroll(e); break;
      default       : break;
    }
  },
 
  mouseup: function (e, update) {
    if (!this.dragging) {
      return false;
    }
    
    switch (this.dragging) {
      case 'select' : this.stopDragSelect(e);      break;
      case 'scroll' : this.stopDragScroll(update); break;
      default       : break;
    }
  },
  
  mousemove: function (e) {
    if (this.dragging && !this.scrolling) {
      switch (this.dragAction) {
        case 'scroll' : this.move(e.pageX - this.dragOffset - this.left); break;
        case 'select' : this.dragSelect(e); break;
        default       : break;
      }
    } else if (this.dragAction === 'select') {
      this.moveSelector(e);
    }
  },
  
  moveSelector: function (e) {
    if (!this.selectorStalled) {
      this.selector.css('left', e.pageX - this.wrapper.offset().left - 2);
    }
  },
  
  move: function (delta) {
    var scale = this.scale;
    var start, end, left;
    
    if (scale > 1) {
      delta = Math.round(delta / scale) * scale; // Force stepping by base pair when in small regions
    }
    
    left = this.left + delta;
    
    if (left <= this.minLeft) {
      left  = this.minLeft;
      delta = this.minLeft - this.left;
    } else if (left >= this.maxLeft) {
      left  = this.maxLeft;
      delta = this.maxLeft - this.left;
    }
    
    start = Math.max(Math.round(this.start - delta / scale), 1);
    end   = start + this.length - 1;
    
    if (end > this.chromosomeSize) {
      end   = this.chromosomeSize;
      start = end - this.length + 1;
    }
    
    this.left = left;

    if (start !== this.dragStart) {
      this.closeMenus();
      this.cancelSelect(true);
    }
    
    this.onTracks('move', delta);
    this.setRange(start, end);
  },
  
  moveTo: function (start, end, update, keepLength) {
    this.setRange(start, end, update, keepLength);
    
    if (this.prev.scale === this.scale) {
      this.onTracks('moveTo', this.start, this.end, (this.prev.start - this.start) * this.scale);
    }
  },
  
  setRange: function (start, end, update, keepLength) {
    this.prev.start = this.start;
    this.prev.end   = this.end;
    this.start      = Math.max(typeof start === 'number' ? Math.floor(start) : parseInt(start, 10), 1);
    this.end        = Math.min(typeof end   === 'number' ? Math.floor(end)   : parseInt(end,   10), this.chromosomeSize);
    
    if (this.end < this.start) {
      this.end = Math.min(this.start + this.defaultLength - 1, this.chromosomeSize);
    }
    
    if (keepLength && this.end - this.start + 1 !== this.length) {
      if (this.end === this.chromosomeSize) {
        this.start = this.end - this.length + 1;
      } else {
        var center = (this.start + this.end) / 2;
        this.start = Math.max(Math.floor(center - this.length / 2), 1);
        this.end   = this.start + this.length - 1;
      }
    } else {
      this.length = this.end - this.start + 1;
    }
    
    this.setScale();
    
    if (update === true && (this.prev.start !== this.start || this.prev.end !== this.end)) {
      this.updateURL();
    }
  },
  
  setScale: function () {
    this.prev.scale  = this.scale;
    this.scale       = this.width / this.length;
    this.scaledStart = this.start * this.scale;
    
    if (this.prev.scale !== this.scale) {
      this.left        = 0;
      this.minLeft     = Math.round((this.end   - this.chromosomeSize) * this.scale);
      this.maxLeft     = Math.round((this.start - 1) * this.scale);
      this.labelBuffer = Math.ceil(this.textWidth / this.scale) * this.longestLabel;

      if (this.prev.scale) {
        this.cancelSelect();
        this.closeMenus();
      }
      
      this.onTracks('setScale');
      this.onTracks('makeFirstImage');
    }
  },
  
  checkTrackHeights: function () {
    if (this.dragging) {
      return;
    }
    
    this.onTracks('checkHeight');
  },
  
  resetTrackHeights: function () {
    this.onTracks('resetHeight');
  },
  
  zoomIn: function (x) {
    if (!x) {
      x = this.width / 2;
    }
    
    var start = Math.round(this.start + x / (2 * this.scale));
    var end   = this.length === 2 ? start : Math.round(start + (this.length - 1) / 2);
    
    this.setRange(start, end, true);
  },
  
  zoomOut: function (x) {
    if (!x) {
      x = this.width / 2;
    }
    
    var start = Math.round(this.start - x / this.scale);
    var end   = this.length === 1 ? start + 1 : Math.round(start + 2 * (this.length - 1));
    
    this.setRange(start, end, true);
  },
  
  
  addTrack: function (track, index) {
    return this.addTracks([ track ], index)[0];
  },
  
  addTracks: function (tracks, index) {
    var defaults = {
      browser : this,
      width   : this.width
    };
    
    var push = !!tracks;
    
    tracks = tracks || $.extend([], this.tracks);
    index  = index  || 0;
    
    for (var i = 0; i < tracks.length; i++) {
      tracks[i] = new tracks[i]($.extend(defaults, { index: i + index }));
      
      if (tracks[i].id) {
        this.tracksById[tracks[i].id] = tracks[i];
      }
      
      if (push) {
        this.tracks.push(tracks[i]);
        
        if (this.scale) {
          tracks[i].controller.setScale(); // scale will only be set for tracks added after initalisation
          tracks[i].controller.makeFirstImage();
        }
      } else {
        this.tracks[i] = tracks[i];
      }
    }
    
    this.sortTracks();
    
    return tracks;
  },
  
  removeTrack: function (track) {
    this.removeTracks([ track ]);
  },
  
  removeTracks: function (tracks) {
    var i = tracks.length;
    var j;
    
    while (i--) {
      j = this.tracks.length;
      
      while (j--) {
        if (tracks[i] === this.tracks[j]) {
          this.tracks.splice(j, 1);
          break;
        }
      }
      
      if (tracks[i].id) {
        delete this.tracksById[tracks[i].id];
      }
      
      tracks[i].destructor(); // Destroy DOM elements and track itself
    }
  },
  
  sortTracks: function () {
    if ($.grep(this.tracks, function (t) { return typeof t !== 'object'; }).length) {
      return;
    }
    
    var sorted     = $.extend([], this.tracks).sort(function (a, b) { return a.order - b.order; });
    var labels     = $();
    var containers = $();
    
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].prop('menus').length) {
        sorted[i].prop('top', sorted[i].prop('container').position().top);
      }
      
      labels.push(sorted[i].prop('label')[0]);
      containers.push(sorted[i].prop('container')[0]);
    }
    
    this.labelContainer.append(labels);
    this.wrapper.append(containers);
    
    // Correct the order
    this.tracks = sorted;
    
    labels.map(function () { return $(this).data('track'); }).each(function () {
      if (this.prop('menus').length) {
        var diff = this.prop('container').position().top - this.prop('top');
        this.prop('menus').css('top', function (i, top) { return parseInt(top, 10) + diff; });
        this.prop('top', null);
      }
    }); 
    
    sorted = labels = containers = null;
  },
  
  updateTrackOrder: function (e, ui) {
    var track = ui.item.data('track');
    
    var p = ui.item.prev().data('track').prop('order') || 0;
    var n = ui.item.next().data('track').prop('order') || 0;
    var o = p || n;
    var order;
    
    if (Math.floor(n) === Math.floor(p)) {
      order = p + (n - p) / 2;
    } else {
      order = o + (p ? 1 : -1) * (Math.round(o) - o || 1) / 2;
    }
    
    track.prop('order', order);
    
    this.sortTracks();
  },
  
  updateURL: function () {
    if (this.urlParamTemplate) {
      if (this.useHash) {
        window.location.hash = this.getQueryString();
      } else {
        window.history.pushState({}, '', this.getQueryString());
      }
    }
  },
  
  popState: function () {
    var coords = this.getURLCoords();
    var start  = parseInt(coords.start, 10);
    var end    = parseInt(coords.end,   10);
    
    if (coords.start && !(start === this.start && end === this.end)) {
      // FIXME: a back action which changes scale or a zoom out will reset tracks, since scrollStart will not be the same as it was before
      this.moveTo(start, end);
    }
    
    this.closeMenus();
    this.hideMessages();
  },
  
  getURLCoords: function () {
    var match  = ((this.useHash ? window.location.hash.replace(/^#/, '?') || window.location.search : window.location.search) + '&').match(this.paramRegex);
    var coords = {};
    var i      = 0;
    
    if (!match) {
      return coords;
    }
    
    match = match.slice(2, -1);
    
    $.each(this.urlParamTemplate.split('__'), function () {
      var tmp = this.match(/^(CHR|START|END)$/);
      
      if (tmp) {
        coords[tmp[1].toLowerCase()] = tmp[1] === 'CHR' ? match[i++] : parseInt(match[i++], 10);
      }
    });
    
    return coords;
  },
  
  getQueryString: function () {
    var location = this.urlParamTemplate
      .replace('__CHR__',   this.chr)
      .replace('__START__', this.start)
      .replace('__END__',   this.end);
    
    return this.useHash ? location : window.location.search ? (window.location.search + '&').replace(this.paramRegex, '$1' + location + '$5').slice(0, -1) : '?' + location;
  },
  
  supported: function () {
    var el = document.createElement('canvas');
    return !!(el.getContext && el.getContext('2d'));
  },
  
  die: function (error, el) {
    if (el && el.length) {
      el.html(error);
    } else {
      alert(error);
    }
    
    this.failed = true;
  },
  
  menuTemplate: $('<div class="gv_menu"><div class="close">x</div><table></table></div>').on('click', function (e) {
    if ($(e.target).hasClass('close')) {
      $(this).fadeOut('fast', function () { 
        var data = $(this).data();
        
        if (data.track) {
          data.track.prop('menus', data.track.prop('menus').not(this));
        }
        
        data.browser.menus = data.browser.menus.not(this);
      });
    }
  }),
  
  makeMenu: function (feature, event, track) {
    if (!feature.menuEl) {
      var menu = this.menuTemplate.clone(true).data('browser', this);
      
      $.when(track ? track.controller.populateMenu(feature) : feature).done(function (feature) {
        if (Object.prototype.toString.call(feature) !== '[object Array]') {
          feature = [ feature ];
        }
        
        feature.every(function (f) {
          $('table', menu).append(
            (f.title ? '<tr class="header"><th colspan="2" class="title">' + f.title + '</th></tr>' : '') +
            $.map(f, function (value, key) {
              if (key !== 'title') {
                return '<tr><td>'+ key +'</td><td>'+ value +'</td></tr>';
              }
            }).join()
          );
          
          return true;
        });
        
        if (track) {
          menu.addClass(track.id).data('track', track);
        }
      });
      
      feature.menuEl = menu;
    }
    
    this.menus = this.menus.add(feature.menuEl);
    
    if (track) {
      track.prop('menus', track.prop('menus').add(feature.menuEl));
    }
    
    feature.menuEl.appendTo('body');
    
    if (event) {
      feature.menuEl.css({ left: 0, top: 0 }).position({ of: event, my: 'left top', collision: 'flipfit' });
    }

    return feature.menuEl.show();
  },
  
  closeMenus: function () {
    this.menus.filter(':visible').children('.close').trigger('click');
    this.menus = $();
  },
  
  hideMessages: function () {
    if (this.autoHideMessages) {
      this.wrapper.find('.message_container').addClass('collapsed');
    }
  },
  
  getSelectorPosition: function () {
    var left  = this.selector.position().left;
    var width = this.selector.outerWidth(true);
    var start = Math.round(left / this.scale) + this.start;
    var end   = Math.round((left + width) / this.scale) + this.start - 1;
        end   = end <= start ? start : end;
    
    return { start: start, end: end, left: left, width: width };
  },
  
  // Provide summary of a region (as a popup menu)
  summary: function (start, end) {
    alert(
      'Not implemented' + "\n" +
      'Start: ' + start + "\n" +
      'End: '   + end   + "\n"
    );
  },
  
  saveConfig: $.noop,
  
  systemEventHandlers: {}
}, {
  on: function (events, handler) {
    $.each(events.split(' '), function () {
      if (typeof Genoverse.prototype.systemEventHandlers[this] === 'undefined') {
        Genoverse.prototype.systemEventHandlers[this] = [];
      }
      
      Genoverse.prototype.systemEventHandlers[this].push(handler);
    });
  },
  
  wrapFunctions: function (obj) {
    // Push all before* and after* functions to systemEventHandlers array
    for (var key in obj) {
      if (typeof obj[key] === 'function' && key.match(/^(before|after)/)) {
        obj.systemEventHandlers[key] = obj.systemEventHandlers[key] || [];
        obj.systemEventHandlers[key].push(obj[key]);
      }
    }
    
    // Wrap it up
    for (key in obj) {
      if (typeof obj[key] === 'function' && !key.match(/^(base|extend|constructor|loadPlugins|loadGenome|controller|model|view)$/)) {
        Genoverse.functionWrap(key, obj);
      }
    }
  },
  
  /**
   * functionWrap - wraps event handlers and adds debugging functionality
   **/
  functionWrap: function (key, obj) {
    var name = (obj ? (obj.name || 'Track' + (obj.type || '')) : 'Genoverse') + '.' + key;
    
    if (key.match(/^(before|after|__original)/)) {
      return;
    }
    
    var func = key.substring(0, 1).toUpperCase() + key.substring(1);
    
    if (obj.debug) {
      Genoverse.debugWrap(obj, key, name, func);
    }
    
    // turn function into system event, enabling eventHandlers for before/after the event
    if (obj.systemEventHandlers['before' + func] || obj.systemEventHandlers['after' + func]) {
      obj['__original' + func] = obj[key];
      
      obj[key] = function () {
        var i, rtn;
        
        if (this.systemEventHandlers['before' + func]) {
          for (i = 0; i < this.systemEventHandlers['before' + func].length; i++) {
            // TODO: Should it end when beforeFunc returned false??
            this.systemEventHandlers['before' + func][i].apply(this, arguments);
          }
        }
        
        rtn = this['__original' + func].apply(this, arguments);
        
        if (this.systemEventHandlers['after' + func]) {
          for (i = 0; i < this.systemEventHandlers['after' + func].length; i++) {
            // TODO: Should it end when afterFunc returned false??
            this.systemEventHandlers['after' + func][i].apply(this, arguments);
          }
        }
        
        return rtn;
      };
    }
  },
  
  debugWrap: function (obj, key, name, func) {
    // Debugging functionality
    // Enabled by "debug": true || { functionName: true, ...} option
    // if "debug": true, simply log function call
    if (obj.debug === true) {
      if (!obj.systemEventHandlers['before' + func]) {
        obj.systemEventHandlers['before' + func] = [];
      }
      
      obj.systemEventHandlers['before' + func].unshift(function () {
        console.log(name);
      });
    }
    
    // if debug: { functionName: true, ...}, log function time
    if (typeof obj.debug === 'object' && obj.debug[key]) {
      if (!obj.systemEventHandlers['before' + func]) {
        obj.systemEventHandlers['before' + func] = [];
      }
      
      if (!obj.systemEventHandlers['after' + func]) {
        obj.systemEventHandlers['after' + func] = [];
      }
      
      obj.systemEventHandlers['before' + func].unshift(function () {
        //console.log(name, arguments);        
        console.time('time: ' + name);
      });
      
      obj.systemEventHandlers['after' + func].push(function () {
        console.timeEnd('time: ' + name);
      });
    }
  }
});

Genoverse.prototype.origin = ($('script:last').attr('src').match(/(.*)js\/\w+/) || [])[1];

if (typeof LazyLoad !== 'undefined') {
  LazyLoad.css(Genoverse.prototype.origin + 'css/genoverse.css');
}

String.prototype.hashCode = function () {
  var hash = 0;
  var chr;
  
  if (!this.length) {
    return hash;
  }
  
  for (var i = 0; i < this.length; i++) {
    chr  = this.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash = hash & hash; // Convert to 32bit integer
  }
  
  return '' + hash;
};

window.Genoverse = Genoverse;




Genoverse.Track = Base.extend({
  height     : 12,        // The height of the track_container div
  margin     : 2,         // The spacing between this track and the next
  resizable  : true,      // Is the track resizable - can be true, false or 'auto'. Auto means the track will automatically resize to show all features, but the user cannot resize it themselves.
  border     : true,      // Does the track have a bottom border
  hidden     : false,     // Is the track hidden by default
  unsortable : false,     // Is the track unsortable
  name       : undefined, // The name of the track, which appears in its label
  autoHeight : undefined, // Does the track automatically resize so that all the features are visible
  
  constructor: function (config) {
    if (this.stranded || config.stranded) {
      this.controller = this.controller || Genoverse.Track.Controller.Stranded;
      this.model      = this.model      || Genoverse.Track.Model.Stranded;
    }
    
    this.setInterface();
    this.extend(config);
    this.setDefaults();
    
    Genoverse.wrapFunctions(this);
    
    this.setLengthMap();
    this.setMVC();
  },
  
  setDefaults: function () {
    this.order             = this.order || this.index;
    this.defaultHeight     = this.height;
    this.defaultAutoHeight = this.autoHeight;
    this.autoHeight        = typeof this.autoHeight !== 'undefined' ? this.autoHeight : this.browser.trackAutoHeight;
    this.height           += this.margin;
    this.initialHeight     = this.height;
    
    if (this.hidden) {
      this.height = 0;
    }
    
    if (this.resizable === 'auto') {
      this.autoHeight = true;
    }
  },
  
  setInterface: function () {
    var mvc = [ 'Controller', 'Model', 'View', 'controller', 'model', 'view' ];
    var prop;
    
    this._interface = {};
    
    for (var i = 0; i < 3; i++) {
      for (prop in Genoverse.Track[mvc[i]].prototype) {
        if (!/^(constructor|init)$/.test(prop)) {
          this._interface[prop] = mvc[i + 3];
        }
      }
    }
  },
  
  setMVC: function () {
    // FIXME: if you zoom out quickly then hit the back button, the second zoom level (first one you zoomed out to) will not draw if the models/views are the same
    if (this.model && typeof this.model.abort === 'function') { // TODO: don't abort unless model is changed?
      this.model.abort();
    }
    
    var lengthSettings = this.getSettingsForLength();
    var settings       = $.extend(true, {}, this.constructor.prototype, lengthSettings); // model, view, options
    var mvc            = [ 'model', 'view', 'controller' ];
    var propFunc       = $.proxy(this.prop, this);
    var mvcSettings    = {};
    var trackSettings  = {};
    var obj, j;
    
    settings.controller = settings.controller || this.controller || Genoverse.Track.Controller;
    settings.model      = settings.model      || this.model      || Genoverse.Track.Model;
    settings.view       = settings.view       || this.view       || Genoverse.Track.View;
    
    for (var i = 0; i < 3; i++) {
      mvcSettings[mvc[i]] = { prop: {}, func: {} };
    }
    
    for (i in settings) {
      if (!/^(constructor|init|setDefaults|base|extend|lengthMap)$/.test(i) && isNaN(i)) {
        if (this._interface[i]) {
          mvcSettings[this._interface[i]][typeof settings[i] === 'function' ? 'func' : 'prop'][i] = settings[i];
        } else if (!Genoverse.Track.prototype.hasOwnProperty(i) && !/^(controller|model|view)$/.test(i)) {
          trackSettings[i] = settings[i];
        }
      }
    }
    
    this.extend(trackSettings);
    
    for (i = 0; i < 3; i++) {
      obj = mvc[i];
      
      mvcSettings[obj].func.prop                = propFunc;
      mvcSettings[obj].func.systemEventHandlers = this.systemEventHandlers;
      mvcSettings[obj].prop.browser             = this.browser;
      mvcSettings[obj].prop.width               = this.width;
      mvcSettings[obj].prop.index               = this.index;
      mvcSettings[obj].prop.track               = this;
      
      if (obj === 'controller') {
        continue;
      }
      
      if (typeof settings[obj] === 'function' && (!this[obj] || this[obj].constructor.ancestor !== settings[obj])) {
        // Make a new instance of model/view if there isn't one already, or the model/view in lengthSettings is different from the existing model/view
        this[obj] = new (settings[obj].extend($.extend(true, {}, settings[obj].prototype, mvcSettings[obj].func)))(mvcSettings[obj].prop);
      } else {
        // Update the model/view with the values in mvcSettings.
        var test = typeof settings[obj] === 'object' && this[obj] !== settings[obj] ? this[obj] = settings[obj] : lengthSettings && this.lengthMap.length > 1 ? lengthSettings : false;
        
        if (test) {
          for (j in mvcSettings[obj].prop) {
            if (typeof test[j] !== 'undefined') {
              this[obj][j] = mvcSettings[obj].prop[j];
            }
          }
          
          this[obj].constructor.extend(mvcSettings[obj].func);
          
          if (obj === 'model' && typeof test.url !== 'undefined') {
            this.model.setURL(); // make sure the URL is correct
          }
        }
      }
    }
    
    if (!this.controller || typeof this.controller === 'function') {
      this.controller = new (settings.controller.extend($.extend(true, {}, settings.controller.prototype, mvcSettings.controller.func)))($.extend(mvcSettings.controller.prop, { model: this.model, view: this.view }));
    } else {
      $.extend(this.controller, { model: this.model, view: this.view, threshold: mvcSettings.controller.prop.threshold || this.controller.constructor.prototype.threshold });
    }
    
    if (this.strand === -1 && this.orderReverse) {
      this.order = this.orderReverse;
    }
    
    if (lengthSettings) {
      lengthSettings.model = this.model;
      lengthSettings.view  = this.view;
    }
  },
  
  setLengthMap: function () {
    var value, j, deepCopy;
    
    this.lengthMap = [];
    
    for (var key in this) { // Find all scale-map like keys
      if (!isNaN(key)) {
        key   = parseInt(key, 10);
        value = this[key];
        delete this[key];
        this.lengthMap.push([ key, value === false ? { threshold: key, resizable: 'auto' } : value ]);
      }
    }
    
    if (this.lengthMap.length) {
      this.lengthMap.push([ -1, $.extend(true, {}, this, { view: this.view || Genoverse.Track.View, model: this.model || Genoverse.Track.Model }) ]);
      this.lengthMap = this.lengthMap.sort(function (a, b) { return b[0] - a[0]; });
    }
    
    for (var i = 0; i < this.lengthMap.length; i++) {
      if (this.lengthMap[i][1].model && this.lengthMap[i][1].view) {
        continue;
      }
      
      deepCopy = {};
      
      if (this.lengthMap[i][0] !== -1) {
        for (j in this.lengthMap[i][1]) {
          if (this._interface[j]) {
            deepCopy[this._interface[j]] = true;
          }
        }
      }
      
      for (j = i + 1; j < this.lengthMap.length; j++) {
        if (!this.lengthMap[i][1].model && this.lengthMap[j][1].model) {
          this.lengthMap[i][1].model = deepCopy.model ? Genoverse.Track.Model.extend($.extend(true, {}, this.lengthMap[j][1].model.prototype)) : this.lengthMap[j][1].model;
        }
        
        if (!this.lengthMap[i][1].view && this.lengthMap[j][1].view) {
          this.lengthMap[i][1].view = deepCopy.view ? Genoverse.Track.View.extend($.extend(true, {}, this.lengthMap[j][1].view.prototype)) : this.lengthMap[j][1].view;
        }
        
        if (this.lengthMap[i][1].model && this.lengthMap[i][1].view) {
          break;
        }
      }
    }
  },
  
  getSettingsForLength: function () {
    for (var i = 0; i < this.lengthMap.length; i++) {
      if (this.browser.length > this.lengthMap[i][0] || this.browser.length === 1 && this.lengthMap[i][0] === 1) {
        return this.lengthMap[i][1];
      }
    }
  },
  
  prop: function (key, value) {
    var mvc = [ 'controller', 'model', 'view' ];
    var obj;
    
    if (this._interface[key]) {
      obj = this[this._interface[key]];
    } else {
      for (var i = 0; i < 3; i++) {
        if (this[mvc[i]] && typeof this[mvc[i]][key] !== 'undefined') {
          obj = this[mvc[i]];
          break;
        }
      }
      
      obj = obj || this;
    }
    
    
    if (typeof value !== 'undefined') {
      if (value === null) {
        delete obj[key];
      } else {
        obj[key] = value;
      }
    }
    
    return obj ? obj[key] : undefined;
  },
  
  setHeight: function (height, forceShow) {
    if (this.prop('hidden') || (forceShow !== true && height < this.prop('featureHeight'))) {
      height = 0;
    } else {
      height = Math.max(height, this.prop('minLabelHeight'));
    }
    
    this.height = height;
    
    return height;
  },
  
  resetHeight: function () {  
    if (this.resizable === true) {
      var resizer = this.prop('resizer');
      
      this.autoHeight = !!([ this.defaultAutoHeight, this.browser.trackAutoHeight ].sort(function (a, b) {
        return (typeof a !== 'undefined' && a !== null ? 0 : 1) - (typeof b !== 'undefined' && b !== null ?  0 : 1);
      })[0]);
      
      this.controller.resize(this.autoHeight ? this.prop('fullVisibleHeight') : this.defaultHeight + this.margin + (resizer ? resizer.height() : 0));
      this.initialHeight = this.height;
    }
  },
  
  show: function () {
    this.hidden = false;
    this.controller.resize(this.initialHeight);
  },
  
  hide: function () {
    this.hidden = true;
    this.controller.resize(0);
  },
  
  enable: function () {
    this.disabled = false;
    this.show();
    this.controller.makeFirstImage();
  },
  
  disable: function () {
    this.hide();
    this.controller.scrollContainer.css('left', 0);
    this.controller.reset();
    this.disabled = true;
  },
  
  remove: function () {
    this.browser.removeTrack(this);
  },
  
  destructor: function () {
    this.controller.destroy();
    
    var objs = [ this.view, this.model, this.controller, this ];
    
    for (var obj in objs) {
      for (var key in obj) {
        delete obj[key];
      }
    }
  },
  
  systemEventHandlers: {}
}, {
  on: function (events, handler) {
    $.each(events.split(' '), function () {
      if (typeof Genoverse.Track.prototype.systemEventHandlers[this] === 'undefined') {
        Genoverse.Track.prototype.systemEventHandlers[this] = [];
      }
      
      Genoverse.Track.prototype.systemEventHandlers[this].push(handler);
    });
  }
});



Genoverse.Track.File = Genoverse.Track.extend({
  setInterface: function () {
    this.base();
    this._interface.data = 'model';
  }
});




Genoverse.Track.Controller = Base.extend({
  scrollBuffer : 1.2,       // Number of widths, if left or right closer to the edges of viewpoint than the buffer, start making more images
  threshold    : Infinity,  // Length above which the track is not drawn
  messages     : {
    error     : 'ERROR: ',
    threshold : 'Data for this track is not displayed in regions greater than ',
    resize    : 'Some features are currently hidden, resize to see all'
  },
  
  constructor: function (properties) {
    $.extend(this, properties);
    Genoverse.wrapFunctions(this);
    this.init();
  },
  
  init: function () {
    this.imgRange    = {};
    this.scrollRange = {};
    
    this.addDomElements();
    this.addUserEventHandlers();
  },
  
  reset: function () {
    this.resetImages();
    this.browser.closeMenus.call(this);
    
    if (this.url !== false) {
      this.model.init(true);
    }
    
    this.view.init();
  },
  
  resetImages: function () {
    this.imgRange    = {};
    this.scrollRange = {};
    this.scrollContainer.empty();
    this.resetImageRanges();
  },
  
  resetImageRanges: function () {
    this.left        = 0;
    this.scrollStart = 'ss_' + this.browser.start + '_' + this.browser.end;
    
    this.imgRange[this.scrollStart]    = this.imgRange[this.scrollStart]    || { left: this.width * -2, right: this.width * 2 };
    this.scrollRange[this.scrollStart] = this.scrollRange[this.scrollStart] || { start: this.browser.start - this.browser.length, end: this.browser.end + this.browser.length };
  },
  
  rename: function (name) {
    this.track.name     = name;
    this.minLabelHeight = $('span.name', this.label).html(name).outerHeight(true);
    this.label.height(this.prop('hidden') ? 0 : Math.max(this.prop('height'), this.minLabelHeight));
  },
  
  addDomElements: function () {
    var name = this.track.name || '';
    
    this.menus            = $();
    this.container        = $('<div class="track_container">').appendTo(this.browser.wrapper);
    this.scrollContainer  = $('<div class="scroll_container">').appendTo(this.container);
    this.imgContainer     = $('<div class="image_container">').width(this.width);
    this.messageContainer = $('<div class="message_container"><div class="messages"></div><span class="control collapse">&laquo;</span><span class="control expand">&raquo;</span></div>').appendTo(this.container);
    this.label            = $('<li>').appendTo(this.browser.labelContainer).height(this.prop('height')).data('track', this.track);
    this.context          = $('<canvas>')[0].getContext('2d');
    
    if (this.prop('border')) {
      $('<div class="track_border">').appendTo(this.container);
    }
    
    if (this.prop('unsortable')) {
      this.label.addClass('unsortable');
    } else {
      $('<div class="handle">').appendTo(this.label);
    }
    
    this.minLabelHeight = $('<span class="name" title="' + name + '">' + name + '</span>').appendTo(this.label).outerHeight(true);
    
    var h = this.prop('hidden') ? 0 : Math.max(this.prop('height'), this.minLabelHeight);
    
    if (this.minLabelHeight) {
      this.label.height(h);
    }
    
    this.container.height(h);
  },
  
  addUserEventHandlers: function () {
    var controller = this;
    var browser    = this.browser;
    
    this.container.on('mouseup', '.image_container', function (e) {
      if ((e.which && e.which !== 1) || browser.start !== browser.dragStart || (browser.dragAction === 'select' && browser.selector.outerWidth(true) > 2)) {
        return; // Only show menus on left click when not dragging and not selecting
      }

      controller.click(e);
    });
    
    this.messageContainer.children().on('click', function () {
      var collapsed = controller.messageContainer.children('.messages').is(':visible') ? ' collapsed' : '';
      var code      = controller.messageContainer.find('.msg')[0].className.replace('msg', '').replace(' ', '');
      
      controller.messageContainer.attr('class', 'message_container' + collapsed);
      controller.checkHeight();
      
      if (code !== 'error') {
        document.cookie = [ 'gv_msg', code, controller.prop('id') ].join('_') + '=1; expires=' + (collapsed ? 'Tue, 19 Jan 2038' : 'Thu, 01 Jan 1970') + ' 00:00:00 GMT; path=/';
      }
    });
  },
  
  click: function (e) {
    var x = e.pageX - this.container.parent().offset().left + this.browser.scaledStart;
    var y = e.pageY - $(e.target).offset().top;
    var f = this[e.target.className === 'labels' ? 'labelPositions' : 'featurePositions'].search({ x: x, y: y, w: 1, h: 1 }).sort(function (a, b) { return a.sort - b.sort; })[0];
    
    if (f) {
      this.browser.makeMenu(f, e, this.track);
    }
  },
  
  // FIXME: messages are now hidden/shown instead of removed/added. This will cause a problem if a new message arrives with the same code as one that already exists.
  showMessage: function (code, additionalText) {
    var messages = this.messageContainer.children('.messages');
    
    if (!messages.children('.' + code).show().length) {
      messages.prepend('<div class="msg ' + code + '">' + this.messages[code] + (additionalText || '') + '</div>');
      this.messageContainer[document.cookie.match([ 'gv_msg', code, this.prop('id') ].join('_') + '=1') ? 'addClass' : 'removeClass']('collapsed');
    }
    
    var height = this.messageContainer.show().outerHeight(true);
    
    if (height > this.prop('height')) {
      this.resize(height);
    }
    
    messages = null;
  },
  
  hideMessage: function (code) {
    var messages = this.messageContainer.find('.msg');
    
    if (code) {
      messages = messages.filter('.' + code).hide();
      
      if (messages.length && !messages.siblings().filter(function () { return this.style.display !== 'none'; }).length) {
        this.messageContainer.hide();
      }
    } else {
      messages.hide();
      this.messageContainer.hide();
    }
    
    messages = null;
  },
  
  showError: function (error) {
    this.showMessage('error', error);
  },
  
  checkHeight: function () {
    if (this.browser.length > this.threshold) {
      if (this.thresholdMessage) {
        this.showMessage('threshold', this.thresholdMessage);
        this.fullVisibleHeight = Math.max(this.messageContainer.outerHeight(true), this.minLabelHeight);
      } else {
        this.fullVisibleHeight = 0;
      }
    } else if (this.thresholdMessage) {
      this.hideMessage('threshold');
    }
    
    if (!this.prop('resizable')) {
      return;
    }
    
    var autoHeight;
    
    if (this.browser.length > this.threshold) {
      autoHeight = this.prop('autoHeight');
      this.prop('autoHeight', true);
    } else {
      var bounds   = { x: this.browser.scaledStart, w: this.width, y: 0, h: 9e99 };
      var scale    = this.scale;
      var features = this.featurePositions.search(bounds);
      var height   = Math.max.apply(Math, $.map(features, function (feature) { return feature.position[scale].bottom; }).concat(0));
      
      if (this.prop('labels') === 'separate') {
        this.labelTop = height;
        height += Math.max.apply(Math, $.map(this.labelPositions.search(bounds).concat(this.prop('repeatLabels') ? features : []), function (feature) { return feature.position[scale].label.bottom; }).concat(0));
      }
      
      this.fullVisibleHeight = height || (this.messageContainer.is(':visible') ? this.messageContainer.outerHeight(true) : 0);
    }
    
    this.autoResize();
    
    if (typeof autoHeight !== 'undefined') {
      this.prop('autoHeight', autoHeight);
    }
  },
  
  autoResize: function () {
    var autoHeight = this.prop('autoHeight');
    
    if (autoHeight || this.prop('labels') === 'separate') {
      this.resize(autoHeight ? this.fullVisibleHeight : this.prop('height'), this.labelTop);
    } else {
      this.toggleExpander();
    }
  },
  
  resize: function (height) {
    height = this.track.setHeight(height, arguments[1]);
    
    if (typeof arguments[1] === 'number') {
      this.imgContainers.children('.labels').css('top', arguments[1]);
    }
    
    this.container.add(this.label).height(height)[height ? 'show' : 'hide']();
    this.toggleExpander();
  },
  
  toggleExpander: function () {
    if (this.prop('resizable') !== true) {
      return;
    }
    
    var featureMargin = this.prop('featureMargin');
    var height        = this.prop('height');
    
    // Note: fullVisibleHeight - featureMargin.top - featureMargin.bottom is not actually the correct value to test against, but it's the easiest best guess to obtain.
    // fullVisibleHeight is the maximum bottom position of the track's features in the region, which includes margin at the bottom of each feature and label
    // Therefore fullVisibleHeight includes this margin for the bottom-most feature.
    // The correct value (for a track using the default positionFeatures code) is:
    // fullVisibleHeight - ([there are labels in this region] ? (labels === 'separate' ? 0 : featureMargin.bottom + 1) + 2 : featureMargin.bottom)
    if (this.fullVisibleHeight - featureMargin.top - featureMargin.bottom > height) {
      this.showMessage('resize');
      
      var controller = this;
      var h          = this.messageContainer.outerHeight(true);
      
      if (h > height) {
        this.resize(h);
      }
      
      this.expander = (this.expander || $('<div class="expander static">').width(this.width).appendTo(this.container).on('click', function () {
        controller.resize(controller.fullVisibleHeight);
      }))[this.prop('height') === 0 ? 'hide' : 'show']();
    } else if (this.expander) {
      this.hideMessage('resize');
      this.expander.hide();
    }
  },
  
  setWidth: function (width) {
    var track = this.track;
    
    $.each([ this, track, track.model, track.view ], function () {
      this.width = width;
    });
    
    this.imgContainer.add(this.expander).width(width);
    
  },
  
  setScale: function () {
    var controller = this;
    
    this.scale = this.browser.scale;
    
    this.track.setMVC();
    this.resetImageRanges();
    
    var labels = this.prop('labels');
    
    if (labels && labels !== 'overlay') {
      this.model.setLabelBuffer(this.browser.labelBuffer);
    }
    
    if (this.threshold !== Infinity && this.prop('resizable') !== 'auto') {
      this.thresholdMessage = this.view.formatLabel(this.threshold);
    }
    
    $.each(this.view.setScaleSettings(this.scale), function (k, v) { controller[k] = v; });
    
    this.hideMessage();
  },
  
  move: function (delta) {
    this.left += delta;
    this.scrollContainer.css('left', this.left);
    
    var scrollStart = this.scrollStart;
    
    if (this.imgRange[scrollStart].left + this.left > -this.scrollBuffer * this.width) {
      var end = this.scrollRange[scrollStart].start - 1;
      
      this.makeImage({
        scale : this.scale,
        start : end - this.browser.length + 1,
        end   : end,
        left  : this.imgRange[scrollStart].left,
        cls   : scrollStart
      });
      
      this.imgRange[scrollStart].left     -= this.width;
      this.scrollRange[scrollStart].start -= this.browser.length;
    }
    
    if (this.imgRange[scrollStart].right + this.left < this.scrollBuffer * this.width) {
      var start = this.scrollRange[scrollStart].end + 1;
      
      this.makeImage({
        scale : this.scale,
        start : start,
        end   : start + this.browser.length - 1,
        left  : this.imgRange[scrollStart].right,
        cls   : scrollStart
      });
      
      this.imgRange[scrollStart].right  += this.width;
      this.scrollRange[scrollStart].end += this.browser.length;
    }
  },
  
  moveTo: function (start, end, delta) {
    var scrollRange = this.scrollRange[this.scrollStart];
    var scrollStart = 'ss_' + start + '_' + end;
    
    if (this.scrollRange[scrollStart] || start > scrollRange.end || end < scrollRange.start) {
      this.resetImageRanges();
      this.makeFirstImage(scrollStart);
    } else {
      this.move(typeof delta === 'number' ? delta : (start - this.browser.start) * this.scale);
      this.checkHeight();
    }
  },
  
  makeImage: function (params) {
    params.scaledStart   = params.scaledStart   || params.start * params.scale;
    params.width         = params.width         || this.width;
    params.height        = params.height        || this.prop('height');
    params.featureHeight = params.featureHeight || 0;
    params.labelHeight   = params.labelHeight   || 0;
    
    var deferred;
    var controller = this;
    var tooLarge   = this.browser.length > this.threshold;
    var div        = this.imgContainer.clone().addClass((params.cls + ' loading').replace('.', '_')).css({ left: params.left, display: params.cls === this.scrollStart ? 'block' : 'none' });
    var bgImage    = params.background ? $('<img class="bg">').hide().addClass(params.background).data(params).prependTo(div) : false;
    var image      = $('<img class="data">').hide().data(params).appendTo(div).on('load', function () {
      $(this).fadeIn('fast').parent().removeClass('loading');
      $(this).siblings('.bg').show();
    });
    
    params.container = div;
    
    this.imgContainers.push(div[0]);
    this.scrollContainer.append(this.imgContainers);
    
    if (!tooLarge && !this.model.checkDataRange(params.start, params.end)) {
      var buffer = this.prop('dataBuffer');
      
      params.start -= buffer.start;
      params.end   += buffer.end;
      deferred      = this.model.getData(params.start, params.end);
    }
    
    if (!deferred) {
      deferred = $.Deferred();
      setTimeout($.proxy(deferred.resolve, this), 1); // This defer makes scrolling A LOT smoother, pushing render call to the end of the exec queue
    }
    
    return deferred.done(function () {
      var features = tooLarge ? [] : controller.model.findFeatures(params.start, params.end);
      controller.render(features, image);
      
      if (bgImage) {
        controller.renderBackground(features, bgImage);
      }
    }).fail(function (e) {
      controller.showError(e);
    });
  },
  
  makeFirstImage: function (moveTo) {
    if (this.scrollContainer.children().hide().filter('.' + (moveTo || this.scrollStart)).show().length) {
      if (moveTo) {
        this.scrollContainer.css('left', 0);
      }
      
      return this.checkHeight();
    }
    
    var controller = this;
    var start      = this.browser.start;
    var end        = this.browser.end;
    var length     = this.browser.length;
    var scale      = this.scale;
    var cls        = this.scrollStart;
    var images     = [{ start: start, end: end, scale: scale, cls: cls, left: 0 }];
    var left       = 0;
    var width      = this.width;
    
    if (start > 1) {
      images.push({ start: start - length, end: start - 1, scale: scale, cls: cls, left: -this.width });
      left   = -this.width;
      width += this.width;
    }
    
    if (end < this.browser.chromosomeSize) {
      images.push({ start: end + 1, end: end + length, scale: scale, cls: cls, left: this.width });
      width += this.width;
    }
    
    var loading = this.imgContainer.clone().addClass('loading').css({ left: left, width: width }).prependTo(this.scrollContainer.css('left', 0));
    
    function makeImages() {
      for (var i = 0; i < images.length; i++) {
        controller.makeImage(images[i]);
      }
      
      loading.remove();
    }
    
    // FIXME: on zoom out, making more than 1 request
    if (length > this.threshold || this.model.checkDataRange(start, end)) {
      makeImages();
    } else {
      var buffer = this.prop('dataBuffer');
      
      this.model.getData(start - buffer.start - length, end + buffer.end + length).done(makeImages).fail(function (e) {
        controller.showError(e);
      });
    }
  },
  
  render: function (features, img) {
    var params         = img.data();
        features       = this.view.positionFeatures(this.view.scaleFeatures(features, params.scale), params); // positionFeatures alters params.featureHeight, so this must happen before the canvases are created
    var featureCanvas  = $('<canvas>').attr({ width: params.width, height: params.featureHeight || 1 });
    var labelCanvas    = this.prop('labels') === 'separate' && params.labelHeight ? featureCanvas.clone().attr('height', params.labelHeight) : featureCanvas;
    var featureContext = featureCanvas[0].getContext('2d');
    var labelContext   = labelCanvas[0].getContext('2d');
    
    featureContext.font = labelContext.font = this.prop('font');
    
    switch (this.prop('labels')) {
      case false     : break;
      case 'overlay' : labelContext.textAlign = 'center'; labelContext.textBaseline = 'middle'; break;
      default        : labelContext.textAlign = 'left';   labelContext.textBaseline = 'top';    break;
    }
    
    this.view.draw(features, featureContext, labelContext, params.scale);
    
    img.attr('src', featureCanvas[0].toDataURL());
    
    if (labelContext !== featureContext) {
      img.clone(true).attr({ 'class': 'labels', src: labelCanvas[0].toDataURL() }).insertAfter(img);
    }
    
    this.checkHeight();
    
    featureCanvas = labelCanvas = img = null;
  },
  
  renderBackground: function (features, img, height) {
    var canvas = $('<canvas>').attr({ width: this.width, height: height || 1 })[0];
    this.view.drawBackground(features, canvas.getContext('2d'), img.data());
    img.attr('src', canvas.toDataURL());
    canvas = img = null;
  },
  
  populateMenu: function (feature) {
    return feature;
  },
  
  destroy: function () {
    this.container.add(this.label).add(this.menus).remove();
  }
});




Genoverse.Track.Model = Base.extend({
  dataBuffer : { start: 0, end: 0 }, // basepairs to extend data region for, when getting data from the origin
  xhrFields  : {},
  dataType   : 'json',
  allData    : false,
  url        : undefined,
  urlParams  : {}, // hash of URL params
  
  constructor: function (properties) {
    $.extend(this, properties);
    Genoverse.wrapFunctions(this);
    this.init();
  },
  
  init: function (reset) {
    this.setDefaults(reset);
    
    if (reset) {
      for (var i in this.featuresById) {
        delete this.featuresById[i].position;
      }
    } else {
      this.dataRanges   = new RTree();
      this.features     = new RTree();
      this.featuresById = {};
    }
    
    this.dataLoading = []; // tracks incomplete requests for data
  },
  
  setDefaults: function (reset) {
    if (!this._url) {
      this._url = this.url; // Remember original url
    }
    
    if (this.url || (this._url && reset)) {
      this.setURL(undefined, reset);
    }
  },
  
  setURL: function (urlParams, update) {
    urlParams = urlParams || this.urlParams;
    
    if (update && this._url) {
      this.url = this._url;
    }

    this.url += (this.url.indexOf('?') === -1 ? '?' : '&') + decodeURIComponent($.param(urlParams, true));
    this.url  = this.url.replace(/[&?]$/, '');
  },
  
  parseURL: function (start, end, url) {
    if (this.allData) {
      start = 1;
      end   = this.browser.chromosomeSize;
    }
    
    return (url || this.url).replace(/__CHR__/, this.browser.chr).replace(/__START__/, start).replace(/__END__/, end);
  },
  
  setLabelBuffer: function (buffer) {
    this.dataBuffer.start = Math.max(this.dataBuffer.start, buffer);
  },
  
  getData: function (start, end, done) {
    start = Math.max(1, start);
    end   = Math.min(this.browser.chromosomeSize, end);
    
    var model    = this;
    var deferred = $.Deferred();
    var bins     = [];
    var length   = end - start + 1;
    
    if (!this.url) {
      return deferred.resolveWith(this);
    }
   
    if (this.dataRequestLimit && length > this.dataRequestLimit) {
      var i = Math.ceil(length / this.dataRequestLimit);
     
      while (i--) {
        bins.push([ start, i ? start += this.dataRequestLimit - 1 : end ]);
        start++;
      }
    } else {
      bins.push([ start, end ]);
    }
   
    $.when.apply($, $.map(bins, function (bin) {
      var request = $.ajax({
        url       : model.parseURL(bin[0], bin[1]),
        dataType  : model.dataType,
        context   : model,
        xhrFields : model.xhrFields,
        success   : function (data) { this.receiveData(data, bin[0], bin[1]); },
        error     : function (xhr, statusText) { this.track.controller.showError(statusText + ' while getting the data, see console for more details', arguments); },
        complete  : function (xhr) { this.dataLoading = $.grep(this.dataLoading, function (t) { return xhr !== t; }); }
      });
      
      request.coords = [ bin[0], bin[1] ]; // store actual start and end on the request, in case they are needed
      
      if (typeof done === 'function') {
        request.done(done);
      }
      
      model.dataLoading.push(request);
      
      return request;
    })).done(function () { deferred.resolveWith(model); });
    
    return deferred;
  },
  
  receiveData: function (data, start, end) {
    start = Math.max(start, 1);
    end   = Math.min(end, this.browser.chromosomeSize);
    
    this.setDataRange(start, end);
    this.parseData(data, start, end);
    
    if (this.allData) {
      this.url = false;
    }
  },
  
  /**
  * parseData(data, start, end) - parse raw data from the data source (e.g. online web service)
  * extract features and insert it into the internal features storage (RTree)
  *
  * >> data  - raw data from the data source (e.g. ajax response)
  * >> start - start location of the data
  * >> end   - end   location of the data
  * << nothing
  *
  * every feature extracted this routine must construct a hash with at least 3 values:
  *  {
  *    id    : [unique feature id, string],
  *    start : [chromosomal start position, integer],
  *    end   : [chromosomal end position, integer],
  *    [other optional key/value pairs]
  *  }
  *
  * and call this.insertFeature(feature)
  */
  parseData: function (data, start, end) {
    // Example of parseData function when data is an array of hashes like { start: ..., end: ... }
    for (var i = 0; i < data.length; i++) {
      var feature = data[i];
      
      feature.sort = start + i;
      
      this.insertFeature(feature);
    }
  },
  
  setDataRange: function (start, end) {
    if (this.allData) {
      start = 1;
      end   = this.browser.chromosomeSize;
    }
    
    this.dataRanges.insert({ x: start, w: end - start + 1, y: 0, h: 1 }, [ start, end ]);
  },
  
  checkDataRange: function (start, end) {
    start = Math.max(1, start);
    end   = Math.min(this.browser.chromosomeSize, end);
    
    var ranges = this.dataRanges.search({ x: start, w: end - start + 1, y: 0, h: 1 }).sort(function (a, b) { return a[0] - b[0]; });
    
    if (!ranges.length) {
      return false;
    }
    
    var s = ranges.length === 1 ? ranges[0][0] : 9e99;
    var e = ranges.length === 1 ? ranges[0][1] : -9e99;
    
    for (var i = 0; i < ranges.length - 1; i++) {
      // s0 <= s1 && ((e0 >= e1) || (e0 + 1 >= s1))
      if (ranges[i][0] <= ranges[i + 1][0] && ((ranges[i][1] >= ranges[i + 1][1]) || (ranges[i][1] + 1 >= ranges[i + 1][0]))) {
        s = Math.min(s, ranges[i][0]);
        e = Math.max(e, ranges[i + 1][1]);
      } else {
        return false;
      }
    }
    
    return start >= s && end <= e;
  },
  
  insertFeature: function (feature) {
    // Make sure we have a unique ID, this method is not efficient, so better supply your own id
    if (!feature.id) {
      feature.id = JSON.stringify(feature).hashCode();
    }
    
    if (!this.featuresById[feature.id]) {
      this.features.insert({ x: feature.start, y: 0, w: feature.end - feature.start + 1, h: 1 }, feature);
      this.featuresById[feature.id] = feature;
    }
  },
  
  findFeatures: function (start, end) {
    return this.features.search({ x: start - this.dataBuffer.start, y: 0, w: end - start + this.dataBuffer.start + this.dataBuffer.end + 1, h: 1 }).sort(function (a, b) { return a.sort - b.sort; });
  },
  
  abort: function () {
    for (var i = 0; i < this.dataLoading.length; i++) {
      this.dataLoading[i].abort();
    }
    
    this.dataLoading = [];
  }
});




Genoverse.Track.View = Base.extend({
  featureMargin  : { top: 3, right: 1, bottom: 1, left: 0 }, // left is never used
  fontHeight     : 10,
  fontFamily     : 'sans-serif',
  fontWeight     : 'normal',
  fontColor      : '#000000',
  color          : '#000000',
  minScaledWidth : 0.5,
  labels         : true,
  repeatLabels   : false,
  bump           : false,
  depth          : undefined,
  featureHeight  : undefined, // defaults to track height
  
  constructor: function (properties) {
    $.extend(this, properties);
    Genoverse.wrapFunctions(this);
    this.init();
  },
  
  // difference between init and constructor: init gets called on reset, if reset is implemented
  init: function () {
    this.setDefaults();
    this.scaleSettings = {};
  },
  
  setDefaults: function () {
    var margin = [ 'Top', 'Right', 'Bottom', 'Left' ];
    
    for (var i = 0; i < margin.length; i++) {
      if (typeof this['featureMargin' + margin[i]] === 'number') {
        this.featureMargin[margin[i].toLowerCase()] = this['featureMargin' + margin[i]];
      }
    }
    
    this.context       = $('<canvas>')[0].getContext('2d');
    this.featureHeight = typeof this.featureHeight !== 'undefined' ? this.featureHeight : this.prop('defaultHeight');
    this.font          = this.fontWeight + ' ' + this.fontHeight + 'px ' + this.fontFamily;
    this.labelUnits    = [ 'bp', 'kb', 'Mb', 'Gb', 'Tb' ];
    
    if (this.labels && this.labels !== 'overlay' && (this.depth || this.bump === 'labels')) {
      this.labels = 'separate';
    }
  },
  
  setScaleSettings: function (scale) {
    var featurePositions, labelPositions;
    
    if (!this.scaleSettings[scale]) {
      featurePositions = featurePositions || new RTree();
      
      this.scaleSettings[scale] = {
        imgContainers    : $(),
        featurePositions : featurePositions,
        labelPositions   : this.labels === 'separate' ? labelPositions || new RTree() : featurePositions
      };
    }
    
    return this.scaleSettings[scale];
  },
  
  scaleFeatures: function (features, scale) {
    var add = Math.max(scale, 1);
    var feature;
    
    for (var i = 0; i < features.length; i++) {
      feature = features[i];
      
      if (!feature.position) {
        feature.position = {};
      }
      
      if (!feature.position[scale]) {
        feature.position[scale] = {
          start  : feature.start * scale,
          width  : Math.max((feature.end - feature.start) * scale + add, this.minScaledWidth),
          height : feature.height || this.featureHeight
        };
      }
    }
    
    return features;
  },
  
  positionFeatures: function (features, params) {
    params.margin = this.prop('margin');
    
    for (var i = 0; i < features.length; i++) {
      this.positionFeature(features[i], params);
    }
    
    params.width         = Math.ceil(params.width);
    params.height        = Math.ceil(params.height);
    params.featureHeight = Math.max(Math.ceil(params.featureHeight), this.prop('resizable') ? Math.max(this.prop('height'), this.prop('minLabelHeight')) : 0);
    params.labelHeight   = Math.ceil(params.labelHeight);
    
    return features;
  },
  
  positionFeature: function (feature, params) {
    var scale = params.scale;
    
    feature.position[scale].X = feature.position[scale].start - params.scaledStart; // FIXME: always have to reposition for X, in case a feature appears in 2 images. Pass scaledStart around instead?
    
    if (!feature.position[scale].positioned) {
      feature.position[scale].H = feature.position[scale].height + this.featureMargin.bottom;
      feature.position[scale].W = feature.position[scale].width + (feature.marginRight || this.featureMargin.right);
      feature.position[scale].Y = typeof feature.y === 'number' ? feature.y * feature.position[scale].H : this.featureMargin.top;
      
      if (feature.label) {
        if (typeof feature.label === 'string') {
          feature.label = feature.label.split('\n');
        }
        
        var context = this.context;
        
        feature.labelHeight = feature.labelHeight || (this.fontHeight + 2) * feature.label.length;
        feature.labelWidth  = feature.labelWidth  || Math.max.apply(Math, $.map(feature.label, function (l) { return Math.ceil(context.measureText(l).width); })) + 1;
        
        if (this.labels === true) {
          feature.position[scale].H += feature.labelHeight;
          feature.position[scale].W  = Math.max(feature.labelWidth, feature.position[scale].W);
        } else if (this.labels === 'separate' && !feature.position[scale].label) {
          feature.position[scale].label = {
            x: feature.position[scale].start,
            y: feature.position[scale].Y,
            w: feature.labelWidth,
            h: feature.labelHeight
          };
        }
      }
      
      var bounds = {
        x: feature.position[scale].start,
        y: feature.position[scale].Y,
        w: feature.position[scale].W,
        h: feature.position[scale].H + this.featureMargin.top
      };
      
      if (this.bump === true) {
        this.bumpFeature(bounds, feature, scale, this.scaleSettings[scale].featurePositions);
      }
      
      this.scaleSettings[scale].featurePositions.insert(bounds, feature);
      
      feature.position[scale].bottom = feature.position[scale].Y + feature.position[scale].H + params.margin;
      
      if (feature.position[scale].label) {
        var f = $.extend(true, {}, feature); // FIXME: hack to avoid changing feature.position[scale].Y in bumpFeature
        
        this.bumpFeature(feature.position[scale].label, f, scale, this.scaleSettings[scale].labelPositions);
        
        f.position[scale].label        = feature.position[scale].label;
        f.position[scale].label.bottom = f.position[scale].label.y + f.position[scale].label.h + params.margin;
        
        feature = f;
        
        this.scaleSettings[scale].labelPositions.insert(feature.position[scale].label, feature);
        
        params.labelHeight = Math.max(params.labelHeight, feature.position[scale].label.bottom);
      }
      
      feature.position[scale].positioned = true;
    }
    
    params.featureHeight = Math.max(params.featureHeight, feature.position[scale].bottom);
    params.height        = Math.max(params.height, params.featureHeight + params.labelHeight);
  },
  
  bumpFeature: function (bounds, feature, scale, tree) {
    var depth = 0;
    var bump;
    
    do {
      if (this.depth && ++depth >= this.depth) {
        if ($.grep(this.scaleSettings[scale].featurePositions.search(bounds), function (f) { return f.position[scale].visible !== false; }).length) {
          feature.position[scale].visible = false;
        }
        
        break;
      }
      
      bump = false;
      
      if ((tree.search(bounds)[0] || feature).id !== feature.id) {
        bounds.y += bounds.h;
        bump      = true;
      }
    } while (bump);
    
    feature.position[scale].Y = bounds.y;
  },
  
  draw: function (features, featureContext, labelContext, scale) {
    var feature;
    
    for (var i = 0; i < features.length; i++) {
      feature = features[i];
      
      if (feature.position[scale].visible !== false) {
        // TODO: extend with feature.position[scale], rationalize keys
        this.drawFeature($.extend({}, feature, {
          x             : feature.position[scale].X,
          y             : feature.position[scale].Y,
          width         : feature.position[scale].width,
          height        : feature.position[scale].height,
          labelPosition : feature.position[scale].label
        }), featureContext, labelContext, scale);
      }
    }
  },
  
  drawFeature: function (feature, featureContext, labelContext, scale) {
    if (feature.x < 0 || feature.x + feature.width > this.width) {
      this.truncateForDrawing(feature);
    }
    
    if (feature.color !== false) {
      if (!feature.color) {
        this.setFeatureColor(feature);
      }
      
      featureContext.fillStyle = feature.color;
      featureContext.fillRect(feature.x, feature.y, feature.width, feature.height);
    }
    
    if (this.labels && feature.label) {
      this.drawLabel(feature, labelContext, scale);
    }
    
    if (feature.borderColor) {
      featureContext.strokeStyle = feature.borderColor;
      featureContext.strokeRect(feature.x, feature.y + 0.5, feature.width, feature.height);
    }
    
    if (feature.decorations) {
      this.decorateFeature(feature, featureContext, scale);
    }
  },
  
  drawLabel: function (feature, context, scale) {
    var original = feature.untruncated;
    var width    = (original || feature).width;
    
    if (this.labels === 'overlay' && feature.labelWidth >= width) {
      return;
    }
    
    if (typeof feature.label === 'string') {
      feature.label = [ feature.label ];
    }
    
    var x       = (original || feature).x;
    var n       = this.repeatLabels && !feature.labelPosition ? Math.ceil((width - (this.labels === 'overlay' ? feature.labelWidth : 0)) / this.width) : 1;
    var spacing = width / n;
    var label, start, j, y, h;
    
    if (!feature.labelColor) {
      this.setLabelColor(feature);
    }
    
    context.fillStyle = feature.labelColor;
    
    if (this.labels === 'overlay') {
      label = [ feature.label.join(' ') ];
      y     = feature.y + (feature.height + 1) / 2;
      h     = 0;
    } else {
      label = feature.label;
      y     = feature.labelPosition ? feature.labelPosition.y : feature.y + feature.height + this.featureMargin.bottom;
      h     = this.fontHeight + 2;
    }
    
    var i      = context.textAlign === 'center' ? 0.5 : 0;
    var offset = feature.labelWidth * i;
    
    for (; i < n; i++) {
      start = x + (i * spacing);
      
      if (start + feature.labelWidth >= 0) {
        if (start - offset > this.width) {
          break;
        }
        
        for (j = 0; j < label.length; j++) {
          context.fillText(label[j], start, y + (j * h));
        }
      }
    }
  },
  
  setFeatureColor: function (feature) {
    feature.color = this.color;
  },
  
  setLabelColor: function (feature) {
    feature.labelColor = feature.color || this.fontColor || this.color;
  },
  
  // truncate features - make the features start at 1px outside the canvas to ensure no lines are drawn at the borders incorrectly
  truncateForDrawing: function (feature) {
    var start = Math.min(Math.max(feature.x, -1), this.width + 1);
    var width = feature.x - start + feature.width;
    
    if (width + start > this.width) {
      width = this.width - start + 1;
    }
    
    feature.untruncated = { x: feature.x, width: feature.width };
    feature.x           = start;
    feature.width       = Math.max(width, 0);
  },
  
  formatLabel: function (label) {
    var power = Math.floor((label.toString().length - 1) / 3);
    var unit  = this.labelUnits[power];
    
    label /= Math.pow(10, power * 3);
    
    return Math.floor(label) + (unit === 'bp' ? '' : '.' + (label.toString().split('.')[1] || '').concat('00').substring(0, 2)) + ' ' + unit;
  },
  
  drawBackground  : $.noop,
  decorateFeature : $.noop // decoration for the features
});



Genoverse.Track.Controller.Static = Genoverse.Track.Controller.extend({
  constructor: function (properties) {
    this.base(properties);
    
    this.image = $('<img>').appendTo(this.imgContainer);
    this.container.toggleClass('track_container track_container_static').html(this.imgContainer);
  },
  
  reset: $.noop,
  
  setWidth: function (width) {
    this.base(width);
    this.image.width = width;
  },
  
  makeFirstImage: function () {
    this.base.apply(this, arguments);
    this.container.css('left', 0);
    this.imgContainer.show();
  },
  
  makeImage: function (params) {
    var features = this.view.positionFeatures(this.model.findFeatures(params.start, params.end), params);
    
    if (features) {
      var string = JSON.stringify(features);
      
      if (this.stringified !== string) {
        var height = this.prop('height');
        
        params.width         = this.width;
        params.featureHeight = height;
        
        this.render(features, this.image.data(params));
        this.imgContainer.children(':last').show();
        this.resize(height);
        
        this.stringified = string;
      }
    }
    
    return $.Deferred().resolve();
  }
});

Genoverse.Track.Model.Static = Genoverse.Track.Model.extend({
  url            : false,
  checkDataRange : function () { return true; }
});

Genoverse.Track.View.Static = Genoverse.Track.View.extend({
  featureMargin : { top: 0, right: 1, bottom: 0, left: 1 },
  
  positionFeature : $.noop,
  scaleFeatures   : function (features) { return features; },
  
  draw: function (features, featureContext, labelContext, scale) {
    for (var i = 0; i < features.length; i++) {
      this.drawFeature(features[i], featureContext, labelContext, scale);
    }
  }
});

Genoverse.Track.Static = Genoverse.Track.extend({
  controls   : 'off',
  resizable  : false,
  controller : Genoverse.Track.Controller.Static,
  model      : Genoverse.Track.Model.Static,
  view       : Genoverse.Track.View.Static
});




Genoverse.Track.Controller.Stranded = Genoverse.Track.Controller.extend({
  constructor: function (properties) {
    this.base(properties);
    
    if (typeof this._makeImage === 'function') {
      return;
    }
    
    var strand        = this.prop('strand');
    var featureStrand = this.prop('featureStrand');
    
    if (strand === -1) {
      this._makeImage = this.track.makeReverseImage ? $.proxy(this.track.makeReverseImage, this) : this.makeImage;
      this.makeImage  = $.noop;
    } else {
      strand = this.prop('strand', 1);
      
      this._makeImage   = this.makeImage;
      this.makeImage    = this.makeForwardImage;
      this.reverseTrack = this.browser.addTrack(this.track.constructor.extend({ strand: -1, url: false, forwardTrack: this }), this.browser.tracks.length).controller;
    }
    
    if (!featureStrand) {
      this.prop('featureStrand', strand);
    }
    
    if (!(this.model instanceof Genoverse.Track.Model.Stranded)) {
      this.track.lengthMap.push([ -9e99, { model: Genoverse.Track.Model.Stranded }]);
    }
  },
  
  makeForwardImage: function (params) {
    var reverseTrack = this.prop('reverseTrack');
    var rtn          = this._makeImage(params);
    
    if (rtn && typeof rtn.done === 'function') {
      rtn.done(function () {
        reverseTrack._makeImage(params, rtn);
      });
    } else {
      reverseTrack._makeImage(params, rtn);
    }
  },
  
  destroy: function () {
    if (this.removing) {
      return;
    }
    
    this.removing = true;
    
    this.browser.removeTrack((this.prop('forwardTrack') || this.prop('reverseTrack')).track);
    this.base();
  }
});



Genoverse.Track.Model.Stranded = Genoverse.Track.Model.extend({
  init: function (reset) {
    this.base(reset);
    
    if (!reset) {
      var otherTrack = this.prop('forwardTrack');
      
      if (otherTrack) {
        this.features     = otherTrack.prop('features');
        this.featuresById = otherTrack.prop('featuresById');
      }
    }
  },
  
  setURL: function (urlParams, update) {
    this.base($.extend(urlParams || this.urlParams, { strand: this.track.featureStrand }), update);
  },
  
  findFeatures: function () {
    var strand = this.track.featureStrand;
    return $.grep(this.base.apply(this, arguments), function (feature) { return feature.strand === strand; });
  }
});




Genoverse.Track.Scaleline = Genoverse.Track.Static.extend({
  strand     : 1,
  color      : '#000000',
  height     : 12,
  labels     : 'overlay',
  unsortable : true,
  
  resize: $.noop,
  
  makeFirstImage: function () {
    this.prop('scaleline', false);
    this.base.apply(this, arguments);
  },
  
  render: function (f, img) {
    this.base(f, img);
    this.prop('drawnScale', img.data('scale'));
  },
  
  positionFeatures: function (features, params) {
    var scaleline = this.prop('scaleline');
    
    if (params.scale === this.drawnScale) {
      return false;
    } else if (scaleline) {
      return scaleline;
    }
    
    var strand = this.prop('strand');
    var height = this.prop('height');
    var text   = this.formatLabel(this.browser.length);
    var text2  = strand === 1 ? 'Forward strand' : 'Reverse strand';
    var width1 = this.context.measureText(text).width;
    var width2 = this.context.measureText(text2).width;
    var bg     = this.browser.colors.background;
    var x1, x2;
    
    if (strand === 1) {
      x1 = 0;
      x2 = this.width - width2 - 40;
    } else {
      x1 = 25;
      x2 = 30;
    }
    
    scaleline = [
      { x: x1,                             y: height / 2, width: this.width - 25, height: 1, decorations: true },
      { x: (this.width - width1 - 10) / 2, y: 0,          width: width1 + 10,     height: height, color: bg, labelColor: this.color, labelWidth: width1, label: text  },
      { x: x2,                             y: 0,          width: width2 + 10,     height: height, color: bg, labelColor: this.color, labelWidth: width2, label: text2 }
    ];
    
    return this.base(this.prop('scaleline', scaleline), params);
  },
  
  decorateFeature: function (feature, context) {
    var strand = this.prop('strand');
    var height = this.prop('height');
    var x      = strand === 1 ? this.width - 25 : 25;
    
    context.strokeStyle = this.color;
    
    context.beginPath();
    context.moveTo(x,                 height * 0.25);
    context.lineTo(x + (strand * 20), height * 0.5);
    context.lineTo(x,                 height * 0.75);
    context.closePath();
    context.stroke();
    context.fill();
  }
});



Genoverse.Track.Scalebar = Genoverse.Track.extend({
  unsortable     : true,
  order          : 1,
  orderReverse   : 1e5,
  featureStrand  : 1,
  controls       : 'off',
  height         : 20,
  featureHeight  : 3,
  featureMargin  : { top: 0, right: 0, bottom: 2, left: 0 },
  margin         : 0,
  minPixPerMajor : 100, // Least number of pixels per written number
  color          : '#000000',
  autoHeight     : false,
  labels         : true,
  bump           : false,
  resizable      : false,
  colors         : {
    majorGuideLine : '#CCCCCC',
    minorGuideLine : '#E5E5E5'
  },
  
  setScale: function () {
    var max       = this.prop('width') / this.prop('minPixPerMajor');
    var divisor   = 5;
    var majorUnit = -1;
    var fromDigit = ('' + this.browser.start).split(''); // Split into array of digits
    var toDigit   = ('' + this.browser.end).split('');
    var divisions, i;
    
    for (i = fromDigit.length; i < toDigit.length; i++) {
      fromDigit.unshift('0');
    }
    
    for (i = toDigit.length; i < fromDigit.length; i++) {
      toDigit.unshift('0');
    }
    
    // How many divisions would there be if we only kept i digits?
    for (i = 0; i < fromDigit.length; i++) {
      divisions = parseInt(toDigit.slice(0, fromDigit.length - i).join(''), 10) - parseInt(fromDigit.slice(0, fromDigit.length - i).join(''), 10);
      
      if (divisions && divisions <= max) {
        majorUnit = parseInt('1' + $.map(new Array(i), function () { return '0'; }).join(''), 10);
        break;
      }
    }
    
    if (majorUnit === -1) {
      majorUnit = parseInt('1' + $.map(new Array(fromDigit.length), function () { return '0'; }).join(''), 10);
      divisor   = 1;
    } else {
      // Improve things by trying simple multiples of 1<n zeroes>.
      // (eg if 100 will fit will 200, 400, 500).
      if (divisions * 5 <= max) {
        majorUnit /= 5;
        divisor    = 2;
      } else if (divisions * 4 <= max) {
        majorUnit /= 4;
        divisor    = 1;
      } else if (divisions * 2 <= max) {
        majorUnit /= 2;
      }
    }
    
    majorUnit = Math.max(majorUnit, 1);
    
    this.prop('minorUnit',    Math.max(majorUnit / divisor, 1));
    this.prop('majorUnit',    majorUnit);
    this.prop('features',     new RTree());
    this.prop('featuresById', {});
    this.prop('seen',         {});
    
    this.base();
  },
  
  setFeatures: function (start, end) {
    var minorUnit = this.prop('minorUnit');
    var majorUnit = this.prop('majorUnit');
    var seen      = this.prop('seen');
    
    start = Math.max(start - (start % minorUnit) - majorUnit, 0);
    
    var flip  = (start / minorUnit) % 2 ? 1 : -1;
    var feature, major, label;
    
    for (var x = start; x < end + minorUnit; x += minorUnit) {
      flip *= -1;
      
      if (seen[x]) {
        continue;
      }
      
      seen[x] = 1;
      
      feature = { id: x, strand: 1, sort: x };
      major   = x && x % majorUnit === 0;
      
      if (flip === 1) {
        feature.start = x;
        feature.end   = x + minorUnit - 1;
      }
      
      if (major) {
        label = this.track.view.formatLabel(x);
        
        if (label !== this.lastLabel) {
          feature.label = label;
          
          if (!feature.end) {
            feature.start = x;
            feature.end   = x - 1;
          }
        }
        
        this.lastLabel = label;
      }
      
      if (feature.end) {
        this.insertFeature(feature);
      }
    }
  },
  
  makeFirstImage: function (moveTo) {
    if (this.prop('strand') === -1) {
      moveTo = this.track.forwardTrack.scrollStart;
    }
    
    return this.base(moveTo);
  },
  
  makeImage: function (params) {
    params.background    = 'guidelines fullHeight';
    params.featureHeight = this.prop('height');
    
    this.track.setFeatures.apply(this.track.model, [ params.start, params.end ]);
    
    var rtn = this.base(params);
    
    params.container.addClass('fullHeight');
    
    return rtn;
  },
  
  makeReverseImage: function (params) {
    this.imgContainers.push(params.container.clone().html(params.container.children('.data').clone(true).css('background', '#FFF'))[0]);
    this.scrollContainer.append(this.imgContainers);
  },
  
  renderBackground: function (f, bgImage) {
    this.base(f, bgImage);
    bgImage.height(this.browser.wrapper.outerHeight(true));
  },
  
  draw: function (features, featureContext, labelContext, scale) {
    var i         = features.length;
    var minorUnit = this.prop('minorUnit');
    var width     = Math.ceil(minorUnit * scale);
    var feature, start;
    
    featureContext.textBaseline = 'top';
    featureContext.fillStyle    = this.color;
    
    this.guideLines = { major: {} }; // FIXME: pass params to draw, rather than scale. set guideLines on params
    
    while (i--) {
      feature = features[i];
      start   = Math.round(feature.position[scale].X);
      
      this.drawFeature($.extend({}, feature, {
        x      : start,
        y      : 0,
        width  : Math.ceil(feature.position[scale].width),
        height : this.featureHeight
      }), featureContext, labelContext, scale);
      
      if (feature.label) {
        if (start > -1) {
          featureContext.fillRect(start, this.featureHeight, 1, this.featureHeight);
        }
        
        this.guideLines.major[feature.start] = true;
      }
      
      this.guideLines[feature.start] = start;
      this.guideLines[feature.start + minorUnit] = start + width - 1;
    }
    
    featureContext.fillRect(0, 0, featureContext.canvas.width, 1);
    featureContext.fillRect(0, this.featureHeight, featureContext.canvas.width, 1);
  },
  
  // Draw guidelines
  drawBackground: function (f, context) {
    for (var i in this.guideLines) {
      if (this.guideLines[i] >= 0 && this.guideLines[i] <= this.width) {
        context.fillStyle = this.track.colors[this.guideLines.major[i] ? 'majorGuideLine' : 'minorGuideLine' ];
        context.fillRect(this.guideLines[i], 0, 1, context.canvas.height);
      }
    }
  },
  
  formatLabel: function (label) {
    return this.prop('minorUnit') < 1000 ? label.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1,') : this.base(label);
  }
});

Genoverse.Track.on('afterResize', function () {
  $('.bg.fullHeight', this.browser.container).height(this.browser.wrapper.outerHeight(true));
});

Genoverse.on('afterAddTracks', function () {
  $('.bg.fullHeight', this.container).height(this.wrapper.outerHeight(true));
});



// Abstract Sequence model
// assumes that the data source responds with raw sequence text
// see Fasta model for more specific example
Genoverse.Track.Model.Sequence = Genoverse.Track.Model.extend({
  threshold : 100000,  
  chunkSize : 1000,
  buffer    : 0,
  dataType  : 'text',
  
  init: function () {
    this.base();
    this.chunks = {};
  },
  
  getData: function (start, end) {
    var start = start - start % this.chunkSize + 1;
    var end  = end + this.chunkSize - end % this.chunkSize;    
    return this.base(start, end);
  },
  
  parseData: function (data, start, end) {
    data = data.replace(/\n/g, '');
    
    if (this.prop('lowerCase')) {
      data = data.toLowerCase();
    }
    
    for (var i = 0; i < data.length; i += this.chunkSize) {
      if (this.chunks[start + i]) {
        continue;
      }
      
      var feature = {
        id       : start + i,
        start    : start + i,
        end      : start + i + this.chunkSize,
        sequence : data.substr(i, this.chunkSize),
      };
      
      this.chunks[feature.start] = feature;
      this.insertFeature(feature);
    }
  }
});



Genoverse.Track.Model.Sequence.Fasta = Genoverse.Track.Model.Sequence.extend({
  url  : 'http://genoverse.org/data/Homo_sapiens.GRCh37.72.dna.chromosome.1.fa', // Example url
  
  // Following settings could be left undefined and will be detected automatically via .getStartByte()
  startByte  : undefined, // Byte in the file where the sequence actually starts
  lineLength : undefined, // Length of the sequence line in the file
  
  // TODO: Check if URL provided
  
  getData: function (start, end) {
    var deferred = $.Deferred();
    
    $.when(this.getStartByte()).done(function () {
      start = start - start % this.chunkSize + 1;
      end   = end + this.chunkSize - end % this.chunkSize;
      
      var startByte = start - 1 + Math.floor((start - 1) / this.lineLength) + this.startByte;
      var endByte   = end   - 1 + Math.floor((end   - 1) / this.lineLength) + this.startByte;
      
      $.ajax({
        url       : this.parseURL(start, end),
        dataType  : this.dataType,
        context   : this,
        headers   : { 'Range' : 'bytes=' + startByte + '-' + endByte },
        xhrFields : this.xhrFields,
        success   : function (data) { this.receiveData(data, start, end); },
        error     : this.track.controller.showError
      }).done(function () { deferred.resolveWith(this); }).fail(function () { deferred.rejectWith(this); });
    }).fail(function () { deferred.rejectWith(this); });
    
    return deferred;
  },
  
  getStartByte: function () {
    if (this.startByteRequest) {
      return this.startByteRequest;
    }
    
    if (this.startByte === undefined || this.lineLength === undefined) {
      this.startByteRequest = $.ajax({
        url       : this.parseURL(),
        dataType  : 'text',
        context   : this,
        headers   : { 'Range': 'bytes=0-300' },
        xhrFields : this.xhrFields,        
        success   : function (data) {
          if (data.indexOf('>') === 0) {
            this.startByte = data.indexOf('\n') + 1;
          } else {
            this.startByte = 0;
          }
          
          this.lineLength = data.indexOf('\n', this.startByte) - this.startByte;
        }
      });
      
      return this.startByteRequest;
    }
  }
});




Genoverse.Track.Model.Sequence.Ensembl = Genoverse.Track.Model.Sequence.extend({
  url              : 'http://beta.rest.ensembl.org/sequence/region/human/__CHR__:__START__-__END__?content-type=text/plain', // Example url
  dataRequestLimit : 10000000 // As per e! REST API restrictions
});



Genoverse.Track.Model.Sequence.DAS = Genoverse.Track.Model.Sequence.extend({

  name     : 'DAS Sequence',
  dataType : 'xml',
  url      : 'http://www.ensembl.org/das/Homo_sapiens.GRCh37.reference/sequence?segment=__CHR__:__START__,__END__', // Example url

  parseData: function (data) {
    var track = this;
    $(data).find('SEQUENCE').each(function (index, SEQUENCE) {

      var sequence = $(SEQUENCE).text();
      var start = parseInt(SEQUENCE.getAttribute('start'));

      // Check if the sequence is multi-line or not
      if (track.multiLine === undefined) {
        if (sequence.indexOf("\n") !== -1) {
          track.multiLine = true;
        } else {
          track.multiLine = false;
        }
      }

      if (track.multiLine) {
        sequence = sequence.replace(/\n/g, "");
        sequence = sequence.toUpperCase();
      }

      track.base.apply(track, [ sequence, start ]);
    });
  },

});  



Genoverse.Track.View.Sequence = Genoverse.Track.View.extend({
  featureMargin : { top: 0, right: 0, bottom: 0, left: 0 },
  colors        : { 'default': '#CCCCCC', A: '#00986A', T: '#0772A1', G: '#FF8E00', C: '#FFDD73' },
  labelColors   : { 'default': '#000000', A: '#FFFFFF', T: '#FFFFFF' },
  
  constructor: function () {
    this.base.apply(this, arguments);
    
    var lowerCase = this.prop('lowerCase');
    
    this.labelWidth   = {};
    this.widestLabel  = lowerCase ? 'g' : 'G';
    this.labelYOffset = (this.featureHeight + (lowerCase ? 0 : 1)) / 2;
    
    if (lowerCase) {
      for (var key in this.colors) {
        this.colors[key.toLowerCase()] = this.colors[key];
      }
      
      for (key in this.labelColors) {
        this.colors[key.toLowerCase()] = this.colors[key];
      }      
    }
  },

  draw: function (features, featureContext, labelContext, scale) {
    featureContext.textBaseline = 'middle';
    featureContext.textAlign    = 'left';
    
    if (!this.labelWidth[this.widestLabel]) {
      this.labelWidth[this.widestLabel] = Math.ceil(this.context.measureText(this.widestLabel).width) + 1;
    }
    
    var width = Math.max(scale, this.minScaledWidth);
    
    for (var i = 0; i < features.length; i++) {
      this.drawSequence(features[i], featureContext, scale, width);
    }
  },
  
  drawSequence: function (feature, context, scale, width) {
    var drawLabels = this.labelWidth[this.widestLabel] < width - 1;
    var start, bp;
    
    for (var i = 0; i < feature.sequence.length; i++) {
      start = feature.position[scale].X + i * scale;
      
      if (start < -scale || start > context.canvas.width) {
        continue;
      }
      
      bp = feature.sequence.charAt(i);
      
      context.fillStyle = this.colors[bp] || this.colors['default'];
      context.fillRect(start, feature.position[scale].Y, width, this.featureHeight);
      
      if (!this.labelWidth[bp]) {
        this.labelWidth[bp] = Math.ceil(context.measureText(bp).width) + 1;
      }
      
      if (drawLabels) {
        context.fillStyle = this.labelColors[bp] || this.labelColors['default'];
        context.fillText(bp, start + (width - this.labelWidth[bp]) / 2, feature.position[scale].Y + this.labelYOffset);
      }
    }
  },
  
  click: $.noop
});



Genoverse.Track.Model.SequenceVariation = Genoverse.Track.Model.extend({
  // Nothing specific, all specisics are in the derived classes
});



Genoverse.Track.Model.SequenceVariation.VCF = Genoverse.Track.Model.SequenceVariation.extend({
  dataType: 'text',
  
  parseData: function (text) {
    var lines = text.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].length || lines[i].indexOf('#') === 0) {
        continue;
      }
      
      var fields = lines[i].split('\t');
      
      if (fields.length < 5) {
        continue;
      }
      
      if (fields[0] === this.browser.chr || fields[0] === 'chr' + this.browser.chr) {
        var id      = fields.slice(0, 3).join('|');
        var start   = parseInt(fields[1], 10);
        var alleles = fields[4].split(',');
        
        alleles.unshift(fields[3]);
        
        for (var j = 0; j < alleles.length; j++) {
          var end = start + alleles[j].length - 1;
          
          this.insertFeature({
            id              : id + '|' + alleles[j],
            sort            : j,
            start           : start,
            end             : end,
            width           : end - start,
            allele          : j === 0 ? 'REF' : 'ALT',
            sequence        : alleles[j],
            label           : alleles[j],
            labelColor      : '#FFFFFF',
            originalFeature : fields
          });        
        }
      }
    }
  }
});



// Abstract Gene model
// see sub-models for more specific examples
Genoverse.Track.Model.Gene = Genoverse.Track.Model.extend({

});



// Ensembl REST API Gene model
Genoverse.Track.Model.Gene.Ensembl = Genoverse.Track.Model.Gene.extend({
  url              : 'http://beta.rest.ensembl.org/feature/region/human/__CHR__:__START__-__END__?feature=gene;content-type=application/json',
  dataRequestLimit : 5000000, // As per e! REST API restrictions
  
  // The url above responds in json format, data is an array
  // We assume that parents always preceed children in data array, gene -> transcript -> exon
  // See http://beta.rest.ensembl.org/documentation/info/feature_region for more details
  parseData: function (data) {
    for (var i = 0; i < data.length; i++) {
      var feature = data[i];
      
      if (feature.feature_type === 'gene' && !this.featuresById[feature.ID]) {
        feature.id          = feature.ID;
        feature.label       = feature.external_name || feature.id;
        feature.transcripts = [];
        
        this.insertFeature(feature);
      }
    }
  }
});




Genoverse.Track.View.Gene = Genoverse.Track.View.extend({
  featureHeight : 5,
  labels        : true,
  repeatLabels  : true,
  bump          : true
});




Genoverse.Track.View.Gene.Ensembl = Genoverse.Track.View.Gene.extend({
  setFeatureColor: function (feature) {
    var color = '#000000';
    
    if (feature.logic_name.indexOf('ensembl_havana') === 0) {
      color = '#cd9b1d';
    } else if (feature.biotype.indexOf('RNA') > -1) {
      color = '#8b668b';
    } else switch (feature.biotype) {
      case 'protein_coding'       : color = '#A00000'; break;
      case 'processed_transcript' : color = '#0000FF'; break;
      case 'antisense'            : color = '#0000FF'; break;
      case 'sense_intronic'       : color = '#0000FF'; break;
      case 'pseudogene'           :
      case 'processed_pseudogene' : color = '#666666'; break;
      default                     : color = '#A00000'; break;
    }
    
    feature.color = feature.labelColor = color;
  }
});



// Abstract Transcript model
// see sub-models for more specific examples
Genoverse.Track.Model.Transcript = Genoverse.Track.Model.extend({

});



// Ensembl REST API Transcript model
Genoverse.Track.Model.Transcript.Ensembl = Genoverse.Track.Model.Transcript.extend({
  url              : 'http://beta.rest.ensembl.org/feature/region/human/__CHR__:__START__-__END__?content-type=application/json',
  urlParams        : { feature: 'transcript' },
  dataRequestLimit : 5000000, // As per e! REST API restrictions
  
  // The url above responds in json format, data is an array
  // See http://beta.rest.ensembl.org/documentation/info/feature_region for more details
  parseData: function (data) {
    for (var i = 0; i < data.length; i++) {
      var feature = data[i];
      
      if (feature.feature_type === 'transcript' && !this.featuresById[feature.ID]) {
        feature.id    = feature.ID;
        feature.label = feature.id;
        feature.exons = [];
        feature.cds   = [];
        
        this.insertFeature(feature);
      } else if (feature.feature_type === 'exon' && this.featuresById[feature.Parent]) {
        feature.id = feature.ID;
        
        if (!this.featuresById[feature.Parent].exons[feature.id]) {
          this.featuresById[feature.Parent].exons.push(feature);
          this.featuresById[feature.Parent].exons[feature.id] = feature;
        }
      } else if (feature.feature_type === 'cds' && this.featuresById[feature.Parent]) {
        feature.id = feature.start + '-' + feature.end;
        
        if (!this.featuresById[feature.Parent].cds[feature.id]) {
          this.featuresById[feature.Parent].cds.push(feature);
          this.featuresById[feature.Parent].cds[feature.id] = feature;
        }
      }
    }
  },
  
  getData: function (start, end, dfd) {
    start = Math.max(1, start);
    end   = Math.min(this.browser.chromosomeSize, end);
    
    var deferred = dfd || $.Deferred();
    
    this.base(start, end, function (data, state, request) {
      if (dfd) {
        this.parseData(data, request.coords[0], request.coords[1]);
      } else { // Non modified (transcript) url, loop through the transcripts and see if any extend beyond start and end
        for (var i = 0; i < data.length; i++) {
          start = Math.min(start, data[i].start);
          end   = Math.max(end,   data[i].end);
        }
        
        this.receiveData(data, request.coords[0], request.coords[1]); 
      }
    }).done(function () {
      if (dfd) { // Now get me the exons and cds for start-end
        dfd.resolveWith(this);
      } else {
        this.setURL({ feature: [ 'exon', 'cds' ]}, true);
        this.getData(start, end, deferred);
        this.setURL(this.urlParams, true);
      }
    });
    
    return deferred;
  }
});



// Basic GFF3 model for transcripts
// See http://www.broadinstitute.org/annotation/gebo/help/gff3.html 
Genoverse.Track.Model.Transcript.GFF3 = Genoverse.Track.Model.Transcript.extend({
  dataType : 'text',
  
  // Transcript structure map for column 3 (type) 
  typeMap : {
    exon  : 'exon',
    cds   : 'cds'
  },
  
  parseData: function (text) {
    var lines = text.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].length || lines[i].indexOf('#') === 0) {
        continue;
      }
      
      var fields = lines[i].split('\t');
      
      if (fields.length < 5) {
        continue;
      }
      
      if (fields[0] === this.browser.chr || fields[0].toLowerCase() === 'chr' + this.browser.chr || fields[0].match('[^1-9]' + this.browser.chr + '$')) {
        var feature = {};
        
        feature.id     = fields.slice(0, 5).join('|');
        feature.start  = parseInt(fields[3], 10);
        feature.end    = parseInt(fields[4], 10);
        feature.source = fields[1];
        feature.type   = fields[2];
        feature.score  = fields[5];
        feature.strand = fields[6] + '1';
        
        if (fields[8]) {
          var frame = fields[8].split(';');
          
          for (var j = 0; j < frame.length; j++) {
            var keyValue = frame[j].split('=');
            
            if (keyValue.length === 2) {
              feature[keyValue[0].toLowerCase()] = keyValue[1];
            }
          }
        }
        
        // sub-feature came earlier than parent feature
        if (feature.parent && !this.featuresById[feature.parent]) {
          this.featuresById[feature.parent] = {
            exons : [],
            cds   : []
          };
        }
        
        if (feature.parent && feature.type.toLowerCase() === this.typeMap.exon.toLowerCase()) {
          if (!$.grep(this.featuresById[feature.parent].exons, function (exon) { return exon.id === feature.id; }).length) {
            this.featuresById[feature.parent].exons.push(feature);
          }
        } else if (feature.parent && feature.type.toLowerCase() === this.typeMap.cds.toLowerCase()) {
          if (!$.grep(this.featuresById[feature.parent].cds, function (exon) { return exon.id === feature.id; }).length) {
            this.featuresById[feature.parent].cds.push(feature);
          }
        } else if (!feature.parent) {
          feature.label = feature.name || feature.id || '';
          $.extend(feature, { label: feature.name || feature.id || '', exons: [], cds: [] }, this.featuresById[feature.id] || {});
          
          delete this.featuresById[feature.id];
          
          this.insertFeature(feature);
        }
      }
    }
  }
});



Genoverse.Track.View.Transcript = Genoverse.Track.View.extend({
  featureHeight : 10,
  labels        : true,
  repeatLabels  : true,
  bump          : true,
  intronStyle   : 'bezierCurve',
  lineWidth     : 0.5,
  
  drawFeature: function(transcript, featureContext, labelContext, scale) {
    this.setFeatureColor(transcript);
    
    var exons = (transcript.exons || []).sort(function (a, b) { return a.start - b.start; });
    var exon, cds, i;
    
    if (!exons.length || exons[0].start > transcript.start) {
      exons.unshift({ start: transcript.start, end: transcript.start });
    }
    
    if (!exons.length || exons[exons.length - 1].end < transcript.end) {
      exons.push({ start: transcript.end, end: transcript.end  });
    }
    
    for (i = 0; i < exons.length; i++) {
      exon = exons[i];
      
      featureContext.strokeStyle = exon.color || transcript.color || this.color;
      featureContext.lineWidth   = 1;
      
      featureContext.strokeRect(
        transcript.x + (exon.start - transcript.start) * scale,
        transcript.y + 1.5,
        Math.max(1, (exon.end - exon.start) * scale), 
        transcript.height - 3
      );
      
      if (i) {
        this.drawIntron({
          x: transcript.x + (exons[i - 1].end - transcript.start) * scale,
          y: transcript.y + transcript.height / 2 + 0.5,
          width: (exon.start - exons[i - 1].end) * scale,
          height: transcript.strand > 0 ? -transcript.height / 2 : transcript.height / 2,
        }, featureContext);
      }
    }

    if (transcript.cds && transcript.cds.length) {
      for (i = 0; i < transcript.cds.length; i++) {
        cds = transcript.cds[i];
        
        featureContext.fillStyle = cds.color || transcript.color || this.color;
        
        featureContext.fillRect(
          transcript.x + (cds.start - transcript.start) * scale,
          transcript.y, 
          Math.max(1, (cds.end - cds.start) * scale),
          transcript.height
        );
      }
    }
    
    if (this.labels && transcript.label) {
      this.drawLabel(transcript, labelContext, scale)
    }
  },  
  
  drawIntron: function (intron, context) {
    context.beginPath();
    context.lineWidth = this.lineWidth;
    
    switch (this.intronStyle) {
      case 'line':
        context.moveTo(intron.x, intron.y);
        context.lineTo(intron.x + intron.width, intron.y);
        break;
      case 'hat':
        context.moveTo(intron.x, intron.y);
        context.lineTo(intron.x + intron.width / 2, intron.y + intron.height);
        context.lineTo(intron.x + intron.width, intron.y);
        break;
      case 'bezierCurve':
        context.moveTo(intron.x, intron.y);
        context.bezierCurveTo(intron.x, intron.y + intron.height, intron.x + intron.width, intron.y + intron.height, intron.x + intron.width, intron.y);
        break;
      default: break;
    }
    
    context.stroke();
    context.closePath();
  }
});




Genoverse.Track.View.Transcript.Ensembl = Genoverse.Track.View.Transcript.extend({
  setFeatureColor: function (feature) {
    Genoverse.Track.View.Gene.Ensembl.prototype.setFeatureColor(feature);
  }
});



Genoverse.Track.Model.File = Genoverse.Track.Model.extend({
  dataType : 'text'
});



Genoverse.Track.Model.File.GFF = Genoverse.Track.Model.File.extend({
  parseData: function (text) {
    var lines = text.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].length || lines[i].indexOf('#') === 0) {
        continue;
      }
      
      var fields = lines[i].split('\t');

      if (fields.length < 5) {
        continue;
      }
      
      if (fields[0] === this.browser.chr || fields[0].toLowerCase() === 'chr' + this.browser.chr || fields[0].match('[^1-9]' + this.browser.chr + '$')) {
        this.insertFeature({
          id     : fields.slice(0, 5).join('|'),
          start  : parseInt(fields[3], 10),
          end    : parseInt(fields[4], 10),
          source : fields[1],
          type   : fields[2],
          score  : fields[5],
          strand : fields[6] + '1',
          label  : fields[1] + ' ' + fields[2] + ' ' + fields[3] + '-' + fields[4]
        });
      }
    }
  }
});

Genoverse.Track.Model.File.GTF = Genoverse.Track.Model.File.GFF;



Genoverse.Track.Model.File.BED = Genoverse.Track.Model.File.extend({
  parseData: function (text) {
    var lines = text.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].split('\t');
      
      if (fields.length < 3) {
        continue;
      }
      
      if (fields[0] === this.browser.chr || fields[0].toLowerCase() === 'chr' + this.browser.chr || fields[0].match('[^1-9]' + this.browser.chr + '$')) {
        var score = parseFloat(fields[4], 10);
        var color = '#000000';

        if (fields[8]) {
          color = 'rgb(' + fields[8] + ')';
        } else {
          color = this.scoreColor(isNaN(score) ? 1000 : score);
        }

        this.insertFeature({
          start           : parseInt(fields[1], 10),
          end             : parseInt(fields[2], 10),
          id              : fields[1] + '-' + fields[3],
          label           : fields[3],
          color           : color,
          originalFeature : fields
        });
      }
    }
  },  

  // As per https://genome.ucsc.edu/FAQ/FAQformat.html#format1 specification
  scoreColor: function (score) {
    if (score <= 166) { return 'rgb(219,219,219)'; }
    if (score <= 277) { return 'rgb(186,186,186)'; }
    if (score <= 388) { return 'rgb(154,154,154)'; }
    if (score <= 499) { return 'rgb(122,122,122)'; }
    if (score <= 611) { return 'rgb(94,94,94)';    }
    if (score <= 722) { return 'rgb(67,67,67)';    }
    if (score <= 833) { return 'rgb(42,42,42)';    }
    if (score <= 944) { return 'rgb(21,21,21)';    }
    return '#000000';
  }
});  



Genoverse.Track.File.GFF = Genoverse.Track.File.extend({
  name          : 'GFF',
  model         : Genoverse.Track.Model.File.GFF,
  bump          : true,
  height        : 100,
  featureHeight : 5
});

Genoverse.Track.File.GTF = Genoverse.Track.File.GFF;



Genoverse.Track.File.GFF3 = Genoverse.Track.File.extend({
  name  : 'GFF3',
  model : Genoverse.Track.Model.Transcript.GFF3,
  view  : Genoverse.Track.View.Transcript,
  bump  : true
});



Genoverse.Track.File.BED = Genoverse.Track.File.extend({
  name          : 'BED',
  model         : Genoverse.Track.Model.File.BED,
  bump          : true,
  featureHeight : 6,
  
  populateMenu: function (feature) {
    return {
      title       : '<a target=_blank href="https://genome.ucsc.edu/FAQ/FAQformat.html#format1">BED feature details</a>',
      chrom       : feature.originalFeature[0],
      chromStart  : feature.originalFeature[1],
      chromEnd    : feature.originalFeature[2],
      name        : feature.originalFeature[3],
      score       : feature.originalFeature[4],
      strand      : feature.originalFeature[5],
      thickStart  : feature.originalFeature[6],
      thickEnd    : feature.originalFeature[7],
      itemRgb     : feature.originalFeature[8],
      blockCount  : feature.originalFeature[9],
      blockSizes  : feature.originalFeature[10],
      blockStarts : feature.originalFeature[11]
    };
  }
});



Genoverse.Track.File.VCF = Genoverse.Track.File.extend({
  name       : 'VCF',
  model      : Genoverse.Track.Model.SequenceVariation.VCF,
  autoHeight : false,
  
  populateMenu: function (feature) {
    return {
      title  : '<a target="_blank" href="http://www.1000genomes.org/node/101">VCF feature details</a>',
      CHROM  : feature.originalFeature[0],
      POS    : feature.originalFeature[1],
      ID     : feature.originalFeature[2],
      REF    : feature.originalFeature[3],
      ALT    : feature.originalFeature[4],
      QUAL   : feature.originalFeature[5],
      FILTER : feature.originalFeature[6],
      INFO   : feature.originalFeature[7].split(';').join('<br />')
    };
  },
  
  1: { 
    view: Genoverse.Track.View.Sequence.extend({
      bump          : true,
      labels        : false,
      featureMargin : { top: 0, right: 0, bottom: 0, left: 0 },
      
      draw: function (features, featureContext, labelContext, scale) {
        this.base.apply(this, arguments);
        this.highlightRef(features, featureContext, scale);
      },

      highlightRef: function (features, context, scale) {
        context.strokeStyle = 'black';
        
        for (var i = 0; i < features.length; i++) {
          if (features[i].allele === 'REF') {
            context.strokeRect(features[i].position[scale].X, features[i].position[scale].Y, features[i].position[scale].width, features[i].position[scale].height);
          }
        }
      }
    })
  },
  
  1000: {
    view: Genoverse.Track.View.extend({
      bump   : false,
      labels : false,
      
      drawFeature: function (feature) {
        if (!feature.color) {
          var QUAL  = feature.originalFeature[5];
          var heat  = Math.min(255, Math.floor(255 * QUAL / this.maxQUAL)) - 127;
          var red   = heat > 0 ? 255 : 127 + heat;
          var green = heat < 0 ? 255 : 127 - heat;

          feature.color = 'rgb(' + red + ',' + green + ',0)';
        }
        
        this.base.apply(this, arguments);
      }
    })
  }
});





var thisScriptTag = $('script:last');          
var config = thisScriptTag.text();             
if (config) {                                  
  try {                                        
    config = eval('('+ config +')');           
    $(document).ready(function(){              
      window.genoverse = new Genoverse(config) 
    });                                        
  } catch (e) {                                
    throw('Configuration ERROR:' + e);         
  };                                           
}                                              
})();                                          
$.noConflict(true);