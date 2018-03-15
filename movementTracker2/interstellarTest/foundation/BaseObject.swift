//
//  baseClass.swift
//  interStellarTest
//
//  Created by sami on 2017/07/03.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar




//-> boResult<NSDictionary>

//put a lot of stuff in houskeep_extend. low disk alert : im I writing to local db, should I drop? does the db adaptor cache
//creating a picture taking wiev when no mem / diskspace available, results in DROP
//when getting a drop, UI notifies user

typealias PetDictionary = [ String : String]  //oID,name

enum hibernationStrategy: String {
    
    case teardown = "teardown" //gtfo dodge
    case finalize = "finalize" //finalize, disk operations
    case hibernate = "hibernate"
    case persist = "persist"
    //dont do anything memory related here
    
}

enum memoryPressureStrategy: String {
    
    case teardown = "teardown" //gtfo dodge
    case finalize = "finalize" //finalize, disk operations
    case purgeCaches = "purgeCaches"
    case persist = "persist"
    //dont do anything memory related here
    
}




class BufferConsumer {
    
    //anything that receives buffers guards for memory overload
    var processing = false;
    var terminated = false;
    var lastProcessedBuffer = 0;
    var totalPassedBuffers = 0;
    var totalSuccessfullBuffers = 0;
    var totalParsedObjects = 0 ;
    var maxBuffers = 10;
    
}

class BaseObject: NSObject {
    
    weak var scheduler: Scheduler?  //BaseObjects way to talk to scheduler
    weak var messageQueue : MessageQueue?   //link to messageQueue
    
    var myObjects = [objectCategoryTypes : PetDictionary ]();	//links with categories, my observables. I can get messages from these
    
    //let scheduler observe object memory consumption and take action
    //if something is out of controol
    
    
    //var myDataArray =
    
    var myCategory = objectCategoryTypes.generic
    var myID = String(Date().timeIntervalSince1970)
    var name = "defaultName"
    var created = Date().timeIntervalSince1970
    var muted = false;
    var EXITWhenEmpty = true;   //when losing last subObject link, EXIT
    var TTL = Date().timeIntervalSince1970 ; //10000;    //in milliseconds //time to die, increase when there is an interaction
    var PULSEextendBySecondsDefault : Double = 5 //every time _pulsed, extend by this if not specified othewise
    var maxCategoryObjects = 2 //how many obs per cat, limits users in groups etc
                                //exceeding this limit causes DROP and _purge handler, somebody has to retry
    var schedulerAgentType : schedulerAgents?;
    
    var houseKeepingInterval = 1000;	//once  this is decided by scheduler
    var isHibernating = false
    var isInitialized = false   //calling initialize will turn this on
    var isPrimed = false;   //if the agent needs some data, this will set when we have it
    
    var myHibernationStrategy = hibernationStrategy.teardown    //teardown as default
    
    var isReleasingMemoryPressure = false;
    var myMemoryPressureStrategy = memoryPressureStrategy.teardown
    
    var houseKeepingRole = houseKeepingRoles.slave;	//default  even masters get housekeeped by scheduler
                                                    //should schduler ignore slaves? how to know if the master has died?
                                                    //master should force its slaves to die when it EXITs?
    
        //me.dieWhenEmpty = false;	//group dies when it has no objects
								//check this when done housekeeping
								//maybe let the actor specify this
                                //not having any listeners is not a problem. the object is going to TTL out
                                //if nobody asks it to do anything
    
    //var listeningToMe = [String]();		//pass catID myID to array
    //if listeners goes down to 0, _finalize
    //nobody cares about what we do, bugger off
    
    var listeners = [String]();
    var maxListeners = 20
    
    var filterMessagesByMyID = false;	//on user, group, force filter
    var propagateTheseListenersToMyChildren = [String]();
        //unused defaultlistners
    var defaultListeners = [String]();	//push any def listeners here. usually the parent that created this
        //me.beingSpokenTo = false; //or speaker id. paranoid
    
    var isPurging = false;	//or a timestamp. if psychokilling too long, TIMEOUT
        //anything set to purge will die 
    
    
    var purgeRequestCount = 0   //if this grows too high, there is a system panic
    var purgeRequestEXITtreshold = 10   //system panic level exceeded, just drop everything and EXIT
            //shitloads of EXIT messages incoming. should we just set to terminated and return a nil?
            //maybe keep passing EXIT messages to help bookkeeping and dont worry about message pressure
                                    
    var terminated = false;	//EXIT set this true
    var isFinalizing = false;   //when finalizer is called, ignore anything from outside
    
    //computation latency
    var latency = 0.0;
    var maxLatency = 0.0
    
    let maxLatencyWarningGap = 205.648778915405273  //if things take too long, warm , kill
    let maxLatencyKillGap = 44423.648778915405273
    
    var isProcessing = false;
    var processingStartUnixTimestamp = Date().timeIntervalSince1970
    var user : Any? = nil;
    var agentIcon : String?;
    
    //var user = Player(playerID: <#String#>) ; //if the function depends on player info, use setPlayer for this. mapcombiner, runrecorder, data analysis
    
    //}	//end baseobject
    init( messageQueue : MessageQueue? ) {
        super.init()
        //
        objectCategoryTypes.allValues().forEach {
            myObjects[$0] = PetDictionary()
        }
        
        //give a bit of lifetime to this guy
        self.TTL = self.TTL + self.PULSEextendBySecondsDefault;
        self.messageQueue = messageQueue    //share message queue object for this guy too
        //print("BaseObject: initializing new me \(self.name))")
    }
    
    func setUser ( user: Player) {
        
        //if we have a user property, set it
        if self.user == nil { return }
        self.user = user;
        
    }
    
    func getUser () -> Player? {
        
        if self.user == nil { return nil }
        return self.user as! Player
        
    }
    
func propagateListenersToChild (cOBJ : [String] ) -> Bool {
    
    //this should happen with a message. looks at my children
    
    
    /*if (this.propagateTheseListenersToMyChildren.length) {
    var t=0;
    var added = false;
    while(a=this.propagateTheseListenersToMyChildren[t]){
    if (Obase[a]!==undefined){
				//Obase[a].addListener(cOBJ.myCategory,cOBJ.myID,cOBJ);
				cOBJ.addListener(Obase[a].myCategory,Obase[a].myID,Obase[a]);
				//illegal
				cOBJ.PING("");	//this should happen at housekeep
				added=true;
    }
    t++;
    }
    
    if (added) {
    //say hello to listeners
    //LISTEN should catch this
    
    }
    
    } */
        return false;
    }	//end of propagateListenersToChild
    
    func initDefaultListeners () -> Bool {
    
    /*if (this.propagateTheseListenersToMyChildren.length) {
     
     while(a=this.defaultListeners.shift()){
     if (Obase[a]!==undefined){
     Obase[a].addListener(this.myCategory,this.myID,this);
     }
     }
     
     }*/
    
        
    //usually talk back to parent
        if (self.defaultListeners.count == 0) { return false ;}
        for a in self.defaultListeners {
            
            //Obase[a].addListener(this.myCategory,this.myID,this);
        }
        
        return true;
        
        
    } //propagateListenersToChild
    
    func setDefaultListeners (cOBJ : [String] ) -> Bool {
    //array ob myIDs that point to Obase entry
    //usually talk back to parent
        
        for a in cOBJ {
            
            //Obase[a].addListener(this.myCategory,this.myID,this);
            self.defaultListeners.append(a)
        }
        
        return true;
        
    }   //setDefaultListeners
    
    func addObject (oCAT : objectCategoryTypes, oID : String , name : String ) -> DROPcategoryTypes? {
        
        let c = self.myObjects[oCAT]?.count;
        if (c! > self.maxCategoryObjects ) {
            return DROPcategoryTypes.maxCategoryObjectsExceeded
        }
        
        self.myObjects[oCAT]?[oID]=name;
        
        //adding live objects to this object causes problems of overseeing, stuff get out of schedulers reach. 
        //if we need to add objects, request from scheduler with a closure?  
        
        
        return nil
    }
    
    //check if we have too much aready
    //if (Obase[oID]!==undefined) {
    //dont allow re add the same objo
    //	return null;	//we are in already, win
    //}
    
    
    //eventually pass only listeners say,listen SAY LISTEN
    //SAY LISTEN is for process control like crashes
    //say listen is for soft message passing from child to parent
    
    //o.categoryID = oCat;
    
    
    func getObject (oCAT : objectCategoryTypes , oID : String ) -> Any? {
    
        if let gg = self.myObjects[oCAT] {
            if gg[oID] != nil {
                return oID; //return a signal to the objo?
            }
            return nil; //not found
        }
        
    return nil;
    
    
    /*var me=this;
    if (me.myObjects[oCAT]===undefined) { return false; }
    if (me.myObjects[oCAT][oID]===undefined) { return false; }
    if (Obase[oID]===undefined) {
    //deleted from obase, delete our link
    delete(me.myObjects[oCAT][oID]);
    return false;
    }
    return Obase[oID];
    }*/
    
    }   //end getObject
    
    
    func getGroupObject (oID : String ) -> Any? {
        
        return self.getObject(oCAT: objectCategoryTypes.group, oID: oID)
        
    }
    
    func getUserObject (oID : String ) -> Any? {
        
        return self.getObject(oCAT: objectCategoryTypes.user, oID: oID)
        
    }
    
    
    func findObjectByName (name : String ,oCAT : objectCategoryTypes ,oID : String) -> Any? {
        
        let evalue = oCAT.rawValue  ; //gives the string, 
        let eobj = objectCategoryTypes(rawValue: "generic")
        
        
    //our object collection might contain a lot of stuff
    //with this we try to find, say, our onliners group
    
        return nil
    }	//end of findObjectByName
    
    func findObjectByType  ( oCAT : objectCategoryTypes ,oID : String ) -> Any? {
    
    
    //our object collection might contain a lot of stuff
    //with this we try to find, say, our onliners group
        return nil
    
    }	//end of findObjectByType
    
    
    /*func findObjectByStatus (keysArr : [] , statusFlag :Bool ,status:Int , oCAT : objectCategoryTypes , oID:String ) -> Any? {
    
        //our object collection might contain a lot of stuff
        //with this we try to find, say, our onliners group
        
    
    }	//end of findObjectByStatus
    
    */
    
    func removeObject ( oCAT : objectCategoryTypes ,oID : String) -> Bool {
    
    
        //delete(me.myObjects[oCAT][oID]);
        //NONO send this object the DIE signal. this might take a while
        //notify the object about being dropped. it may exist, it may be listening
        //the object can react if it needs to or it has a react hook
        //parent object implements its own scenario, we are not doing that here
    
        //stop listening to this fellow
        //delete (me.listeners[oID]);
    
        return true;
    }
    
    
    
    
    func addListener (oCAT : objectCategoryTypes ,oID : String , name : String ) -> DROPcategoryTypes? {
    
        let lco = listeners.count
        if (lco > maxListeners) {
            
            //this is real trouble. some bug is making us to listen to 10000 users. should not happen
            //strategy for this is to create a similar object and intelligently migrate from me to it
            //this should cause a purge to remove fluff. let scheduler make a descision here
            
            return DROPcategoryTypes.maxListenerObjectsExceeded
            
        }
        
        listeners.append(oID)
        return nil
        
        /*if (listeners[oID] != nil ) {
            
            return nil; //if this exists, just ignore
            
        }
        
        listeners[oID] = name; */
        
        //if message queue dies, my TTL will run out and i will die
        //main loop should keep an eye on message queue and scheduler
        //if scheduler dies all objects will be purged anyway
        
        
        //me.listeners.push(handler);
        //retain ref to handler to remove it
        //me.listeners[oID]=handler;
        return nil
    
    }
    
    func _initialize () -> DROPcategoryTypes? {
        
        
        isInitialized = true;
        return nil
        
    }
    
    func _housekeep () -> DROPcategoryTypes? {
        
        //returns a DROP type if something is not cool
        if self.name == "jsonStreamReader" {
            
            let glis = 1;
        }
        if (self.terminated) {
            return DROPcategoryTypes.terminating
        }
        if (self.isHibernating){
            return DROPcategoryTypes.hibernating
        }
        
        
        if ( self.uxT() > self.TTL ) {
            
            //run out of time to live 
            //return self._teardown();
            return self._finalize();    //this guy might have a finalizer
            return DROPcategoryTypes.terminating;
        }
        
        if (self.isProcessing == true) {
            
            //update current latency
            let t = uxT()-processingStartUnixTimestamp
            latency = t
            
            //warn scheduler if im taking too much time processing something
            if latency > maxLatencyKillGap {
                //good idea to suicide here?
                self._teardown();
                return DROPcategoryTypes.busyProcessingExceedingLatencyKillGap
            }
            
            if latency > maxLatencyWarningGap {
                return DROPcategoryTypes.busyProcessingExceedingLatencyWarningGap
            }
            
            //dont update maxLatency, when we kill this obj, we can see if it froze with a code bug or too much data etcc
            
            /*if (maxLatency<t){
                maxLatency = t
            }*/
            
            //significant load alert?
            
            return DROPcategoryTypes.busyProcessesing
        }
        
        //unlikely to get housekeep during teardown. if master housekeeps slave objects, this returning false to master
        //will only lead to master ignoring the result
        
        //motherobject will immediately kill this object when getting a false to _housekeep
        //should we return a DROP instead, busy terminating
        
        //allow multiple calls to housekeep
        //first see if ttl has expired, _teardown if it has
        
        //then check if we are housekeeping by some other request and ignore if we are
        //if this guy freezes while housekeeping, TTL will make sure it gets purged
        
        return _housekeep_extend()
    }
    
    func _housekeep_extend() -> DROPcategoryTypes? {
        
        //should we do this at listener level. listen_extend DOES NOT CONTAIN anything vital
        //just ignore the request with a DROP, the request will come again if its important
        
        
        return nil
    }
    
    func _finalize () -> DROPcategoryTypes? {
        
        if (self.terminated) { return DROPcategoryTypes.terminating; }
        if (self.isFinalizing) { return DROPcategoryTypes.finalizing }
        
        //isFinalizing never needs to change to false again.
        self.isFinalizing = true
        
        //finalize is called if this guy has to save data or something
        
        //finalize ends in teardown
        
        
        return _teardown()
        
    }
    
    func _teardown () -> DROPcategoryTypes? {
        
        if (self.terminated) { return DROPcategoryTypes.terminating; }
        //this happens when the object wants to self terminate. say everybody goodbye, release resources..
        self.terminated = true;
        self.muted = true;
        
        //see final latency for processor load etc
        if (self.isProcessing == true) {
            
            //update current latency
            let t = uxT()-processingStartUnixTimestamp
            latency = t
            
            //dont update maxLatency, when we kill this obj, we can see if it froze with a code bug or too much data etcc
            
            if maxLatency != 0 {
                //ignore initial latency values
                if (maxLatency<t){
                    
                        //
                }
                
            }
            //significant load alert?
            
            //return DROPcategoryTypes.busyProcessesing
        }
        
        
        //we might be terminating asynchronously
        //the EXIT does not go to scheduler. Scheduler just terminates the object.terminated
        
        EXIT(exitcode: "teardown", reason: "blaa");
        
        let ssi = serviceStatusItem(name: self.name, data: 0, ttl: self.TTL, active: true, isProcessing : false );
        
        DispatchQueue.global(qos: .userInitiated).async {
            serviceStatusJunctionObserver.update(ssi);
        }
        
        return DROPcategoryTypes.terminating    //hello mother, im done terminating, get rid of me
        
    }
    
    
    func psychoKiller () -> DROPcategoryTypes? {
    
        //return a DROP if im busy or whatever
        /*const me=this;
        const cats = Object.keys(me.myObjects);
        if (cats.length === 0) { return false; }
        var purged = false;
    
        //indiscriminantly kills from all categories
        Object.keys(me.myObjects).forEach(function(key) {
    
        var c = Object.keys(obj[key]);
    
        //console.log(key, obj[key]);
        Object.keys(c).forEach(function(ckey) {
    
        //console.log(ckey, c[ckey]);
        });
    
    
        });
    
        if (purged && me.exitWhenEmpty) {
    
        me.EXIT('EMPTY')
        return;*/
    
       //end psychokiller
        return nil
    
    }	//gets rid of zombie children without talking to them at all
    
    
    
    func _pulse ( pulseBySeconds : Double? ) -> Bool {
        
        //if the object is doing a long calculation,
        //pulse the object after calc is finished. if the calc takes too long, the object reports drops from its housekeep
        //TTL goes down, termination happens
        if (self.terminated) { return false; }  //nothing can save us now
        
        //var me=this;
        //this keeps this object alive
        //gets triggered on meaningful interaction
        //good place to test for a CRASH
        /*
        if (extendBySeconds===undefined){
        extendBySeconds=me.PULSEextendBySecondsDefault;
        }
    
        try {
        me.TTL+=extendBySeconds;
        } catch(e){
        me.CRASH('_pulse',e)
        }
        */
        
        TTL = uxT()  + pulseBySeconds! ?? PULSEextendBySecondsDefault
//        if let t = pulseBySeconds {
//            TTL = TTL + t;
//        } else {
//            
//            TTL = TTL + self.PULSEextendBySecondsDefault;
//        }
        
        //PULSEextendBySecondsDefault
        
        return true
        
    }   //end of _pulse
    
    func say ( o : CommMessage ) -> Bool {
    
//    var me=this;
    
        //try {
        //my objects can talk to me via this hook
        //o.category,o.myID,o.myCategory, o.whatHaveYou
        /*o.categoryID = me.myCategory;
        o.myID = me.myID;
    
        if (me.myCategory==='user') {
    
        //console.log('tit');
        }
    
        Object.keys(me.listeners).forEach(function(key) {
        if(me.name==='websocket'){
        //me.debuMess('websocket talking to '+key+' '+o.type);
        } else {
        me.debuMess(me.name+' saying to '+key+' '+o.type);
        var lum=true;
    
        }
        //var c = Object.keys(me.listeners[key]);
        fakeMQTT.say(key,o); //me.listeners[key](o);
    
        }); */
    
        return true;
    
    
    }	//end of say
    

        func sayDirect (o : CommMessage , targetuID: String ) -> Bool {
    
        //swift note. SAY goes thru mqtt, sayDirect through global object pool via interstellar
    
        //THIS IS RESERVED for messages that can expect to have a object linkage (run on the same instance)
        //MAYBE change this behaviour to use a message queue so as not to assume any direct object links anywhere in the system
    
        //try {
        //my objects can talk to me via this hook
        //o.category,o.myID,o.myCategory, o.whatHaveYou
        /*o.categoryID = me.myCategory;
        o.myID = me.myID;
    
        if (me.myCategory==='user') {
    
            console.log('tit');
        }
    
        Object.keys(me.listeners).forEach(function(key) {
        if(me.name==='websocket'){
            me.debuMess('websocket talking to '+key+' '+o.type);
        }
        if (key===targetuID){
        //var c = Object.keys(me.listeners[key]);
        me.listeners[key](o);
        }
        });*/
    
        return true;
    
    
    }	//end of sayDirect
    
    
    func SAY (o : CommMessage ) -> Bool {
    
        //my objects can talk to me via this hook
        //o.category,o.myID,o.myCategory, o.whatHaveYou
        //this would be our MQTT hook
        /*
    
        //try {
        //my objects can talk to me via this hook
        //o.category,o.myID,o.myCategory, o.whatHaveYou
        o.categoryID = me.myCategory;
        o.myID = me.myID;
    
    
        Object.keys(me.listeners).forEach(function(key) {
    
            //var c = Object.keys(me.listeners[key]);
            //me.listeners[key](o);
            fakeMQTT.SAY(key,o);
        });
        */
        if listeners.isEmpty {
            return false;
        }
        
        //goes to message queue. the reply will come later
        
        for oID in listeners {
            
            let io = internalMessage(from : myID, to : oID, name: name,  o : o)
            
            //DispatchQueue.main.async {
                self.messageQueue?.LISTEN(i: io);
            //}
            
        }
        
        
        return true;
    
    
    
    }	//end of SAY
    
    //func sayToCategory ( o : CommMessage, oCAT : objectCategoryTypes) -> Bool
    //sayToCategory is not necessary. pull objects in category trough scheduler and add as listeners
    
    
    func LISTEN (o : internalMessage ) -> DROPcategoryTypes? {
    
        //ALL messages come thru this
        //if im terminated or muted, ignore 
        //whoever initializes the SAY might be interested in my result
        //too complicated maybe, just returning false might work
        //or just dont expect anything from the listener function
        //answers will come as messages sometime somewhere
        
        
        if (self.terminated==true){
            return DROPcategoryTypes.terminating
        }
        
        if (self.isFinalizing==true){
            return DROPcategoryTypes.finalizing
        }
        
        if (self.muted==true){
            return DROPcategoryTypes.busyProcessesing
        }
        
        /*
    
        //my objects can talk to me via this hook
        //the o comes always with a oCat, oID, type
        var me=this;
        //console.log(me.myCategory);
    
        if (self.muted) {
    
        //we are tearing down, dont listen to anything anymore
            return;
        }
    
        //dont filter here. fake websocket has no idea of oID' and shit
    
    
        var oCat = o.categoryID;
        var oID = o.myID;
        //me.debuMess("message got from "+oCat+' :: '+oID);
    
        //q: how will i get this message if listener is not attached?
        //a: if it is relayed.
        //even directly attaching user to websocket, it will give messages not for the the user
        //so we need to filter here
    
        //console.log(o.type);
    
        //first pick the crucial ones
        //catch all for these, return after execute
        switch (o.type) {
            case 'EXIT':
                me.debuMess("EXIT message got from "+o.oCAT+' :: '+o.oID);
                me.debuMess("EXIT message listened by "+me.myID+' :: '+me.myCategory+' :: '+me.name);
    
            //groups etc take action of a member exits
                if (me.EXIT_purgeMember!==undefined){
                    var res = me.EXIT_purgeMember(o);
                    if (res.type==='EXIT'){
        //make sure this objo is gone
        me.removeObject(res.oCAT,res.oID);
        return res;
				}
				var tb=1;
        }
        return;
        break;
        case 'CRASH':
    
        break;
        case 'TIMEOUT':
    
        break;
        case 'DROP':
    
        break;
    
        case 'PING':
    
        break;
    
        */
//        }
    
        //o.category,o.myID,o.myCategory, o.whatHaveYou
        
        
        return _LISTEN_extend(o: o)
//        if (me._LISTEN_extend!==undefined){
//    
//            //whatever custom stuff happens with the objo
//            var res = me._LISTEN_extend(o);
//            return res;	//propagate exit or parent to caller
//        }
    
    
    }	//end of exit
    
    func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        //should we do this at listener level. listen_extend DOES NOT CONTAIN anything vital
        //just ignore the request with a DROP, the request will come again if its important

        
        return nil
    }
    
    //THESE return voids, object does not care if the message got passed or not
    
    func EXIT (exitcode : String , reason : String ) -> Void {
    
        //this might be because TTL has run out
        //clean exit with exit code, reason
        
        //have the exit code call _finalize etc before this
        //does the scheduler care about EXIT messages? NO
        let o = CommMessage.EXIT(type: "EXIT",reason: reason, oCAT : self.myCategory ,oID: self.myID,exitcode: exitcode)
        
        //var o = [ "type" : "EXIT", "reason" : reason ,"oCAT": self.myCategory, "oID": myID , "exitcode": exitcode ] as [String : Any];
        
        SAY(o: o)
        
        //this should go to my supervisors
        /*
        var me=this;
        this.muted = true;
        var o = {'type':'EXIT', 'reason' : reason ,'oCAT': me.myCategory, 'oID':me.myID, 'exitcode':exitcode};
    
        Obase[me.myID].terminated = true;
    
        setTimeout(function(){
            Object.keys(me.listeners).forEach(function(key) {
                //this will also ping the object that is talking to me
        /on our test env
                //var c = Object.keys(me.listeners[key]);
                //me.listeners[key](o);
                fakeMQTT.SAY(key,o);
            });
        },100)
        */
        //send my EXIT message, then teardown
        
        
    
    }	//end of exit
    
    func CRASH ( exitCode : String , reason : String ) -> Void {
        
        //case CRASH(type : String , reason : String, oCAT : objectCategoryTypes , oID: String, exitCode : String , latency : Double )
        let com = CommMessage.CRASH(type:"CRASH",reason:reason,oCAT:self.myCategory,oID:self.myID,exitCode : exitCode,latency:self.maxLatency)
        self.SAY(o: com);

        
        
        //var o = [ "type" : "CRASH", "reason" : reason ,"oCAT": self.myCategory, "oID": myID , "name": name ] as [String : Any];
        self.muted = true;
        self.terminated = true;
        //TODO crash should run _teardown to terminate location services etc
        
    /*var me=this;
    me.debuMess('CRASH ::'+me.myCategory+' : '+me.myID);
    me.debuObj(reason);
    me.debuMess('setting me to MUTED. not listening to anything anymore');
    
    //clean exit with exit code, reason
    this.muted = true;
    
    return ( {'type':'CRASH','myID':this.myID,'myCategory':this.myCategory,'code':code,'reason':reason} );
        */
        
    }	//end of CRASH
    
    //gameGroup has its own ping
    func PING (reason : String ) -> Void {
    
        
    
        //pings affiliate objects when setting  propagateListenersToChild
        //this way loungeUI knows about this object
        //me.debuMess('PING ::'+me.myCategory+' : '+me.myID);
    
        //var o = [ "type" : "PING" , "reason" : reason , "oCAT": self.myCategory, "oID":self.myID , "name": self.name ] as [String : Any];
    
        //self.SAY( o:o ) //says to all who are listening
    
        
        
    }	//end of PING
    
    //TIMEOUT is a special message sent to scheduler when processing is taking too long
    //too loong like over maxLatency. this message will be preceded by many DROPs if the
    //object is accessed for processing more stuff
    //if the process is just crunching away on the background with no accesses from outside, this would indicate its taking a bit too long to complete
    //estimate maxLatency for each processing intensive task on _initialize
    //apply a timeout termination strategy on the object
    //scheduler should kill it away if it drops too much, TTL
    //TIMEOUT is a FRIENDLY NOTIFIER about things taking too long
    
    
    /*func TIMEOUT ( exitcode : String ,reason : String ) -> [] {
     
        //something is taking too long. timeout is a notification to my supervisor
        //TIMEOUT would be DROP with DROPcategoryTypes.busy / busyProcessing .. busy Something
        //timeouting will result in TTL dropping below zero and the object EXITing
        
        return  ["type":"TIMEOUT","myID":self.myID,"myCategory":self.myCategory,"code":exitcode,"reason":reason] ;

    }	//end of TIMEOUT */
    
    
    func DROP ( dropCode : DROPcategoryTypes ,reason : String ) -> Void {
    
    //notify that we had to drop data because of low mem or some other reason
    //the parent object has to implement its own memory pressure release mechanism
    //so we dont do anything here
        //let com = [ "type" : "DROP" , "myID" : self.myID ,"myCategory" : self.myCategory,"code" : dropCode ,"reason":reason ,"latency":maxLatency] as [String : Any] ;
        
        //case DROP(type : String , reason : String, oCat : objectCategoryTypes , oID: String, dropCode : DROPcategoryTypes , latency : Double )
        
        
        let com = CommMessage.DROP(type:"DROP",reason:reason,oCAT:self.myCategory,oID:self.myID,dropCode:dropCode,latency:self.maxLatency)
        self.SAY(o: com);
        
        
        //implement drop strategy per object
        //scheduler could try to terminate too old gamegroups by decreasing their ttl
        //say im dropping
        
        
    }
    
    func _purgeDEPRE ( backPressure : Int ) -> Int {
        
        //if im processing, do x
        //backpressure is 1 (warning) 99999999... (GTFO now)
        
        //returns a guesstimate how much pressure is relieved with my action
        
        //if not, just drop my TTL
        //the objects are somewhere else anyway
        //Scheduler just asks me to purge, i react how i react
        
        //objects die out with TTL only, nothing stays for too long anyway
        //look at TTL shortage implementation on timeWaster
        
        //default purge does absolutely nothing. you are stuck with us baby
        //return a big number if this object is ready to be purged with the next scheduler housekeep
        //that will release backpressure and the scheduler will have another round to keep purging if its still not happy
        
        
        return 0
    }
    
    func _purge ( backPressure : Int ) -> Int {
        
        //default purge. all objects obey to purge except .debugger, .uniqueServiceProvider
        if myCategory == objectCategoryTypes.debugger { return backPressure }
        if myCategory == objectCategoryTypes.uniqueServiceProvider { return backPressure }
        
        //uniqServiceProviders can try to stay alive and force lesser processes to die
        //by just removing one tick of backpressure
        
        //if im processing, do x
        //backpressure is 1 (warning) 99999999... (GTFO now)
        
        if (backPressure > purgeRequestEXITtreshold ) {
            
            self._teardown()
            let rema = backPressure - purgeRequestEXITtreshold
            return rema //too much back pressure, just bail out
        }
        
        isPurging = true
        
        let b = Double ( backPressure * 30 )
        let TTLdeducted = self.TTL - b //deduct by one housekeep round
        
        if (TTLdeducted < self.uxT()){
            
            self._teardown()    //some objects need finalize, timewaster does not
            return backPressure
        }
        
        TTL = TTLdeducted   //_pulse() will keep this up if something meaningful happens
        //in timewasters case it never does and we will teardown
        //some other object would do purge in a different way, block incoming data..
        
        return 1    //down by one click
        
        
        //returns a guesstimate how much pressure is relieved with my action
        
        //if not, just drop my TTL
        //the objects are somewhere else anyway
        //Scheduler just asks me to purge, i react how i react
        
        //objects die out with TTL only, nothing stays for too long anyway
        
        //default purge does absolutely nothing. you are stuck with us baby
        
        return 0
    }

    func DIE () -> Bool {
    
        //direct message from motherObject. there are no silent deaths here, every termination results is
        //a bunch of EXIT messages
        //scheduler can do this
        
        //this will kill finalizer if one exists
        
        //run my termination handler
        self._teardown();
    
        return true
    }
    
    func _hibernate () -> DROPcategoryTypes? {
        
        if self.terminated { return DROPcategoryTypes.terminating }
        if self.isHibernating { return DROPcategoryTypes.hibernating }
        
        switch (self.myHibernationStrategy) {
            
        case .hibernate :
            
            return self._hibernate_extend()
            
        case .finalize :
                return self._finalize()
            
        case .persist :
            
            return self._hibernate_extend()
            //return DROPcategoryTypes.persisting
            
        default :
            
            return self._teardown()
        }
    }
    
    func _hibernate_extend () -> DROPcategoryTypes? {
        
        if self.terminated { return DROPcategoryTypes.terminating }
        self.isHibernating = true;
        
        return DROPcategoryTypes.hibernating
    }
    
    func _unhibernate () -> DROPcategoryTypes? {
        
        if self.terminated { return DROPcategoryTypes.terminating }
        if !self.isHibernating { return DROPcategoryTypes.generic }
        
        self.isHibernating = false;
        self._pulse(pulseBySeconds: 30) //give this guy some time to get his shit together
        
        let ssi = serviceStatusItem(name: self.name, data: 0, ttl: self.TTL, active: true, isProcessing : self.isProcessing );
        
        DispatchQueue.global(qos: .userInitiated).async {
            serviceStatusJunctionObserver.update(ssi);
        }
        
        return DROPcategoryTypes.wokeUpFromHibernation
    }
    
    func startProcessing () -> DROPcategoryTypes? {
        
        //start any calculation with this, keep track of object latency
        
        if ( self.isProcessing == true) {
            //DROP(dropCode: DROPcategoryTypes.busyProcessesing, reason: "busy")
            return DROPcategoryTypes.busyProcessesing;
        }
        
        if ( self.terminated == true){
            return DROPcategoryTypes.terminating;   //dont do any processing if terminated
            //should we do this at listener level. listen_extend does not contain anything vital
            //just ignore the request with a DROP, the request will come again if its important
        }
        
        if (self.isFinalizing) {
            
            //dont allow processing when we are finalizing
            return DROPcategoryTypes.finalizing
        }
        
        processingStartUnixTimestamp = uxT()
        isProcessing = true;
        //var latency = 0.0;
        //var maxLatency = 0.0
        //var isProcessing = false;
        
        //NOTE: using the queue might be bad juju
        
        //let service status take care of reading statuses
        //having observers firing all over the place is bad juju
        //addition: service statuses are updated on housekeep which is too slow
        //processing takes a very short time
        
        //tell serviceStatusJunctionObserver what im up to
        let ssi = serviceStatusItem(name: self.name, data: 0, ttl: self.TTL, active: true, isProcessing : true );
        
        DispatchQueue.global(qos: .userInitiated).async {
            serviceStatusJunctionObserver.update(ssi);
        }
        
        return nil
    }   //end startProcessing
    
    func finishProcessing () -> Bool {
        
        //we might be terminating, purging, finalizing here
        //accessing this wont affect any of those
        
        if (self.isProcessing==false) { return false }
        let t = uxT()-processingStartUnixTimestamp
        latency = t
        if (maxLatency<t){
            maxLatency = t
        }
        isProcessing = false;
        
        let ssi = serviceStatusItem(name: self.name, data: 0, ttl: self.TTL, active: true, isProcessing : true );
        
        DispatchQueue.global(qos: .userInitiated).async {
            serviceStatusJunctionObserver.update(ssi);
        }
        
        return true
    }
    
    func isLowPowerModeEnabled () -> Bool {
        return false;
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            // Low Power Mode is enabled. Start reducing activity to conserve energy.
            return true;
        }
        
        return false;
        
    }
    
    func serviceStatusDataHook () -> Double {
        
        return 0;
        
    }
    
    func updateConfigurationValue ( key : liveConfigurationTypes , val : Any ) -> Bool {
        
        //this is going to be a big method with all of the live conf values. pain in the ass
        //conf values are read only to other methods, updating them at any time should not be a problem
        switch (key) {
            
        case liveConfigurationTypes.maxCategoryObjects :
            
            //needs to be debounced, dont flood all objects with new values all the time
            
            //   //type coercion to tell that we are indeed receiving a double as Any
            //the following will not crash
            
            if let no = (val as? Double) {
                self.maxCategoryObjects = Int(no)
                return true
            }
            
            //break;
            //maxListeners
            
            //fallthrough  do the next case
            
        case liveConfigurationTypes.maxListeners :
            
            //needs to be debounced, dont flood all objects with new values all the time
            self.maxListeners = val as! Int
            
            return true
            
            break;
            
            
        default :
            
            break;
            
        }   //various conf handler hooks
        
        
        return false
        
    }   //end update configuration value
    
    func uxT () -> Double {
        
        //throw all adjusted timing code here
        return Date().timeIntervalSince1970;
        
    }
    
    func hasTimeoutExpired (timestamp : Double , timeoutInMs : Double) -> Bool {
    
        let appLocalUnixTime = Date().timeIntervalSince1970
        
        let vari = timestamp + timeoutInMs;
        
        if (appLocalUnixTime < vari ) { return false; }
        
        return true;
    }
    
    
    func randomTrueFalse () -> Bool
    {
        let a = self.randomIntFromInterval(min: 0,max: 1)
        if (a == 1) { return true; }
        return false;
    }
    
    
    func randomIntFromInterval (min : Double, max : Double) -> Double
    {
        let r = max - min;
        let av = arc4random_uniform(UInt32(r));
        let ax = Double(av) + min;
        return ax;
    }
    
    
    
    //swift compat hooks
//on global dispatch queue
//onLowMemoryWarning
//onLostNetwork

//most messages move even when onLostNetwork
//depending on memorypressure, things might get deallocated
// runobserver (mapping and reducing location data)
// rundispatcher (reacts to network events)

}


