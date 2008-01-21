/**
   Copyright (c) 2005, Brad Neuberg, bkn3@columbia.edu
   http://codinginparadise.org

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
   OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
   THE USE OR OTHER DEALINGS IN THE SOFTWARE.

   The JSON class near the end of this file is
   Copyright 2005, JSON.org
*/

/** An object that provides DHTML history, history data, and bookmarking
    for AJAX applications. */
window.dhtmlHistory = {
   /** Initializes our DHTML history. You should
       call this after the page is finished loading. */
   /** public */ initialize: function() {
      // only Internet Explorer needs to be explicitly initialized;
      // other browsers don't have its particular behaviors.
      // Basicly, IE doesn't autofill form data until the page
      // is finished loading, which means historyStorage won't
      // work until onload has been fired.
      if (this.isInternetExplorer() == false) {
         return;
      }

      // if this is the first time this page has loaded...
      if (historyStorage.hasKey("DhtmlHistory_pageLoaded") == false) {
         this.fireOnNewListener = false;
         this.firstLoad = true;
         historyStorage.put("DhtmlHistory_pageLoaded", true);
      }
      // else if this is a fake onload event
      else {
         this.fireOnNewListener = true;
         this.firstLoad = false;
      }
   },

   /** Adds a history change listener. Note that
       only one listener is supported at this
       time. */
   /** public */ addListener: function(callback) {
      this.listener = callback;

      // if the page was just loaded and we
      // should not ignore it, fire an event
      // to our new listener now
      if (this.fireOnNewListener == true) {
         this.fireHistoryEvent(this.currentLocation);
         this.fireOnNewListener = false;
      }
   },

   /** public */ add: function(newLocation, historyData) {
      // most browsers require that we wait a certain amount of time before changing the
      // location, such as 200 milliseconds; rather than forcing external callers to use
      // window.setTimeout to account for this to prevent bugs, we internally handle this
      // detail by using a 'currentWaitTime' variable and have requests wait in line
      var self = this;
      var addImpl = function() {
         // indicate that the current wait time is now less
         if (self.currentWaitTime > 0)
            self.currentWaitTime = self.currentWaitTime - self.WAIT_TIME;

         // remove any leading hash symbols on newLocation
         newLocation = self.removeHash(newLocation);

         // IE has a strange bug; if the newLocation
         // is the same as _any_ preexisting id in the
         // document, then the history action gets recorded
         // twice; throw a programmer exception if there is
         // an element with this ID
         var idCheck = $(newLocation);
         if (idCheck != undefined || idCheck != null) {
            var message =
               "Exception: History locations can not have "
               + "the same value as _any_ id's "
               + "that might be in the document, "
               + "due to a bug in Internet "
               + "Explorer; please ask the "
               + "developer to choose a history "
               + "location that does not match "
               + "any HTML id's in this "
               + "document. The following ID "
               + "is already taken and can not "
               + "be a location: "
               + newLocation;

            throw message;
         }

         // store the history data into history storage
         historyStorage.put(newLocation, historyData);

         // indicate to the browser to ignore this upcomming
         // location change
         self.ignoreLocationChange = true;

         // indicate to IE that this is an atomic location change
         // block
         this.ieAtomicLocationChange = true;

         // save this as our current location
         self.currentLocation = newLocation;

         // change the browser location
         window.location.hash = newLocation;

         // change the hidden iframe's location if on IE
         if (self.isInternetExplorer())
            self.iframe.src = "/blank.html?" + newLocation;

         // end of atomic location change block
         // for IE
         this.ieAtomicLocationChange = false;
      };

      // now execute this add request after waiting a certain amount of time, so as to
      // queue up requests
      window.setTimeout(addImpl, this.currentWaitTime);

      // indicate that the next request will have to wait for awhile
      this.currentWaitTime = this.currentWaitTime + this.WAIT_TIME;
   },

   /** public */ isFirstLoad: function() {
      if (this.firstLoad == true) {
         return true;
      }
      else {
         return false;
      }
   },

   /** public */ isInternational: function() {
      return false;
   },

   /** public */ getVersion: function() {
      return "0.05";
   },

   /** Gets the current hash value that is in the browser's
       location bar, removing leading # symbols if they are present. */
   /** public */ getCurrentLocation: function() {
      var currentLocation = escape(this.removeHash(window.location.hash));

      return currentLocation;
   },





   /** Our current hash location, without the "#" symbol. */
   /** private */ currentLocation: null,

   /** Our history change listener. */
   /** private */ listener: null,

   /** A hidden IFrame we use in Internet Explorer to detect history
       changes. */
   /** private */ iframe: null,

   /** Indicates to the browser whether to ignore location changes. */
   /** private */ ignoreLocationChange: null,

   /** The amount of time in milliseconds that we should wait between add requests.
       Firefox is okay with 200 ms, but Internet Explorer needs 400. */
   /** private */ WAIT_TIME: 200,

   /** The amount of time in milliseconds an add request has to wait in line before being
       run on a window.setTimeout. */
   /** private */ currentWaitTime: 0,

   /** A flag that indicates that we should fire a history change event
       when we are ready, i.e. after we are initialized and
       we have a history change listener. This is needed due to
       an edge case in browsers other than Internet Explorer; if
       you leave a page entirely then return, we must fire this
       as a history change event. Unfortunately, we have lost
       all references to listeners from earlier, because JavaScript
       clears out. */
   /** private */ fireOnNewListener: null,

   /** A variable that indicates whether this is the first time
       this page has been loaded. If you go to a web page, leave
       it for another one, and then return, the page's onload
       listener fires again. We need a way to differentiate
       between the first page load and subsequent ones.
       This variable works hand in hand with the pageLoaded
       variable we store into historyStorage.*/
   /** private */ firstLoad: null,

   /** A variable to handle an important edge case in Internet
       Explorer. In IE, if a user manually types an address into
       their browser's location bar, we must intercept this by
       continiously checking the location bar with an timer
       interval. However, if we manually change the location
       bar ourselves programmatically, when using our hidden
       iframe, we need to ignore these changes. Unfortunately,
       these changes are not atomic, so we surround them with
       the variable 'ieAtomicLocationChange', that if true,
       means we are programmatically setting the location and
       should ignore this atomic chunked change. */
   /** private */ ieAtomicLocationChange: null,

   /** Creates the DHTML history infrastructure. */
   /** private */ create: function() {
      // get our initial location
      var initialHash = this.getCurrentLocation();

      // save this as our current location
      this.currentLocation = initialHash;

      // write out a hidden iframe for IE and
      // set the amount of time to wait between add() requests
      if (this.isInternetExplorer()) {
         document.write("<iframe style='border: 0px; width: 1px; "
                               + "height: 1px; position: absolute; bottom: 0px; "
                               + "right: 0px; visibility: visible;' "
                               + "name='DhtmlHistoryFrame' id='DhtmlHistoryFrame' "
                               + "src='/blank.html?" + initialHash + "'>"
                               + "</iframe>");
         // wait 400 milliseconds between history
         // updates on IE, versus 200 on Firefox
         this.WAIT_TIME = 400;
      }

      // add an unload listener for the page; this is
      // needed for Firefox 1.5+ because this browser caches all
      // dynamic updates to the page, which can break some of our
      // logic related to testing whether this is the first instance
      // a page has loaded or whether it is being pulled from the cache
      var self = this;
      window.onunload = function() {
         self.firstLoad = null;
      };

      // determine if this is our first page load;
      // for Internet Explorer, we do this in
      // this.iframeLoaded(), which is fired on
      // page load. We do it there because
      // we have no historyStorage at this point
      // in IE, which only exists after the page
      // is finished loading for that browser
      if (this.isInternetExplorer() == false) {
         if (historyStorage.hasKey("DhtmlHistory_pageLoaded") == false) {
            this.ignoreLocationChange = true;
            this.firstLoad = true;
            historyStorage.put("DhtmlHistory_pageLoaded", true);
         }
         else {
            // indicate that we want to pay attention
            // to this location change
            this.ignoreLocationChange = false;
            // For browser's other than IE, fire
            // a history change event; on IE,
            // the event will be thrown automatically
            // when it's hidden iframe reloads
            // on page load.
            // Unfortunately, we don't have any
            // listeners yet; indicate that we want
            // to fire an event when a listener
            // is added.
            this.fireOnNewListener = true;
         }
      }
      else { // Internet Explorer
         // the iframe will get loaded on page
         // load, and we want to ignore this fact
         this.ignoreLocationChange = true;
      }

      if (this.isInternetExplorer()) {
            this.iframe = $("DhtmlHistoryFrame");
      }

      // other browsers can use a location handler that checks
      // at regular intervals as their primary mechanism;
      // we use it for Internet Explorer as well to handle
      // an important edge case; see checkLocation() for
      // details
      var self = this;
      var locationHandler = function() {
         self.checkLocation();
      };
      setInterval(locationHandler, 100);
   },

   /** Notify the listener of new history changes. */
   /** private */ fireHistoryEvent: function(newHash) {
      // extract the value from our history storage for
      // this hash
      var historyData = historyStorage.get(newHash);

      // call our listener
      this.listener.call(null, newHash, historyData);
   },

   /** Sees if the browsers has changed location.  This is the primary history mechanism
       for Firefox. For Internet Explorer, we use this to handle an important edge case:
       if a user manually types in a new hash value into their Internet Explorer location
       bar and press enter, we want to intercept this and notify any history listener. */
   /** private */ checkLocation: function() {
      // ignore any location changes that we made ourselves
      // for browsers other than Internet Explorer
      if (this.isInternetExplorer() == false
         && this.ignoreLocationChange == true) {
         this.ignoreLocationChange = false;
         return;
      }

      // if we are dealing with Internet Explorer
      // and we are in the middle of making a location
      // change from an iframe, ignore it
      if (this.isInternetExplorer() == false
          && this.ieAtomicLocationChange == true) {
         return;
      }

      // get hash location
      var hash = this.getCurrentLocation();

      // see if there has been a change
      if (hash == this.currentLocation)
         return;

      // on Internet Explorer, we need to intercept users manually
      // entering locations into the browser; we do this by comparing
      // the browsers location against the iframes location; if they
      // differ, we are dealing with a manual event and need to
      // place it inside our history, otherwise we can return
      this.ieAtomicLocationChange = true;

      if (this.isInternetExplorer()
          && this.getIFrameHash() != hash) {
         this.iframe.src = "/blank.html?" + hash;
      }
      else if (this.isInternetExplorer()) {
         // the iframe is unchanged
         return;
      }

      // save this new location
      this.currentLocation = hash;

      this.ieAtomicLocationChange = false;

      // notify listeners of the change
      this.fireHistoryEvent(hash);
   },

   /** Gets the current location of the hidden IFrames
       that is stored as history. For Internet Explorer. */
   /** private */ getIFrameHash: function() {
      // get the new location
      var historyFrame = $("DhtmlHistoryFrame");
      var doc = historyFrame.contentWindow.document;
      var hash = new String(doc.location.search);

      if (hash.length == 1 && hash.charAt(0) == "?")
         hash = "";
      else if (hash.length >= 2 && hash.charAt(0) == "?")
         hash = hash.substring(1);


      return hash;
   },

   /** Removes any leading hash that might be on a location. */
   /** private */ removeHash: function(hashValue) {
      if (hashValue == null || hashValue == undefined)
         return null;
      else if (hashValue == "")
         return "";
      else if (hashValue.length == 1 && hashValue.charAt(0) == "#")
         return "";
      else if (hashValue.length > 1 && hashValue.charAt(0) == "#")
         return hashValue.substring(1);
      else
         return hashValue;
   },

   /** For IE, says when the hidden iframe has finished loading. */
   /** private */ iframeLoaded: function(newLocation) {
      // ignore any location changes that we made ourselves
      if (this.ignoreLocationChange == true) {
         this.ignoreLocationChange = false;
         return;
      }

      // get the new location
      var hash = new String(newLocation.search);
      if (hash.length == 1 && hash.charAt(0) == "?")
         hash = "";
      else if (hash.length >= 2 && hash.charAt(0) == "?")
         hash = hash.substring(1);

      // move to this location in the browser location bar
      // if we are not dealing with a page load event
      if (this.pageLoadEvent != true) {
         window.location.hash = hash;
      }

      // notify listeners of the change
      this.fireHistoryEvent(hash);
   },

   /** Determines if this is Internet Explorer. */
   /** private */ isInternetExplorer: function() {
      var userAgent = navigator.userAgent.toLowerCase();
      if (document.all && userAgent.indexOf('msie')!=-1) {
         return true;
      }
      else {
         return false;
      }
   }
};

/** An object that uses a hidden form to store history state
    across page loads. The chief mechanism for doing so is using
    the fact that browser's save the text in form data for the
    life of the browser and cache, which means the text is still
    there when the user navigates back to the page. See
    http://codinginparadise.org/weblog/2005/08/ajax-tutorial-saving-session-across.html
    for full details. */
window.historyStorage = {
   /** If true, we are debugging and show the storage textfield. */
   /** public */ debugging: false,

   /** Our hash of key name/values. */
   /** private */ storageHash: new Object(),

   /** If true, we have loaded our hash table out of the storage form. */
   /** private */ hashLoaded: false,

   /** public */ put: function(key, value) {
       this.assertValidKey(key);

       // if we already have a value for this,
       // remove the value before adding the
       // new one
       if (this.hasKey(key)) {
         this.remove(key);
       }

       // store this new key
       this.storageHash[key] = value;

       // save and serialize the hashtable into the form
       this.saveHashTable();
   },

   /** public */ get: function(key) {
      this.assertValidKey(key);

      // make sure the hash table has been loaded
      // from the form
      this.loadHashTable();

      var value = this.storageHash[key];

      if (value == undefined)
         return null;
      else
         return value;
   },

   /** public */ remove: function(key) {
      this.assertValidKey(key);

      // make sure the hash table has been loaded
      // from the form
      this.loadHashTable();

      // delete the value
      delete this.storageHash[key];

      // serialize and save the hash table into the
      // form
      this.saveHashTable();
   },

   /** Clears out all saved data. */
   /** public */ reset: function() {
      this.storageField.value = "";
      this.storageHash = new Object();
   },

   /** public */ hasKey: function(key) {
      this.assertValidKey(key);

      // make sure the hash table has been loaded
      // from the form
      this.loadHashTable();

      if (typeof this.storageHash[key] == "undefined")
         return false;
      else
         return true;
   },

   /** public */ isValidKey: function(key) {
      // allow all strings, since we don't use XML serialization
      // format anymore
      return (typeof key == "string");
   },

   /** A reference to our textarea field. */
   /** private */ storageField: null,

   /** private */ init: function() {
      /** simplified newContent from <div><form><input/></form></div> to fix an IE display glitch */
      var newContent = "<input type='text' id='historyStorageField' name='historyStorageField' style='display: none;'/>";
      document.write(newContent);

      this.storageField = $("historyStorageField");
   },

   /** Asserts that a key is valid, throwing
       an exception if it is not. */
   /** private */ assertValidKey: function(key) {
      if (this.isValidKey(key) == false) {
         throw "Please provide a valid key for "
               + "window.historyStorage, key= "
               + key;
       }
   },

   /** Loads the hash table up from the form. */
   /** private */ loadHashTable: function() {
      if (this.hashLoaded == false) {
         // get the hash table as a serialized
         // string
         var serializedHashTable = this.storageField.value;

         if (serializedHashTable != "" &&
             serializedHashTable != null) {
            // destringify the content back into a
            // real JavaScript object
            this.storageHash = eval('(' + serializedHashTable + ')');
         }

         this.hashLoaded = true;
      }
   },

   /** Saves the hash table into the form. */
   /** private */ saveHashTable: function() {
      this.loadHashTable();

      // serialized the hash table
      var serializedHashTable = JSON.stringify(this.storageHash);

      // save this value
      this.storageField.value = serializedHashTable;
   }
};

/** The JSON class is copyright 2005 JSON.org. */
Array.prototype.______array = '______array';

var JSON = {
    org: 'http://www.JSON.org',
    copyright: '(c)2005 JSON.org',
    license: 'http://www.crockford.com/JSON/license.html',

    stringify: function (arg) {
        var c, i, l, s = '', v;

        switch (typeof arg) {
        case 'object':
            if (arg) {
                if (arg.______array == '______array') {
                    for (i = 0; i < arg.length; ++i) {
                        v = this.stringify(arg[i]);
                        if (s) {
                            s += ',';
                        }
                        s += v;
                    }
                    return '[' + s + ']';
                } else if (typeof arg.toString != 'undefined') {
                    for (i in arg) {
                        v = arg[i];
                        if (typeof v != 'undefined' && typeof v != 'function') {
                            v = this.stringify(v);
                            if (s) {
                                s += ',';
                            }
                            s += this.stringify(i) + ':' + v;
                        }
                    }
                    return '{' + s + '}';
                }
            }
            return 'null';
        case 'number':
            return isFinite(arg) ? String(arg) : 'null';
        case 'string':
            l = arg.length;
            s = '"';
            for (i = 0; i < l; i += 1) {
                c = arg.charAt(i);
                if (c >= ' ') {
                    if (c == '\\' || c == '"') {
                        s += '\\';
                    }
                    s += c;
                } else {
                    switch (c) {
                        case '\b':
                            s += '\\b';
                            break;
                        case '\f':
                            s += '\\f';
                            break;
                        case '\n':
                            s += '\\n';
                            break;
                        case '\r':
                            s += '\\r';
                            break;
                        case '\t':
                            s += '\\t';
                            break;
                        default:
                            c = c.charCodeAt();
                            s += '\\u00' + Math.floor(c / 16).toString(16) +
                                (c % 16).toString(16);
                    }
                }
            }
            return s + '"';
        case 'boolean':
            return String(arg);
        default:
            return 'null';
        }
    },
    parse: function (text) {
        var at = 0;
        var ch = ' ';

        function error(m) {
            throw {
                name: 'JSONError',
                message: m,
                at: at - 1,
                text: text
            };
        }

        function next() {
            ch = text.charAt(at);
            at += 1;
            return ch;
        }

        function white() {
            while (ch != '' && ch <= ' ') {
                next();
            }
        }

        function str() {
            var i, s = '', t, u;

            if (ch == '"') {
outer:          while (next()) {
                    if (ch == '"') {
                        next();
                        return s;
                    } else if (ch == '\\') {
                        switch (next()) {
                        case 'b':
                            s += '\b';
                            break;
                        case 'f':
                            s += '\f';
                            break;
                        case 'n':
                            s += '\n';
                            break;
                        case 'r':
                            s += '\r';
                            break;
                        case 't':
                            s += '\t';
                            break;
                        case 'u':
                            u = 0;
                            for (i = 0; i < 4; i += 1) {
                                t = parseInt(next(), 16);
                                if (!isFinite(t)) {
                                    break outer;
                                }
                                u = u * 16 + t;
                            }
                            s += String.fromCharCode(u);
                            break;
                        default:
                            s += ch;
                        }
                    } else {
                        s += ch;
                    }
                }
            }
            error("Bad string");
        }

        function arr() {
            var a = [];

            if (ch == '[') {
                next();
                white();
                if (ch == ']') {
                    next();
                    return a;
                }
                while (ch) {
                    a.push(val());
                    white();
                    if (ch == ']') {
                        next();
                        return a;
                    } else if (ch != ',') {
                        break;
                    }
                    next();
                    white();
                }
            }
            error("Bad array");
        }

        function obj() {
            var k, o = {};

            if (ch == '{') {
                next();
                white();
                if (ch == '}') {
                    next();
                    return o;
                }
                while (ch) {
                    k = str();
                    white();
                    if (ch != ':') {
                        break;
                    }
                    next();
                    o[k] = val();
                    white();
                    if (ch == '}') {
                        next();
                        return o;
                    } else if (ch != ',') {
                        break;
                    }
                    next();
                    white();
                }
            }
            error("Bad object");
        }

        function num() {
            var n = '', v;
            if (ch == '-') {
                n = '-';
                next();
            }
            while (ch >= '0' && ch <= '9') {
                n += ch;
                next();
            }
            if (ch == '.') {
                n += '.';
                while (next() && ch >= '0' && ch <= '9') {
                    n += ch;
                }
            }
            if (ch == 'e' || ch == 'E') {
                n += 'e';
                next();
                if (ch == '-' || ch == '+') {
                    n += ch;
                    next();
                }
                while (ch >= '0' && ch <= '9') {
                    n += ch;
                    next();
                }
            }
            v = +n;
            if (!isFinite(v)) {
                error("Bad number");
            } else {
                return v;
            }
        }

        function word() {
            switch (ch) {
                case 't':
                    if (next() == 'r' && next() == 'u' && next() == 'e') {
                        next();
                        return true;
                    }
                    break;
                case 'f':
                    if (next() == 'a' && next() == 'l' && next() == 's' &&
                            next() == 'e') {
                        next();
                        return false;
                    }
                    break;
                case 'n':
                    if (next() == 'u' && next() == 'l' && next() == 'l') {
                        next();
                        return null;
                    }
                    break;
            }
            error("Syntax error");
        }

        function val() {
            white();
            switch (ch) {
                case '{':
                    return obj();
                case '[':
                    return arr();
                case '"':
                    return str();
                case '-':
                    return num();
                default:
                    return ch >= '0' && ch <= '9' ? num() : word();
            }
        }

        return val();
    }
};

/** QueryString Object from http://adamv.com/dev/javascript/querystring */
/* Client-side access to querystring name=value pairs
	Version 1.2.3
	22 Jun 2005
	Adam Vandenberg
*/
function Querystring(qs) { // optionally pass a querystring to parse
	this.params = new Object()
	this.get=Querystring_get

	if (qs == null)
		qs=location.search.substring(1,location.search.length)

	if (qs.length == 0) return

// Turn <plus> back to <space>
// See: http://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4.1
	qs = qs.replace(/\+/g, ' ')
	// added by Scott Rutherford, change all &amp; to &
	qs = qs.replace(/&amp;/g, '&')
	var args = qs.split('&') // parse out name/value pairs separated via &

// split out each name=value pair
	for (var i=0;i<args.length;i++) {
		var value;
		var pair = args[i].split('=')
		var name = unescape(pair[0])

		if (pair.length == 2)
			value = unescape(pair[1])
		else
			value = name

		this.params[name] = value
	}
}

function Querystring_get(key, default_) {
	// This silly looking line changes UNDEFINED to NULL
	if (default_ == null) default_ = null;

	var value=this.params[key]
	if (value==null) value=default_;

	return value
}

/** ADDED BY SCOTT RUTHERFORD, COMINDED July 2006 scott@cominded */
/** Initialize all of our objects now. */
window.historyStorage.init();
window.dhtmlHistory.create();

/** Create init methods for ActiveScaffold */
function initialize() {
  // initialize our DHTML history
  dhtmlHistory.initialize();
  // subscribe to DHTML history change
  // events
  dhtmlHistory.addListener(handleHistoryChange);
}

/** Our callback to receive history
    change events. */
function handleHistoryChange(pageId, pageData) {
  if (!pageData) return;
  var info = pageId.split(':');
  var id = info[0];
  pageData += '&_method=get';
  new Ajax.Updater(id+'-content', pageData, {asynchronous:true, evalScripts:true, onLoading:function(request){Element.show(id+'-pagination-loading-indicator');}});
}

/** set onload handler */
Event.observe(window, 'load', initialize, false);
