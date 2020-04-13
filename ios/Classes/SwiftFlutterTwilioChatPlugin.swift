import Flutter
import UIKit
import TwilioChatClient

public class SwiftFlutterTwilioChatPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var eventSink:FlutterEventSink?
    public var chatClient: TwilioChatClient?
    public var connected: Bool = false
    public var myChannels = [NSDictionary]()
    public var myMessages = [NSDictionary]()
    var delegate:ChannelManager?
    
    override init() {
        super.init()
        delegate = ChannelManager.sharedManager
        delegate?.plugin = self
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    public func sendDataToFlutter(data: NSDictionary) {
        if (eventSink == nil) {
            print("[Maubic - FlutterTwilioChat] EventSink does not exists")
            return
        }
        eventSink!(data)
    }
    
    public func sendDataToFlutter(data: String) {
        if (eventSink == nil) {
            print("[Maubic - FlutterTwilioChat] EventSink does not exists")
            return
        }
        eventSink!(data)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let channel = FlutterMethodChannel(name: "flutter_twilio_chat", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_twilio_chat_events", binaryMessenger: registrar.messenger())
        
        /* TODO SNA KOTLIN
        val context: Context = registrar.context()
        val messenger: BinaryMessenger = registrar.messenger()
        val plugin: FlutterTwilioChatPlugin = FlutterTwilioChatPlugin()
        plugin.context = context
        */
        
        let instance = SwiftFlutterTwilioChatPlugin()
        
        eventChannel.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        
    }
    
    func traceLevel(depth: String, val: inout Int, inc: Bool) {
        var direction: String
        if (inc) {
            direction = "+"
            val+=1
        } else {
            direction = "-"
            val-=1
        }
        
        print("[Maubic - FlutterTwilioChat] Group Level Depth \(depth) : \(val) \(direction)")
    }
    
//    private var eventSink: EventSink? = null
//    private var chatClient: ChatClient? = null
//    private var context: Context? = null
    
    func initializeClientWithToken(token: String, flutterResult: @escaping FlutterResult) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        print("[Maubic - FlutterTwilioChat] Connecting...")
        TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: delegate) { [weak self] result, chatClient in
            guard (result.isSuccessful()) else { return }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            print("[Maubic - FlutterTwilioChat] Connected: true")
            self?.connected = true
            self?.chatClient = chatClient

            let dicRoom : NSDictionary = [
                "sid" : "CHda3a360e6cde486091e4f4324bd0dd35",
                "uniqueName" : "0d5c0c4f-6668-4f22-b813-fa4989311924",
                "friendlyName" : "Grupo de prueba Twilio 3",
                "attributes" : "{}",
                "createdBy" : "Sergio",
                "unconsumedCount" : 1, // SNA: get Unconsumed Count
                "dateUpdated" : 1586661404000,
            ]
            
            let myMessage : NSDictionary = [
                "sid" : "CHda3a360e6cde486091e4f4324bd0dd35",
                "body" : "Hola Mundo",
                "attributes" : "{}",
                "author" : "Sergio",
                "dateCreated" : "2020-02-27T19:00:00Z",
                "channelSid": "CHda3a360e6cde486091e4f4324bd0dd35",
                "index": 1,
                "mediaSid": "CHda3a360e6cde486091e4f4324bd0dd35",
            ]
  
            let group = DispatchGroup()
            var level = 0
            
            self!.traceLevel(depth: "1", val: &level, inc: true)
            group.enter() // 1
            
            if (chatClient?.channelsList() == nil) {
                self!.traceLevel(depth: "1", val: &level, inc: false)
                group.leave() // 1 - No channels.
            }
            
            // Espera a que se haya completado la sincronización. ChannelManager - synchronizationStatusUpdated
            self?.delegate?.synchronizationGroup.notify(queue: DispatchQueue.main) {
                chatClient?.channelsList()?.userChannelDescriptors(completion: { (res, paginator) in
                    if (res.isSuccessful()) {
                        self!.traceLevel(depth: "2", val: &level, inc: true)
                        group.enter() // 2 - Processing received channel list.
                        self!.traceLevel(depth: "1", val: &level, inc: false)
                        group.leave() // 1 - Successful
                        for channelDescriptor in (paginator?.items())! {
                            self!.traceLevel(depth: "3", val: &level, inc: true)
                            group.enter() // 3 - foreach ChannelDescriptor
                            print("[Maubic - FlutterTwilioChat] Connected - Channel: \(channelDescriptor.friendlyName ?? "NO_CHANNEL")")
                            self?.myChannels.append((self?.toNSDictionary(channel: channelDescriptor))!)

                            
                            channelDescriptor.channel(completion:{ (result, channel) in
                                if result.isSuccessful() {
                                    self!.traceLevel(depth: "3", val: &level, inc: false)
                                    group.leave() // 3 - foreach ChannelDescriptor - Got channel from channel descriptor
                                    if (channel?.messages != nil) {
                                        self!.traceLevel(depth: "4", val: &level, inc: true)
                                        group.enter() // 4 - Getting last messages
                                    }
                                    channel?.messages?.getLastWithCount(100, completion: { (result, messages) in
                                        if result.isSuccessful() {
                                            for message in messages! {
                                                print("[Maubic - FlutterTwilioChat]: \(String(describing: message.body))")
                                                self?.myMessages.append((self?.toNSDictionary(message: message, channelSid: ((channel?.sid)!)))!)
                                            }
                                            self!.traceLevel(depth: "4", val: &level, inc: false)
                                            group.leave() // 4 - Getting last messages. All ready.
                                        } else {
                                            print("[Maubic - FlutterTwilioChat]: getLastWithCount ERROR - " + result.error.debugDescription)
                                            self!.traceLevel(depth: "4", val: &level, inc: false)
                                            group.leave() // 4 - Getting last messages. Failed.
                                        }
                                    })
                                } else {
                                    self!.traceLevel(depth: "3", val: &level, inc: false)
                                    group.leave() // 3 - foreach ChannelDescriptor - not successful
                                }
                            })
                        }
                        self!.traceLevel(depth: "2", val: &level, inc: false)
                        group.leave() // 2 - Processing received channel list - All channels processed
                    } else {
                        self!.traceLevel(depth: "1", val: &level, inc: false)
                        print("[Maubic - FlutterTwilioChat]: ERROR - " + res.error.debugDescription)
                        group.leave() // 1 - not successful
                    }

                })
            } //synchronizationGroup
            
            group.notify(queue: DispatchQueue.main) {
                print("[Maubic - FlutterTwilioChat] DONE Group Level: \(level)")
                let myResult: NSDictionary = [
                    "channels" : self?.myChannels as Any,
                    "messages" : self?.myMessages as Any,
                    //"channels" : [dicRoom],
                    //"messages" : [myMessage]
                ]
                print("[Maubic - FlutterTwilioChat] Connected: true - flutterResult")
                flutterResult(myResult)
            }
            

        }
    }
    
    // TODO: Refactor this to something that makes sense.
    private func serializeAttributes(attributes: TCHJsonAttributes?) -> String {
        var result : String
        if (attributes != nil) {
            if (attributes?.dictionary != nil && attributes?.dictionary?.count ?? 0 > 0) {
                result = "{"
                for item in (attributes?.dictionary!)! {
                    let key: String = item.key as! String
                    var value: String = ""
                    if item.value is String {
                        value = "\"" + (item.value as! String) + "\""
                    } else if item.value is Bool {
                        let res = item.value as! Bool
                        if (res) {
                            value = "true"
                        } else {
                            value = "false"
                        }
                    } else if item.value is Int {
                        value = item.value as! String
                    } else {
                        value = ""
                    }
                    //let value: String = item.value as! String
                    result += "\""+key+"\":"+value+","
                }
                result = result.dropLast() + "}"
            } else {
                result = "{}"
            }
        } else {
            result = "{}"
        }
        return result
    }
    

    public func toNSDictionary(channel: TCHChannel) -> NSDictionary {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        //let dateUpdated = channel.dateUpdated?.timeIntervalSince1970 ?? 0.0
        // SNA: OJO, corregir la fecha!
        let dateUpdated = Date.init(timeIntervalSinceNow: 0).timeIntervalSince1970
        //var attributes: Any
        
        let dicRoom : NSDictionary = [
            "sid" : channel.sid as Any,
            "uniqueName" : channel.uniqueName as Any,
            "friendlyName" : channel.friendlyName as Any,
            //"friendlyName" : "",
            "attributes" : self.serializeAttributes(attributes: channel.attributes()) as Any,
            //"attributes" : "{}",
            "createdBy" : channel.createdBy as Any,
            "unconsumedCount" : 0, // SNA: get Unconsumed Count
            "dateUpdated" : Int(dateUpdated*1000),
        ]
        return dicRoom
    }
    
    public func toNSDictionary(channel: TCHChannelDescriptor) -> NSDictionary {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateUpdated = channel.dateUpdated?.timeIntervalSince1970 ?? 0.0
        //var attributes: Any
        
        let dicRoom : NSDictionary = [
            "sid" : channel.sid as Any,
            "uniqueName" : channel.uniqueName as Any,
            "friendlyName" : channel.friendlyName as Any,
            //"friendlyName" : "",
            "attributes" : self.serializeAttributes(attributes: channel.attributes()) as Any,
            //"attributes" : "{}",
            "createdBy" : channel.createdBy as Any,
            "unconsumedCount" : 0, // SNA: get Unconsumed Count
            "dateUpdated" : Int(dateUpdated*1000),
        ]
        return dicRoom
    }
    
    public func toNSDictionary(message: TCHMessage, channelSid: String) -> NSDictionary {
        
        let messageDict : NSDictionary = [
            "sid" : message.sid as Any,
            "body" : message.body as Any,
            "attributes" : self.serializeAttributes(attributes: message.attributes()) as Any,
            "author" : message.author as Any,
            "dateCreated" : message.timestamp as Any,
            "channelSid" : channelSid as Any,
            "hasMedia" : message.hasMedia() as Any,
            "index" : message.index as Any,
            "mediaSid" : message.mediaSid as Any,
        ]
        return messageDict
        
    }
    
    
    func updateToken(token: String, flutterResult: @escaping FlutterResult) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        print("[Maubic - FlutterTwilioChat] Connecting...")
        chatClient?.updateToken(token) { (result) in
            if (!result.isSuccessful()) {
                // warn the user the update didn't succeed
            } else {
                flutterResult(true)
            }
        }
    }
    

    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        self.delegate?.chatClient(client, channelDeleted: channel)
    }

/*
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == TCHClientSynchronizationStatus.completed {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            ChannelManager.sharedManager.channelsList = client.channelsList()
            ChannelManager.sharedManager.populateChannels()
            loadGeneralChatRoomWithCompletion { success, error in
                if success {
                    self.presentRootViewController()
                }
            }
        }
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
*/
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let flutterResult : FlutterResult = result
        print("[Maubic - FlutterTwilioChat] calling: " + call.method)
        switch(call.method) {
        case "getPlatformVersion":
            flutterResult("iOS " + UIDevice.current.systemVersion)
            
        case "initialize":
            print("[Maubic - FlutterTwilioChat] Connect: " + call.method)
            
            guard let args = call.arguments else { return }

            if let myArgs = args as? [String: Any] {
                guard let token = myArgs["token"] as? String else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no token provided: (initalize) \(args)",
                        details: nil))
                    return
                }

                print("[Maubic - FlutterTwilioChat] accessToken \(token)")
                
                initializeClientWithToken(token: token, flutterResult: flutterResult)
  
//             KOTLIN
//            val token: String = call.argument<String>("token")!!
//            val properties: ChatClient.Properties = ChatClient.Properties.Builder()
//            .createProperties()
//            val plugin: FlutterTwilioChatPlugin = this
//            println("Creating chat client")
            }
        case "sendSimpleMessage":
            print("[Maubic - FlutterTwilioChat] SendSimpleMessage")
            
            guard let args = call.arguments else { return }
            
            if let myArgs = args as? [String: Any] {
                guard let channelId = myArgs["channelId"] as? String else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no channelId provided: (sendSimpleMessage) \(args)",
                        details: nil))
                    return
                }
                guard let messageText = myArgs["messageText"] as? String else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no message provided: (sendSimpleMessage) \(args)",
                        details: nil))
                    return
                }
                
                chatClient?.channelsList()?.channel(withSidOrUniqueName: channelId, completion: { (result, channel) in
                    if result.isSuccessful() {
                        print("[Maubic - FlutterTwilioChat] SendSimpleMessage - Channel Recovered")
                        // SNA: whenSynchronized?
                        if let messages = channel?.messages {
                          let options = TCHMessageOptions().withBody(messageText)
                          messages.sendMessage(with: options) { result, message in
                            if result.isSuccessful() {
                              print("[Maubic - FlutterTwilioChat] SendSimpleMessage - Message sent.")
                            } else {
                              print("[Maubic - FlutterTwilioChat] SendSimpleMessage - Message NOT sent.")
                            }
                          }
                        }
                    }
                })
                
            }
            return
        case "sendAttachmentMessage":
            print("[Maubic - FlutterTwilioChat] sendAttachmentMessage")
            
            guard let args = call.arguments else { return }
            
            if let myArgs = args as? [String: Any] {
                guard let channelId = myArgs["channelId"] as? String else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no channelId provided: (sendAttachmentMessage) \(args)",
                        details: nil))
                    return
                }
                guard let data = myArgs["attachmentData"] as? FlutterStandardTypedData else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no attachmentData provided: (sendAttachmentMessage) \(args)",
                        details: nil))
                    return
                }
                
                guard let type = myArgs["type"] as? String else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no type provided: (sendAttachmentMessage) \(args)",
                        details: nil))
                    return
                }
                
                chatClient?.channelsList()?.channel(withSidOrUniqueName: channelId, completion: { (result, channel) in
                    if result.isSuccessful() {
                        print("[Maubic - FlutterTwilioChat] sendAttachmentMessage - Channel Recovered")
                        // SNA: whenSynchronized?
                        if let messages = channel?.messages {
                            
                            let messageOptions = TCHMessageOptions()
                            let inputStream = InputStream(data: data.data)
                            messageOptions.withMediaStream(inputStream,
                                                         contentType: type,
                                                         defaultFilename: "default.jpg",
                                                         onStarted: {
                                                          // Called when upload of media begins.
                                                          print("[Maubic - FlutterTwilioChat] sendAttachmentMessage - Media upload started")
                          },
                                                         onProgress: { (bytes) in
                                                          // Called as upload progresses, with the current byte count.
                                                          print("[Maubic - FlutterTwilioChat] sendAttachmentMessage - Media upload progress: \(bytes)")
                          }) { (mediaSid) in
                              // Called when upload is completed, with the new mediaSid if successful.
                              // Full failure details will be provided through sendMessage's completion.
                              flutterResult(true)
                              print("[Maubic - FlutterTwilioChat] sendAttachmentMessage - Media upload completed")
                          }

                          messages.sendMessage(with: messageOptions) { result, message in
                            if result.isSuccessful() {
                              print("[Maubic - FlutterTwilioChat] sendAttachmentMessage - Message sent.")
                            } else {
                              print("[Maubic - FlutterTwilioChat] sendAttachmentMessage - Message NOT sent.")
                            }
                          }
                        }
                    }
                })
                
            }
            return
        case "markAsRead":
            // SNA TODO:
            /*
             val channelId: String = call.argument<String>("channelId")!!
             this.chatClient?.channels?.getChannel(
               channelId,
               object: CallbackListener<Channel>() {
                 override fun onSuccess(channel: Channel) {
                   println("Recovered channel")
                   channel.whenSynchronized({
                     channel.getMessages().setAllMessagesConsumedWithResult(
                       object: CallbackListener<Long>() {
                         override fun onSuccess(index: Long) {
                           result.success(null)
                         }
                         override fun onError(errorInfo: ErrorInfo) {
                           println("Error in setAllMessagesConsumed: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                           result.error("MarkAsReadError", errorInfo.getMessage(), null)
                         }
                       }
                     )
                   })
                 }
                 override fun onError(errorInfo: ErrorInfo) {
                   println("Error in getChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                   result.error("MarkAsReadError", errorInfo.getMessage(), null)
                 }
               }
             */
            return;
        case "updateToken":
            guard let args = call.arguments else { return }
            
            if let myArgs = args as? [String: Any] {
                guard let token = myArgs["token"] as? String else {
                    flutterResult(FlutterError(
                        code: "ERR_RESULT",
                        message: "[Maubic - FlutterTwilioChat]: no token provided: (updateToken) \(args)",
                        details: nil))
                    return
                }
                return self.updateToken(token: token, flutterResult: flutterResult);
            }
        case "connect - NO":
            return;
            /*
            print("[Maubic - PusherChatkitPlugin] Connect: " + call.method)
            
            guard let args = call.arguments else { return }
            
            if let myArgs = args as? [String: Any] {
                let instanceLocator = myArgs["instanceLocator"] as? String
                let accessToken = myArgs["accessToken"] as? String
                let tokenProviderURL = myArgs["tokenProviderURL"] as? String
                let userId = myArgs["userId"] as? String
                var pcTokenProvider = PCTokenProvider(
                    url: tokenProviderURL!
                )
                if ((accessToken) != nil) {
                    print("[Maubic - PusherChatkitPlugin] accessToken \(accessToken ?? "")")
                    pcTokenProvider = PCTokenProvider(
                        url: tokenProviderURL!,
                        requestInjector: { req in
                            req.addHeaders(["Authorization" : accessToken!])
                            return req
                    })
                } else {
                    print("[Maubic - PusherChatkitPlugin] accessToken null")
                }
                
                self.chatManager = ChatManager(
                    instanceLocator: instanceLocator!, //Your Chatkit Instance ID
                    tokenProvider: pcTokenProvider,
                    userID: userId!
                )
                
                // Connect to Chatkit by passing in the ChatManagerDelegate you defined at the top of this class.
                // https://pusher.com/docs/chatkit/reference/swift#connecting
                self.chatManager!.connect(delegate: SwiftFlutterChatkitPluginChatManagerDelegate(eventSink:eventSink!)) { (currentUser, error) in
                    guard(error == nil) else {
                        print("[Maubic - PusherChatkitPlugin] Error connecting: \(error!.localizedDescription)")
                        return
                    }
                    
                    // PCCurrentUser is the main entity you interact with in the Chatkit Swfit SDK
                    // You get it in a callback when successfully connected to Chatkit
                    // https://pusher.com/docs/chatkit/reference/swift#pccurrentuser
                    self.currentUser = currentUser
                    
                    let rooms = currentUser?.rooms
                    
                    print("[Maubic - PusherChatkitPlugin] Connected! \(String(describing: currentUser?.name))'s rooms: \(String(describing: rooms))")
                    
                    var myRooms : Array<NSDictionary> = []
                    for room in currentUser!.rooms {
                        myRooms.append(self.toNSDictionary(room: room))
                    }
                    
                    print("[Maubic - PusherChatkitPlugin] MyRooms \(myRooms)")
                    
                    let myResult: NSDictionary = [
                        "type" : "global",
                        "event" : "CurrentUserReceived",
                        "id" : currentUser?.id ?? "",
                        "name" : currentUser?.name ?? "Unknown user",
                        "rooms" : myRooms,
                    ]
                    
                    DispatchQueue.main.async {
                        self.sendDataToFlutter(data: myResult)
                    }
                    
                    result(currentUser?.id)
                }
                
            } else {
                print("[Maubic - PusherChatkitPlugin]: iOS could not extract flutter arguments in method: (connect) \(args)")
                result(FlutterError(
                    code: "ERR_RESULT",
                    message: "iOS could not extract flutter arguments in method: (connect) \(args)",
                    details: nil)
                )
            }
 */
        case "subscribeToRoom":
            return
            /*
            print("[Maubic - PusherChatkitPlugin] subscribeToRoom: Start. ")
            guard let args = call.arguments else { return }
            if let myArgs = args as? [String: Any] {
                guard let roomId = myArgs["roomId"] as? String else { return }
                
                print("[Maubic - PusherChatkitPlugin] subscribeToRoom: " + roomId)
                
                currentUser!.subscribeToRoomMultipart(id: roomId, roomDelegate: self, completionHandler: { (error) in
                    guard error == nil else {
                        print("[Maubic - PusherChatkitPlugin] Error subscribing to room: \(error!.localizedDescription)")
                        return
                    }
                    print("[Maubic - PusherChatkitPlugin] Successfully subscribed to the room \(roomId)! 👋")
                })
                // SNA TODO: Guardar lista de salas suscritas.
                result(roomId)
            }
 */
        case "unsubscribeFromRoom":
            return
            /*
            print("[Maubic - PusherChatkitPlugin] unsubscribeFromRoom: " + call.method)
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any] {
                guard let roomId = myArgs["roomId"] as? String else { return }
                print("[Maubic - PusherChatkitPlugin] unsubscribeFromRoom: Room " + roomId)
                for room in currentUser!.rooms {
                    if (room.id == roomId) {
                        room.unsubscribe()
                        break
                    }
                }
                // SNA TODO: Guardar lista de salas suscritas.
                //result(room.id)
                result(0)
            }
 */
        case "sendSimpleMessage":
            return
            /*
            // SNA TODO: Enviar mensaje
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any] {
                guard let roomId = myArgs["roomId"] as? String else { return }
                guard let messageText = myArgs["messageText"] as? String else { return }
                
                currentUser?.sendSimpleMessage(roomID: roomId, text: messageText) { message, error in
                    guard error == nil else {
                        print("[Maubic - PusherChatkitPlugin] Error sending message to \(roomId): \(error!.localizedDescription)")
                        result(FlutterError(code: "ERR_RESULT",
                                            message: error!.localizedDescription,
                                            details: nil))
                        return
                    }
                    result(message)
                }
            }
 */
        case "sendAttachmentMessage":
            return
            /*
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any] {
                guard let roomId = myArgs["roomId"] as? String else { return }
                guard let filename = myArgs["filename"] as? String else { return }
                guard let type = myArgs["type"] as? String else { return }
                
                guard let file = FileHandle(forReadingAtPath: filename) else { return; }
                
                if file != nil {
                    // Read all the data
                    let data = file.readDataToEndOfFile()
                    
                    // Close the file
                    file.closeFile()
                    
                    let parts = [PCPartRequest(
                        .attachment(
                            PCPartAttachmentRequest(
                                type: type,
                                file: data,
                                name: filename,
                                customData: ["key": "value"]
                            )
                        )
                        )]
                    
                    currentUser?.sendMultipartMessage(roomID: roomId, parts: parts) { message, error in
                        guard error == nil else {
                            print("[Maubic - PusherChatkitPlugin] Error sending multipart message to \(roomId): \(error!.localizedDescription)")
                            result(FlutterError(code: "ERR_RESULT",
                                                message: error!.localizedDescription,
                                                details: nil))
                            return
                        }
                        result(message)
                    }
                }
                
                
            }
 */
        case "setReadCursor":
            return
            /*
            guard let args = call.arguments else {
                return
            }
            
            
            if let myArgs = args as? [String: Any] {
                guard let roomId = myArgs["roomId"] as? String else { return }
                guard let messageId = myArgs["messageId"] as? Int else { return }
                currentUser?.setReadCursor(position: messageId, roomID: roomId){ error in
                    guard error == nil else {
                        print("[Maubic - PusherChatkitPlugin] Error setting cursor: \(error!.localizedDescription)")
                        result(FlutterError(code: "ERR_RESULT",
                                            message: error!.localizedDescription,
                                            details: nil))
                        return
                    }
                    print("[Maubic - PusherChatkitPlugin] Read cursor successfully updated for \(roomId)! 👋")
                    result(roomId)
                }
            } else {
                //esult.notImplemented();
            }
        */
        default:
            print("[Maubic - FlutterTwilioChat]Not implemented")
            flutterResult("Not implemented")
        }
    }
}

class ChannelManager: NSObject {
    static let sharedManager = ChannelManager()
    
    static let defaultChannelUniqueName = "general"
    static let defaultChannelName = "General Channel"
    
//    weak var delegate:MenuViewController?
    
    var channelsList:TCHChannels?
    var channels:NSMutableOrderedSet?
    var generalChannel:TCHChannel!
    var plugin: SwiftFlutterTwilioChatPlugin?
    var synchronizationGroup:DispatchGroup
    
    
    override init() {
        print("[Maubic - FlutterTwilioChat] Initializing ChannelManager")
        self.synchronizationGroup = DispatchGroup()
        self.synchronizationGroup.enter()
        super.init()
        channels = NSMutableOrderedSet()
    }
    
    // MARK: - General channel
    // SNA: Conectarse a todos los canales.
    func loadGeneralChatRoomWithCompletion(completion:@escaping (Bool, NSError?) -> Void) {
        print("[Maubic - FlutterTwilioChat] loadGeneralChatRoomWithCompletion")
        ChannelManager.sharedManager.joinGeneralChatRoomWithCompletion { succeeded in
            if succeeded {
                print("[Maubic - FlutterTwilioChat] loadGeneralChatRoomWithCompletion: succeeded")
                completion(succeeded, nil)
            }
            else {
                // SNA: Do something on error
                print("[Maubic - FlutterTwilioChat] loadGeneralChatRoomWithCompletion: failed")
                //let error = self.errorWithDescription(description: "Could not join General channel", // code: 300)
                // completion(succeeded, error)
            }
        }
    }
    
    func joinGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
        print("[Maubic - FlutterTwilioChat] joinGeneralChatRoomWithCompletion")

        let uniqueName = ChannelManager.defaultChannelUniqueName
        if let channelsList = self.channelsList {
            channelsList.channel(withSidOrUniqueName: uniqueName) { result, channel in
                self.generalChannel = channel
                
                if self.generalChannel != nil {
                    self.joinGeneralChatRoomWithUniqueName(name: nil, completion: completion)
                } else {
                    self.createGeneralChatRoomWithCompletion { succeeded in
                        if (succeeded) {
                            self.joinGeneralChatRoomWithUniqueName(name: uniqueName, completion: completion)
                            return
                        }
                        
                        completion(false)
                    }
                }
            }
        }
    }
    
    func joinGeneralChatRoomWithUniqueName(name: String?, completion: @escaping (Bool) -> Void) {
        print("[Maubic - FlutterTwilioChat] joinGeneralChatRoomWithUniqueName")
        generalChannel.join { result in
            if ((result.isSuccessful()) && name != nil) {
                self.setGeneralChatRoomUniqueNameWithCompletion(completion: completion)
                return
            }
            completion((result.isSuccessful()))
        }
    }
    
    func createGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
        print("[Maubic - FlutterTwilioChat] createGeneralChatRoomWithCompletion")
        let channelName = ChannelManager.defaultChannelName
        let options = [
            TCHChannelOptionFriendlyName: channelName,
            TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        channelsList!.createChannel(options: options) { result, channel in
            if (result.isSuccessful()) {
                self.generalChannel = channel
            }
            completion((result.isSuccessful()))
        }
    }
    
    func setGeneralChatRoomUniqueNameWithCompletion(completion:@escaping (Bool) -> Void) {
        print("[Maubic - FlutterTwilioChat] setGeneralChatRoomUniqueNameWithCompletion")
        generalChannel.setUniqueName(ChannelManager.defaultChannelUniqueName) { result in
            completion((result.isSuccessful()))
        }
    }
    
    // MARK: - Populate channels
    
    func populateChannels() {
        print("[Maubic - FlutterTwilioChat] populateChannels")
        channels = NSMutableOrderedSet()
        
        channelsList?.userChannelDescriptors { result, paginator in
            print("[Maubic - FlutterTwilioChat] populateChannels - userChannelDescriptors")
            if (paginator != nil) {
                self.channels?.addObjects(from: paginator!.items())
                self.sortChannels()
            }
        }
        
        channelsList?.publicChannelDescriptors { result, paginator in
            print("[Maubic - FlutterTwilioChat] populateChannels - publicChannelDescriptors")
            if (paginator != nil) {
                self.channels?.addObjects(from: paginator!.items())
                self.sortChannels()
            }
        }
        
// SNA
//        if self.delegate != nil {
//            self.delegate!.reloadChannelList()
//        }
    }
    
    func sortChannels() {
        print("[Maubic - FlutterTwilioChat] sortChannels")
        let sortSelector = #selector(NSString.localizedCaseInsensitiveCompare(_:))
        let descriptor = NSSortDescriptor(key: "friendlyName", ascending: true, selector: sortSelector)
        channels!.sort(using: [descriptor])
        
        // SNA: No se pinta listado de canales.
        for item in channels! {
            let chan = item as? TCHChannelDescriptor
            if (chan != nil) {
                print("[Maubic - FlutterTwilioChat] sortChannels - channels: \(chan?.sid ?? "NO_CHAN") \(chan?.uniqueName ?? "NO_CHAN") \(chan?.friendlyName ?? "NO_CHAN")")

            }
        }
        
    }
    
    // MARK: - Create channel
    
    func createChannelWithName(name: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        print("[Maubic - FlutterTwilioChat] createChannelWithName")
        if (name == ChannelManager.defaultChannelName) {
            completion(false, nil)
            return
        }
        
        let channelOptions = [
            TCHChannelOptionFriendlyName: name,
            TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        self.channelsList?.createChannel(options: channelOptions) { result, channel in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            completion((result.isSuccessful()), channel)
        }
    }
}


extension ChannelManager : TCHChannelDelegate {
    
    // SNA TODO: onChannelJoined
    
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {
        print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: messageAdded")
        let channelData = self.plugin?.toNSDictionary(channel: channel)
        channel.messages?.getLastWithCount(1, completion: { (result, messages) in
            if result.isSuccessful() {
                let data : NSDictionary = [
                    "event" : "NewMessage",
                    "message" : self.plugin?.toNSDictionary(message: messages![0], channelSid: channel.sid!) as Any,
                    "channel" : channelData as Any
                ]
                self.plugin?.sendDataToFlutter(data: data)
            } else {
                print("[Maubic - FlutterTwilioChat]: TCHChannelDelegate messageAdded ERROR - " + result.error.debugDescription)
            }
        })
        
    }
 
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: channel Updated")
        if (updated == TCHChannelUpdate.lastConsumedMessageIndex) {
            print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: lastConsumedMessageIndex")
            let channelData = self.plugin?.toNSDictionary(channel: channel)
            let data : NSDictionary = [
                "event" : "ChannelUpdated",
                "channel" : channelData as Any
            ]
            self.plugin?.sendDataToFlutter(data: data)
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberJoined member: TCHMember) {
        print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: memberJoined")
        //addMessages(newMessages: [StatusMessage(member:member, status:.Joined)])
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberLeft member: TCHMember) {
        print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: memberLeft")
        //addMessages(newMessages: [StatusMessage(member:member, status:.Left)])
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: channelDeleted")
        /*
        DispatchQueue.main.async {
            if channel == self.channel {
                self.revealViewController().rearViewController
                    .performSegue(withIdentifier: MainChatViewController.TWCOpenGeneralChannelSegue, sender: nil)
            }
        }*/
    }
    
    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        print("[Maubic - FlutterTwilioChat] TCHChannelDelegate: synchronizationStatusUpdated ")
        /*
        if status == .all {
            loadMessages()
            DispatchQueue.main.async {
                self.tableView?.reloadData()
                self.setViewOnHold(onHold: false)
            }
        }
        */
    }
}

// MARK: - TwilioChatClientDelegate
extension ChannelManager : TwilioChatClientDelegate {
    
    func chatClientTokenWillExpire(_ chatClient: TwilioChatClient) {
        let data : NSDictionary = [
            "event" : "TokenAboutToExpire"
        ]
        self.plugin?.sendDataToFlutter(data: data)
    }

    func chatClientTokenExpired(_ chatClient: TwilioChatClient) {
        let data : NSDictionary = [
            "event" : "TokenExpired"
        ]
        self.plugin?.sendDataToFlutter(data: data)
    }
    
    func chatClient(_ client: TwilioChatClient, typingStartedOn channel: TCHChannel, member: TCHMember) {
        print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: typingStartedOn")
    }

    func chatClient(_ client: TwilioChatClient, typingEndedOn channel: TCHChannel, member: TCHMember) {
        print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: typingEndedOn")
    }
    
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 1 - channel Added")
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels!.add(channel)
                print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: added channel  \(channel.friendlyName ?? "NO_CHAN")")
                self.sortChannels()
            }
            
        let channelData = self.plugin?.toNSDictionary(channel: channel)
            
        let data : NSDictionary = [
            "event" : "ChannelJoined",
            "channel"  : channelData as Any
        ]
            
        self.plugin?.sendDataToFlutter(data: data)
        
// SNA
//            self.delegate?.chatClient(client, channelAdded: channel)
        }
    }
    
    func chatClient2(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 2 - updated \(channel.friendlyName) \(channel.sid)")

// SNA
//        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted2 channel: TCHChannel) {
        print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 3")
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels?.remove(channel)
            }
 
// SNA
//            self.delegate?.chatClient(client, channelDeleted: channel)
        }
      
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 4 - status \(status)")
        if status == TCHClientSynchronizationStatus.completed {
            print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 4 TCHClientSynchronizationStatus.completed")
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            // Ya podemos responder a Initialize.
            ChannelManager.sharedManager.synchronizationGroup.leave()
            ChannelManager.sharedManager.channelsList = client.channelsList()
            ChannelManager.sharedManager.populateChannels()
            

            //ChannelManager.sharedManager.synchronizationGroup.leave()

            // SNA: Conectarse a todos los canales.
            loadGeneralChatRoomWithCompletion { success, error in
                print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 4 - loadGeneralChatRoomWithCompletion \(success)")
                if success {
                    print("[Maubic - FlutterTwilioChat] TwilioChatClientDelegate: chatClient 4 - loadGeneralChatRoomWithCompletion SUCCESSFUL ")
                    // SNA: TODO Something here after success
                }
            }
        }
    }
}
