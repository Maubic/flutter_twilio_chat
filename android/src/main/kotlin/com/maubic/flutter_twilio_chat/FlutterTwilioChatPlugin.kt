package com.maubic.flutter_twilio_chat

import androidx.annotation.NonNull;
import android.content.Context
import java.io.ByteArrayOutputStream
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.twilio.conversations.CallbackListener
import com.twilio.conversations.ConversationsClient
import com.twilio.conversations.ConversationsClient.Properties
import com.twilio.conversations.ConversationsClientListener
import com.twilio.conversations.Conversation
// import com.twilio.conversations.ConversationDescriptor
import com.twilio.conversations.ConversationListener
import com.twilio.conversations.Participant
import com.twilio.conversations.User
import com.twilio.conversations.Message
// import com.twilio.conversations.Message.Media
import com.twilio.conversations.ErrorInfo
// import com.twilio.conversations.Paginator
import com.twilio.conversations.Attributes
import com.twilio.conversations.StatusListener
import com.twilio.conversations.ProgressListener
import com.maubic.flutter_twilio_chat.fromJson
import com.maubic.flutter_twilio_chat.toMap
import com.maubic.flutter_twilio_chat.toList

/** FlutterTwilioChatPlugin */
public class FlutterTwilioChatPlugin
  : FlutterPlugin
  , MethodCallHandler
  , StreamHandler
  , ConversationsClientListener
{
  private var eventSink: EventSink? = null
  private var conversationsClient: ConversationsClient? = null
  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    println("Attached")
    val context: Context = flutterPluginBinding.getApplicationContext()
    val messenger: BinaryMessenger = flutterPluginBinding.getFlutterEngine().getDartExecutor()
    val plugin: FlutterTwilioChatPlugin = FlutterTwilioChatPlugin()
    plugin.context = context

    val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_twilio_chat")
    methodChannel.setMethodCallHandler(plugin)

    val eventChannel: EventChannel = EventChannel(messenger, "flutter_twilio_chat_events")
    eventChannel.setStreamHandler(plugin)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }

  // TODO
  override fun onConversationSynchronizationChange(conversation: Conversation) {
    
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      println("Registered")
      val context: Context = registrar.context()
      val messenger: BinaryMessenger = registrar.messenger()
      val plugin: FlutterTwilioChatPlugin = FlutterTwilioChatPlugin()
      plugin.context = context

      val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_twilio_chat")
      methodChannel.setMethodCallHandler(plugin)

      val eventChannel: EventChannel = EventChannel(messenger, "flutter_twilio_chat_events")
      eventChannel.setStreamHandler(plugin)
    }
  }

  // Flutter callbacks
  override fun onListen(arguments: Any?, events: EventSink) {
    this.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    this.eventSink = null
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "initialize") {
      val token: String = call.argument<String>("token")!!
      //val region: String = call.argument<String>("region") ?: "de1"
      val properties: ConversationsClient.Properties = ConversationsClient.Properties.Builder()
        // This errors out?
        //.setRegion(region)
        .createProperties()
      val plugin: FlutterTwilioChatPlugin = this
      println("Creating chat client")
      //ConversationsClient.setLogLevel(android.util.Log.DEBUG);
      ConversationsClient.create(
        this.context!!,
        token,
        properties,
        object: CallbackListener<ConversationsClient>() {
          override fun onSuccess(client: ConversationsClient) {
            println("Success")
            client.setListener(plugin)
            plugin.conversationsClient = client

            client.getChannels().getUserChannelsList(object: CallbackListener<Paginator<ChannelDescriptor>>() {
              override fun onSuccess(paginator: Paginator<ChannelDescriptor>) {
                paginator.getAll(
                  { channels: List<ChannelDescriptor> ->
                    val channelData: List<Map<String, Any>> = channels.map(::serializeChannelDescriptor)
                    getAllLastMessages(channels, { messages: List<Message> ->
                      println("Received messages")
                      val messageData: List<Map<String, Any?>> = messages.map(::serializeMessage)
                      result.success(mapOf(
                        "channels" to channelData,
                        "messages" to messageData
                      ))
                    }, { errorInfo: ErrorInfo ->
                      println("Error in getAllLastMessages: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                      result.error("ConversationsClientCreateError", errorInfo.getMessage(), null)
                    })
                  },
                  { errorInfo: ErrorInfo ->
                    println("Error in getAll: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                    result.error("ConversationsClientCreateError", errorInfo.getMessage(), null)
                  }
                )
              }
              override fun onError(errorInfo: ErrorInfo) {
                println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                result.error("ConversationsClientCreateError", errorInfo.getMessage(), null)
              }
            })

            //result.success(null)
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error in getUserChannelsList: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("ConversationsClientCreateError", errorInfo.getMessage(), null)
          }
        }
      )
    } else if (call.method == "sendSimpleMessage") {
      val channelId: String = call.argument<String>("channelId")!!
      val messageText: String = call.argument<String>("messageText")!!
      println("sendSimpleMessage")

      this.conversationsClient?.getConversation(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Conversation) {
            println("Recovered channel")
            channel.whenSynchronized({
              channel.getMessages().sendMessage(
                Message.options().withBody(messageText),
                object: CallbackListener<Message>() {
                  override fun onSuccess(message: Message) {
                    println("Sent message")
                    result.success(null)
                  }
                  override fun onError(errorInfo: ErrorInfo) {
                    println("Error in sendMessage: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                    result.error("SendSimpleMessageError", errorInfo.getMessage(), null)
                  }
                }
              )
            })
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error in getChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("SendSimpleMessageError", errorInfo.getMessage(), null)
          }
        }
      )
    } else if (call.method == "sendAttachmentMessage") {
      val channelId: String = call.argument<String>("channelId")!!
      val attachmentData: ByteArray = call.argument<ByteArray>("attachmentData")!!
      val type: String = call.argument<String>("type")!!

      this.conversationsClient?.getConversation(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Conversation) {
            println("Recovered channel")
            channel.whenSynchronized({
              channel.getMessages().sendMessage(
                Message.options().withMedia(attachmentData.inputStream(), type),
                object: CallbackListener<Message>() {
                  override fun onSuccess(message: Message) {
                    println("Sent message")
                    result.success(null)
                  }
                  override fun onError(errorInfo: ErrorInfo) {
                    println("Error in sendMessage: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                    result.error("SendSimpleMessageError", errorInfo.getMessage(), null)
                  }
                }
              )
          })
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error in getChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("SendAttachmentMessageError", errorInfo.getMessage(), null)
          }
        }
      )
    } else if (call.method == "markAsRead") {
      val channelId: String = call.argument<String>("channelId")!!
      this.conversationsClient?.getConversation(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Conversation) {
            println("Recovered channel")
            channel.whenSynchronized({
              // Workaround: A veces no salta el evento "onChannelJoined", lo forzamos
              serializeChannel(
                channel,
                { channelData: Map<String, Any> ->
                  eventSink?.success(mapOf(
                    "event" to "ChannelJoined",
                    "channel" to channelData
                  ))
                },
                { errorInfo: ErrorInfo ->
                  println("Error in serializeChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                }
              )
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
      )
    // getAttachment: UNUSED
    } else if (call.method == "getAttachment") {
      val channelId: String = call.argument<String>("channelId")!!
      val index: Long = call.argument<Long>("index")!!
      this.ConversationsClient?.channels?.getChannel(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Conversation) {
            println("Recovered channel")
            channel.whenSynchronized({
              channel.getMessages().getMessageByIndex(
                index,
                object: CallbackListener<Message>() {
                  override fun onSuccess(message: Message) {
                    if (!message.hasMedia()) {
                      result.error("GetAttachmentError", "Message does not have media", null)
                    } else {
                      val media: Media = message.getMedia()
                      val size: Long = media.getSize()
                      val outputStream: ByteArrayOutputStream = ByteArrayOutputStream(size.toInt())
                      media.download(
                        outputStream,
                        object: StatusListener() {
                          override fun onSuccess() {
                            println("Downloaded media")
                            result.success(outputStream.toByteArray())
                          }
                          override fun onError(errorInfo: ErrorInfo) {
                            println("Error in download: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                            result.error("GetAttachmentError", errorInfo.getMessage(), null)
                          }
                        },
                        object: ProgressListener() {
                          override fun onStarted() {
                            println("Media download onStarted")
                          }
                          override fun onProgress(bytes: Long) {
                            println("Media download onProgress: ${bytes}")
                          }
                          override fun onCompleted(mediaSid: String) {
                            println("Media download onCompleted: ${mediaSid}")
                          }
                        }
                      )
                    }
                  }
                  override fun onError(errorInfo: ErrorInfo) {
                    println("Error in getMessageByIndex: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                    result.error("GetAttachmentError", errorInfo.getMessage(), null)
                  }
                }
              )
            })
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error in getChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("GetAttachmentError", errorInfo.getMessage(), null)
          }
        }
      )
    } else if (call.method == "updateToken") {
      val token: String = call.argument<String>("token")!!
      this.conversationsClient?.updateToken(token, object: StatusListener {
        override fun onSuccess() {
          println("Token updated")
          result.success(null)
        }
        override fun onError(errorInfo: ErrorInfo) {
          println("Error in updateToken: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
          result.error("UpdateTokenError", errorInfo.getMessage(), null)
        }
      })
    } else if (call.method == "recoverMessages") {
      val channelId: String = call.argument<String>("channelId")!!
      val firstIndex: Long = call.argument<Long>("firstIndex")!!
      this.conversationsClient?.getConversation(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Conversation) {
            println("Recovered channel")
            channel.whenSynchronized({
              channel.getMessages().getMessagesBefore(
                firstIndex,
                50,
                object: CallbackListener<List<Message>>() {
                  override fun onSuccess(messages: List<Message>) {
                    val messageData: List<Map<String, Any?>> = messages.map(::serializeMessage)
                    result.success(messageData)
                  }
                  override fun onError(errorInfo: ErrorInfo) {
                    println("Error in getMessagesBefore: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                    result.error("RecoverMessagesError", errorInfo.getMessage(), null)
                  }
                }
              )
            })
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error in getChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("RecoverMessagesError", errorInfo.getMessage(), null)
          }
        }
      )
    } else {
      result.notImplemented()
    }
  }

  // Twilio callbacks
  override fun onChannelJoined(channel: Conversation?) {
    println("onChannelJoined")
    if (channel != null) {
      channel.whenSynchronized({
        serializeChannel(
          channel,
          { channelData: Map<String, Any> ->
            eventSink?.success(mapOf(
              "event" to "ChannelJoined",
              "channel" to channelData
            ))
          },
          { errorInfo: ErrorInfo ->
            println("Error in serializeChannel: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
          }
        )
      })
    }
  }
  override fun onChannelInvited(channel: Conversation?) {
    println("onChannelInvited")
  }
  override fun onChannelAdded(channel: Conversation?) {
    println("onChannelAdded")
  }
  override fun onChannelUpdated(channel: Conversation, reason: Conversation.UpdateReason?) {
    println("onChannelUpdated")
    if (reason == Conversation.UpdateReason.LAST_MESSAGE) {
      println("Last message changed")
      channel.whenSynchronized({
        serializeChannel(
          channel,
          { channelData: Map<String, Any> ->
            channel.getMessages().getLastMessages(1, object: CallbackListener<List<Message>>() {
              override fun onSuccess(messages: List<Message>) {
                println("Message retrieved")
                val message = messages[0]
                eventSink?.success(mapOf(
                  "event" to "NewMessage",
                  "message" to serializeMessage(message),
                  "channel" to channelData
                ))
              }
              override fun onError(errorInfo: ErrorInfo) {
                println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
              }
            })
          },
          { errorInfo: ErrorInfo ->
            println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
          }
        )
      })
    } else if (reason == Conversation.UpdateReason.LAST_CONSUMED_MESSAGE_INDEX) {
      println("Last consumed message changed")
      channel.whenSynchronized({
        serializeChannel(
          channel,
          { channelData: Map<String, Any> ->
            eventSink?.success(mapOf(
              "event" to "ChannelUpdated",
              "channel" to channelData
            ))
          },
          { errorInfo: ErrorInfo ->
            println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
          }
        )
      })
    }
  }
  override fun onChannelDeleted(channel: Conversation?) {
    println("onChannelDeleted")
  }
  override fun onChannelSynchronizationChange(channel: Conversation?) {
    println("onChannelSynchronizationChange")
  }
  override fun onError(errorInfo: ErrorInfo?) {
    println("onError")
  }
  override fun onClientSynchronization(status: ConversationsClient.SynchronizationStatus?) {
    println("onClientSynchronization")
  }
  override fun onConnectionStateChange(state: ConversationsClient.ConnectionState?) {
    println("onConnectionStateChange")
  }
  override fun onTokenExpired() {
    println("onTokenExpired")
    eventSink?.success(mapOf(
      "event" to "TokenExpired"
    ))
  }
  override fun onTokenAboutToExpire() {
    println("onTokenAboutToExpire")
    eventSink?.success(mapOf(
      "event" to "TokenAboutToExpire"
    ))
  }
  override fun onUserUpdated(user: User?, reason: User.UpdateReason?) {
    println("onUserUpdated")
  }
  override fun onUserSubscribed(user: User?) {
    println("onUserSubscribed")
  }
  override fun onUserUnsubscribed(user: User?) {
    println("onUserUnsubscribed")
  }
  override fun onNewMessageNotification(channelSid: String?, messageSid: String?, messageIndex: Long) {
    println("onNewMessageNotification")
  }
  override fun onAddedToChannelNotification(channelSid: String?) {
    println("onAddedToChannelNotification")
  }
  override fun onInvitedToChannelNotification(channelSid: String?) {
    println("onInvitedToChannelNotification")
  }
  override fun onRemovedFromChannelNotification(channelSid: String?) {
    println("onRemovedFromChannelNotification")
  }
  override fun onNotificationSubscribed() {
    println("onNotificationSubscribed")
  }
  override fun onNotificationFailed(errorInfo: ErrorInfo?) {
    println("onNotificationFailed")
  }
}

// Helper functions
fun <T> Paginator<T>.getAll(
  onSuccess: (items: List<T>) -> Unit,
  onError: (error: ErrorInfo) -> Unit
) {
  this.getAllPlus(listOf(), onSuccess, onError)
}

fun <T> Paginator<T>.getAllPlus(
  items: List<T>,
  onSuccess: (items: List<T>) -> Unit,
  onError: (error: ErrorInfo) -> Unit
) {
  val paginatorItems = this.getItems()
  if (this.hasNextPage()) {
    this.requestNextPage(object: CallbackListener<Paginator<T>>() {
      override fun onSuccess (res: Paginator<T>) {
        val addedItems: List<T> = items.plus(paginatorItems)
        res.getAllPlus(addedItems, onSuccess, onError)
      }
      override fun onError (err: ErrorInfo) {
        onError(err)
      }
    })
  } else {
    onSuccess(items.plus(paginatorItems))
  }
}

fun getAllLastMessages(
  channels: List<ChannelDescriptor>,
  onSuccess: (messages: List<Message>) -> Unit,
  onError: (error: ErrorInfo) -> Unit
) {
  getAllLastMessagesPlus(listOf(), channels, onSuccess, onError)
}

fun getAllLastMessagesPlus(
  plusMessages: List<Message>,
  channels: List<ChannelDescriptor>,
  onSuccess: (messages: List<Message>) -> Unit,
  onError: (error: ErrorInfo) -> Unit
) {
  if (channels.isEmpty()) {
    onSuccess(plusMessages)
  } else {
    val channelDescriptor: ConversationDescriptor = channels[0]
    channelDescriptor.getChannel(object: CallbackListener<Channel>() {
      override fun onSuccess (channel: Conversation) {
        channel.whenSynchronized({
          channel.getMessages().getLastMessages(50, object: CallbackListener<List<Message>>() {
            override fun onSuccess (messages: List<Message>) {
              getAllLastMessagesPlus(
                plusMessages.plus(messages),
                channels.drop(1),
                onSuccess,
                onError
              )
            }
            override fun onError (errorInfo: ErrorInfo) {
              onError(errorInfo)
            }
          })
        })
      }
      override fun onError (err: ErrorInfo) {
        onError(err)
      }
    })
  }
}

fun Conversation.whenSynchronized(
  onSuccess: () -> Unit
) {
  if (this.getSynchronizationStatus().isAtLeast(Channel.SynchronizationStatus.ALL)) {
    onSuccess()
  } else {
    this.addListener(object: ConversationListener {
      override fun onSynchronizationChanged(channel: Conversation) {
        if (channel.getSynchronizationStatus().isAtLeast(Channel.SynchronizationStatus.ALL)) {
          channel.removeAllListeners()
          onSuccess()
        }
      }
      // Rest of the events
      override fun onMessageAdded(message: Message) {}
      override fun onMessageUpdated(message: Message, reason: Message.UpdateReason) {}
      override fun onMessageDeleted(message: Message) {}
      override fun onMemberAdded(member: Participant) {}
      override fun onMemberUpdated(member: Participant, reason: Participant.UpdateReason) {}
      override fun onMemberDeleted(member: Participant) {}
      override fun onTypingStarted(channel: Conversation, member: Participant) {}
      override fun onTypingEnded(channel: Conversation, member: Participant) {}
    })
  }
}

fun serializeChannelDescriptor(channel: ConversationDescriptor): Map<String, Any> {
  return mapOf(
    "sid" to channel.getSid(),
    "uniqueName" to channel.getUniqueName(),
    "friendlyName" to channel.getFriendlyName(),
    "attributes" to serializeAttributes(channel.getAttributes()),
    "createdBy" to channel.getCreatedBy(),
    "unconsumedCount" to channel.getUnconsumedMessagesCount(),
    "dateUpdated" to channel.getDateUpdated().getTime()
  )
}

fun serializeChannel(channel: Conversation, onSuccess: (channelData: Map<String, Any>) -> Unit, onError: (errorInfo: ErrorInfo) -> Unit) {
  channel.getUnconsumedMessagesCount(object: CallbackListener<Long>() {
    override fun onSuccess(count: Long) {
      onSuccess(mapOf(
        "sid" to channel.getSid(),
        "uniqueName" to channel.getUniqueName(),
        "friendlyName" to channel.getFriendlyName(),
        "attributes" to serializeAttributes(channel.getAttributes()),
        "createdBy" to channel.getCreatedBy(),
        "unconsumedCount" to count,
        "dateUpdated" to channel.getDateUpdatedAsDate().getTime()
      ))
    }
    override fun onError(errorInfo: ErrorInfo) {
      onError(errorInfo)
    }
  })
}

fun serializeMessage(message: Message): Map<String, Any?> {
  return mapOf(
    "sid" to message.getSid(),
    "body" to message.getMessageBody(),
    "attributes" to serializeAttributes(message.getAttributes()),
    "author" to message.getAuthor(),
    "dateCreated" to message.getDateCreated(),
    "channelSid" to message.getChannelSid(),
    "hasMedia" to message.hasMedia(),
    "index" to message.getMessageIndex(),
    "mediaSid" to message.getMedia()?.getSid()
  )
}

fun serializeAttributes(attributes: Attributes): String {
  return attributes.getJSONObject().toString()
}
