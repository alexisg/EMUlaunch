/*
Tweening prototypes for AS 1.0
version 1.1.7
Ladislav Zigo,lacoz@web.de
*/
#include "easing_equations.as"
//
var Mp = MovieClip.prototype;
//
AsBroadcaster.initialize(Mp);
Mp.$addListener = Mp.addListener;
ASSetPropFlags(Mp, "$addListener", 1, 0);
Mp.addListener = function(){
	AsBroadcaster.initialize(this);
	this.$addListener.apply(this,arguments);
}
//
function tweenManager() {
 this.playing = false
 this.autoStop = false;
 this.broadcastEvents = false; 
 this.autoOverwrite = true; 
 this.tweenList = new Array()
 this.ints = new Array();
 this.lockedTweens = new Object();
 this.now = 0;
 this.isPaused = false;
 this.pausedTime = 0;
}
var tp = tweenManager.prototype;
tp.setupdateInterval = function(time){
	if (this.playing){
		this.deinit()
		this.updateTime = time
		this.init()
	}else{
		this.updateTime = time
	}

}
tp.getupdateInterval = function(){
	return this.updateTime;
}
tp.addProperty("updateInterval",tp.getupdateInterval, tp.setupdateInterval);
//
tp.init = function(){
	var tm = this;	
	if(tm.updateTime > 0){
		tm.updateIntId = setInterval(tm,"update",tm.updateTime);
	}else{
		if(tm.tweenHolder._name == undefined){
			tm.tweenHolder = _root.createEmptyMovieClip("_th_",6789); 
		}
		//tweenHolder.onEnterFrame = update
	
		tm.tweenHolder.onEnterFrame = function(){				
			tm.update.call(tm);
		}
	}
	tm.playing = true;
	tm.now = getTimer();
}
//
tp.deinit = function(){
	this.playing = false;
	clearInterval(this.updateIntId);
	delete this.tweenHolder.onEnterFrame;
}
//-------------------------- private  methods
tp.update = function() {
	var i, t, j;
	i = this.tweenList.length;
	if(this.broadcastEvents){
		// list of updated mcs
		var ut = {};
		// list of ending mcs
		var et = {};
	}
	while (i--) {
		t = this.tweenList[i];
		if (t.ts+t.d>this.now) {
			// compute value using equation function
			if (t.ctm == undefined) {
				// compute primitive value
				t.mc[t.pp] = t.ef(this.now-t.ts, t.ps, t.ch, t.d, t.e1, t.e2);
			} else {
				// compute color transform matrix 
				// stm is starting transform matrix, 
				// ctm is change in start & destination matrix 
				// ttm is computed (temporary) transform matrix
				// c is color object
				var ttm = {};
				for (j in t.ctm) {
					ttm[j] = t.ef(this.now-t.ts, t.stm[j], t.ctm[j], t.d, t.e1, t.e2);
				}
				t.c.setTransform(ttm);
			}
			if(this.broadcastEvents && ut[targetpath(t.mc)] == undefined){
				ut[targetpath(t.mc)] = t.mc;
			}
			if(t.cb.updfunc != undefined){
				t.cb.updfunc.apply(t.cb.updscope,t.cb.updargs);
			}
		} else {
			// end , set up the property to end value;
			if (t.ctm == undefined) {
				t.mc[t.pp] = t.ps+t.ch;
			} else {
				var ttm = {};
				for (j in t.ctm) {
					ttm[j] = t.stm[j]+t.ctm[j];
				}
				t.c.setTransform(ttm);
			}
			if(this.broadcastEvents){
				if(ut[targetpath(t.mc)] == undefined){
					ut[targetpath(t.mc)] = t.mc;
				}
				
				if(et[targetpath(t.mc)] == undefined){
					et[targetpath(t.mc)] = t.mc;
				}
			}
			if(t.cb.updfunc != undefined){
				t.cb.updfunc.apply(t.cb.updscope,t.cb.updargs);
			}
			if (endt == undefined){
				var endt = new Array();
			}
			endt.push(i);
		}
	}
	for (j in ut){
		ut[j].broadcastMessage('onTweenUpdate');
	}
	if(endt != undefined){
		this.endTweens(endt);
	}
	for (j in et){
		et[j].broadcastMessage('onTweenEnd');
	}
	this.now = getTimer();
	// update timer 
	if (this.updateTime > 0){
		updateAfterEvent();
	}

};
tp.endTweens = function(tid_arr){
var cb_arr, tl, i, cb, j
cb_arr = []
// splice tweens from tweenlist 
tl = tid_arr.length
with(this){
	for (i = 0; i<tl; i++){
		cb = tweenList[tid_arr[i]].cb
		if(cb != undefined){
			var exec = true;
			//do not add callbacks that are in cb_arr
			for(j in cb_arr){
				if (cb_arr[j] ==  cb){
					exec = false;
					break;
				}
			}
			//
			if(exec){
				cb_arr.push(cb)
			}
		}
		tweenList.splice(tid_arr[i],1);
	}
	// execute callbacks
	for (i = 0; i<cb_arr.length;i++){
		cb_arr[i].func.apply(cb_arr[i].scope,cb_arr[i].args)
	}
	//
	// /*1.1.6*/
	if(tweenList.length==0){
	// last tween removed, erase onenterframe function
		deinit();
	}
}
}
// ------------- public methods
tp.addTween = function(mc,props,pEnd,sec,eqFunc,callback,extra1,extra2){
	var i, pp, addnew, j, t;
	with(this){
		//
		if(!playing){
			init();
		}
		for(i in props){
			pp = props[i];
			addnew = true;
			//
			if(pp.substr(0,4)!="_ct_"){
				// there is no color transform prefix, use primitive value tween
				//
				if(autoOverwrite){
					// find coliding tween and overwrite it 
					for (j in tweenList){
						t = tweenList[j];
						if(t.mc == mc && t.pp == pp){
							//
							t.ps = mc[pp];
							t.ch = pEnd[i] - mc[pp];
							t.ts = now;
							t.d = sec*1000;
							t.ef = eqFunc;
							t.cb = callback;
							t.e1 = extra1;
							t.e2 = extra2;
							addnew = false;												
							break;
						}
					}
				}
				if(addnew){	
				// not found add new
				tweenList.unshift({							
						  mc: mc,				
						  pp: pp, 				
						  ps: mc[pp],			
						  ch: pEnd[i] - mc[pp], 
						  ts: now, 				
						  d:  sec * 1000, 		
						  ef: eqFunc, 			
						  cb: callback,			
						  e1: extra1,			
						  e2: extra2});			
				}
			}else{
				// color trasform prefix found	
				// compute change matrix
				var c = new Color(mc);
				var stm = c.getTransform();
				// compute difference between starting and desionation matrix
				var ctm = {}
				for(j in pEnd[i]){
					// if is in destination matrix 
					if(pEnd[i][j] != stm[j] && pEnd[i][j] != undefined ){
						ctm[j] = pEnd[i][j] - stm[j];
					}
				}
				if(autoOverwrite){
				// find coliding tween and overwrite it 
				for (j in tweenList){
					t = tweenList[j];
					if(t.mc == mc && t.ctm != undefined){
							//
							t.c = c
							t.stm = stm	
							t.ctm =  ctm,
							t.ts = now;
							t.d = sec*1000;
							t.ef = eqFunc;
							t.cb = callback;
							t.e1 = extra1;
							t.e2 = extra2;
							addnew = false;												break;
						}
					}
				}
				if(addnew){	
				tweenList.unshift({
						mc:  mc,			//reference to movieclip
						c:   c,				//reference to movieclip color
						stm: stm,			//starting transform matrix
						ctm: ctm,			
						ts:  now,
						d:   sec * 1000,
						ef:  eqFunc,
						cb:  callback,
						e1:  extra1,
						e2:  extra2
					})
				}			
				
			}
		} // end for
	if(broadcastEvents){
		mc.broadcastMessage('onTweenStart'); 				
	}
	if(callback.startfunc != undefined){
		callback.startfunc.apply(callback.startscope,callback.startargs)
	}
	}// end with
}
tp.addTweenWithDelay = function(delay,mc,props,pEnd,sec,eqFunc,callback,extra1,extra2){
with(this){
	var il = ints.length;
	var intid = setInterval(function(obj){
		obj.addTween(mc, props, pEnd, sec, eqFunc, callback, extra1, extra2);
		clearInterval(obj.ints[il].intid);
		obj.ints[il] = undefined;
	},delay*1000,this);
	//
	ints[il] = {mc: mc, props: props, pend:pEnd, intid:intid, st: this.now, delay:delay*1000, args: arguments.slice(1)}
}
}
//
tp.removeTween = function(mc,props){
with (this){
	var all, i, j
	all = false;
	if(props == undefined){
		// props are undefined, remove all tweens
		all = true;
	}
	i = tweenList.length; 
	while (i--){
		if(tweenList[i].mc == mc){
			if(all){
				tweenList.splice(i,1);
			}else{
				for(j in props){
					if(tweenList[i].pp == props[j] && tweenList[i].mc == mc){
						tweenList.splice(i,1);
						// (because allows add same properties for same mc,
						// all tweens must be checked) 
					} else if (props[j] == "_ct_" && tweenList[i].ctm != undefined && tweenList[i].mc == mc){
						// removing of colorTransform tweens
						tweenList.splice(i,1);
					}
				}
			}
		}
	}
	i = ints.length;
	while(i-- && ints[i].mc == mc){
		if(all){
			// REMOVE ALL
			clearInterval(ints[i].intid)
			ints[i] = undefined
		} else {
			// REMOVE PROPERTIES
			for(j in props){
				for(var k in ints[i].props){
					if(ints[i].props[k] == props[j] && tweenList[i].mc == mc){
						// remove tween properties + property end values
						ints[i].props.splice(k,1);
						ints[i].pend.splice(k,1);
					} 
				}
				if(ints[i].props.length == 0){
					clearInterval(ints[i].intid)
					// no properties to tween
				}
			}
		}
	}
	// /*1.1.6*/
	if(tweenList.length==0){
	// last tween removed, erase onenterframe function
		deinit();
	}
}// end with	
}
tp.isTweening = function(mc){
	with(this){
		
		for (var i in tweenList){
			if(tweenList[i].mc == mc){
				// mc found, so break loop
				return true;
				break;
			}
		}
		return false;
	}
}
tp.getTweens = function(mc){
	with(this){
		var count = 0;
		for (var i in tweenList){
			if(tweenList[i].mc == mc){
				// found, increase count
				count++;
			}
		}
		return count;
	}
}
tp.lockTween = function(mc,bool){
	this.lockedTweens[targetpath(mc)] = bool;			
}
tp.isTweenLocked = function(mc){
	if(this.lockedTweens[targetpath(mc)] == undefined){
		return false;
	}else{
		return this.lockedTweens[targetpath(mc)];
	}			
}
tp.pauseAll = function(){
	if (this.isPaused){
		return
	}
	this.isPaused = true;
	this.pausedTime = this.now;
	// pause too delayed
	for (var i in this.ints){
		clearInterval(this.ints[i].intid)
	}
	//
	this.deinit();
}
tp.unpauseAll = function(){
	if (!this.isPaused){
		return;
	}
	var i, t;
	this.isPaused = false;
	this.init();
	for (i in this.tweenList) {
		t = this.tweenList[i];
		// update start times 
		t.ts = this.now-(this.pausedTime-t.ts);
	}
	//
	
	//
	for (i in this.ints){
		if (this.ints[i] == undefined){
			continue
		}
		//
		var delay = this.ints[i].delay - (this.pausedTime - this.ints[i].st);
		
		var intid = setInterval(function(obj,id){
			
			obj.addTween.apply(obj, obj.ints[id].args);
			clearInterval(obj.ints[id].intid);
			obj.ints[id] = undefined;
		},delay,this,i);
		//
		this.ints[i].intid = intid;
		this.ints[i].st = this.now;
		this.ints[i].delay = delay;
		//
	}
	
}
tp.stopAll = function(){
	for (var i in this.ints){
		clearInterval(this.ints[i].intid)
	}
	// stop all running tweens
	this.tweenList = new Array();	
	this.deinit();
}
tp.toString = function(){
	return "[AS1 tweenManager 1.1.7]";
}
delete tp;
//----------------------------- end of tweenManager

if($tweenManager == undefined){
_global.$tweenManager = new tweenManager();
}
// prototypes
Mp.tween = function(props, pEnd, seconds, animType,
				delay, callback, extra1, extra2) {
	if ($tweenManager.isTweenLocked(this)){
		//trace("error: this movieclip is locked");
		return;
	}	
	if (arguments.length<2) {
		//trace("error: props & pEnd must be defined");
		return;
	}
	// parse arguments to valid type:
	// parse properties
	if (typeof (props) == "string") {
		props = [props];
	}
	// parse end values
	// if pEnd is not array 
	if (pEnd.length == undefined ) {
		pEnd = [pEnd];
	} 
	// parse time properties
	if(seconds == undefined) {
		seconds = 2;
	}else if (seconds<0.01){
		seconds = 0;
	}
	//
	if (delay<0.01 || delay == undefined) {
		delay = 0;
	}
	// parse animtype to reference to equation function 
	switch(typeof(animType)){
	case "string":
	animType = animType.toLowerCase();
	if (animType == "linear") {
		var eqf = Math.linearTween
	} else {
		var eqf = Math[animType]
	}
	break;
	case "function":
		var eqf = animType;
	break;
	case "object":
		if(animType.pts != undefined && animType.ease != undefined){
		var eqf = animType.ease;
		var extra1 = animType.pts; 
		}
	}
	if (eqf == undefined) {
		// set default tweening equation
		var eqf = Math.easeOutExpo;
	}
	// parse callback function
	switch(typeof (callback)) {
	case "function":
		callback = {func:callback, scope:this._parent};
		break;
	case "string":
		var ilp = callback.indexOf("(");
		var funcp = callback.slice(0, ilp);
		//
		var scope = eval(funcp.slice(0, funcp.lastIndexOf(".")));
		var func = eval(funcp);
		var args = callback.slice(ilp+1, callback.lastIndexOf(")")).split(",");
		for (var i = 0; i<args.length; i++) {
			var a = eval(args[i]);
			if (a != undefined) {
				args[i] = a;
			}
		}
		callback = {func:func, scope:scope, args:args };
		break;
	}
        if($tweenManager.autoStop){
		// automatic removing tweens as in Zeh proto
		$tweenManager.removeTween(this,props)		
	}
	// pass parameters to tweenManager  method 
	if(delay > 0){
		$tweenManager.addTweenWithDelay(delay,this, props, pEnd, seconds, eqf, callback, extra1, extra2);
	}else{
		$tweenManager.addTween(this, props, pEnd, seconds, eqf, callback, extra1, extra2);
	}	
};
ASSetPropFlags(Mp, "tween", 1, 0);
Mp.stopTween = function(props) {
	if (typeof (props) == "string") {
		props = [props];
	}
	$tweenManager.removeTween(this, props);
};
ASSetPropFlags(Mp, "stopTween", 1, 0);
Mp.isTweening = function() {
	//returns boolean
	return $tweenManager.isTweening(this);
};
ASSetPropFlags(Mp, "isTweening", 1, 0);
Mp.getTweens = function() {
	// returns count of running tweens
	return $tweenManager.getTweens(this);
};
ASSetPropFlags(Mp, "getTweens", 1, 0);
Mp.lockTween = function() {
	$tweenManager.lockTween(this,true);
};
ASSetPropFlags(Mp, "lockTween", 1, 0);
Mp.unlockTween = function() {
	$tweenManager.lockTween(this,false);
};
ASSetPropFlags(Mp, "unlockTween", 1, 0);
Mp.isTweenLocked = function() {
	return $tweenManager.isTweenLocked(this);
};
ASSetPropFlags(Mp, "isTweenLocked", 1, 0);
// == shortcut methods == 
// these methods only passes parameters to tween method
Mp.alphaTo = function (destAlpha, seconds, animType, delay, callback, extra1, extra2) {
	this.tween(["_alpha"],[destAlpha],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "alphaTo", 1, 0);
Mp.brightnessTo = function (bright, seconds, animType, delay, callback, extra1, extra2) {
	// destionation color transform matrix
	var percent = 100 - Math.abs(bright);
  	var offset = 0;
  	if (bright > 0) offset = 256 * (bright / 100);
 	var destCt = {ra: percent, rb:offset,
			ga: percent, gb:offset,
			ba: percent,bb:offset}
	//
	this.tween(["_ct_"],[destCt],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "brightnessTo", 1, 0);
Mp.colorTo = function (destColor, seconds, animType, delay, callback, extra1, extra2) {
	// destionation color transform matrix
	var destCt = {rb: destColor >> 16, ra:0,
				  gb: (destColor & 0x00FF00) >> 8, ga:0,
				  bb: destColor & 0x0000FF,ba:0}
	//
	this.tween(["_ct_"],[destCt],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "colorTo", 1, 0);
Mp.colorTransformTo = function (ra, rb, ga, gb, ba, bb, aa, ab, seconds, animType, delay, callback, extra1, extra2) {
	// destionation color transform matrix
	var destCt = {ra: ra ,rb: rb , ga: ga, gb: gb, ba: ba, bb: bb, aa: aa, ab: ab}
	//
	this.tween(["_ct_"],[destCt],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "colorTransformTo", 1, 0);
Mp.scaleTo = function (destScale, seconds, animType, delay, callback, extra1, extra2) {
	this.tween(["_xscale", "_yscale"],[destScale, destScale],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "scaleTo", 1, 0);
Mp.slideTo = function (destX, destY, seconds, animType, delay, callback, extra1, extra2) {
	this.tween(["_x", "_y"],[destX, destY],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "slideTo", 1, 0);
Mp.rotateTo = function (destRotation, seconds, animType, delay, callback, extra1, extra2) {
	this.tween(["_rotation"],[destRotation],seconds,animType,delay,callback,extra1,extra2)
}
ASSetPropFlags(Mp, "rotateTo", 1, 0);
//
Mp.getFrame = function() {
	return this._currentframe;
};
ASSetPropFlags(Mp, "getFrame", 1, 0);
Mp.setFrame = function(fr) {
	this.gotoAndStop(Math.round(fr));
};
ASSetPropFlags(Mp, "setFrame", 1, 0);
Mp.addProperty("_frame", Mp.getFrame, Mp.setFrame);
ASSetPropFlags(Mp, "_frame", 1, 0);
//
Mp.frameTo = function(endframe, duration, animType, delay, callback, extra1, extra2) {
	if (endframe == undefined) {
		endframe = this._totalframes;
	}
	this.tween("_frame", endframe, duration, animType, delay, callback, extra1, extra2);
};
ASSetPropFlags(Mp, "frameTo", 1, 0);
Mp.brightOffsetTo = function(percent, seconds, animType, delay, callback, extra1, extra2) {
	var offset = 256*(percent/100);
	var destCt = {ra:100, rb:offset, ga:100, gb:offset, ba:100, bb:offset};
	this.tween(["_ct_"], [destCt], seconds, animType, delay, callback, extra1, extra2);
};
ASSetPropFlags(Mp, "brightOffsetTo", 1, 0);
Mp.contrastTo = function(percent, seconds, animType, delay, callback, extra1, extra2) {
	// from Robert Penner color toolkit
	var t = {};
	t.ra = t.ga=t.ba=percent;
	t.rb = t.gb=t.bb=128-(128/100*percent);
	this.tween(["_ct_"], [t], seconds, animType, delay, callback, extra1, extra2);
};
ASSetPropFlags(Mp, "contrastTo", 1, 0);
//
delete Mp;
