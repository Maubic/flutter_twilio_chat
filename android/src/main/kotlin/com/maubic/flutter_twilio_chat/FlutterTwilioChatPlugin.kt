package com.maubic.flutter_twilio_chat

import androidx.annotation.NonNull;
import android.content.Context;
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
import com.twilio.chat.CallbackListener
import com.twilio.chat.ChatClient
import com.twilio.chat.ChatClient.Properties
import com.twilio.chat.ChatClientListener
import com.twilio.chat.Channel
import com.twilio.chat.User
import com.twilio.chat.Message
import com.twilio.chat.ErrorInfo

/** FlutterTwilioChatPlugin */
public class FlutterTwilioChatPlugin
  : FlutterPlugin
  , MethodCallHandler
  , StreamHandler
  , ChatClientListener
{
  private var eventSink: EventSink? = null
  private var chatClient: ChatClient? = null
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
      val properties: ChatClient.Properties = ChatClient.Properties.Builder()
        // This errors out?
        //.setRegion(region)
        .createProperties()
      val plugin: FlutterTwilioChatPlugin = this
      println("Creating chat client")
      //ChatClient.setLogLevel(android.util.Log.DEBUG);
      ChatClient.create(
        this.context!!,
        token,
        properties,
        object: CallbackListener<ChatClient>() {
          override fun onSuccess(client: ChatClient) {
            println("Success")
            client.setListener(plugin)
            plugin.chatClient = client
            result.success(null)
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("ChatClientCreateError", errorInfo.getMessage(), null)
          }
        }
      )
    } else if (call.method == "sendSimpleMessage") {
      val channelId: String = call.argument<String>("channelId")!!
      val messageText: String = call.argument<String>("messageText")!!
      println("sendSimpleMessage")

      this.chatClient?.channels?.getChannel(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Channel) {
            println("Recovered channel")
            channel.getMessages().sendMessage(
              Message.options().withBody(messageText),
              object: CallbackListener<Message>() {
                override fun onSuccess(message: Message) {
                  println("Sent message")
                  channel.dispose()
                  result.success(null)
                }
                override fun onError(errorInfo: ErrorInfo) {
                  println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                  channel.dispose()
                  result.error("SendSimpleMessageError", errorInfo.getMessage(), null)
                }
              }
            )
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("SendSimpleMessageError", errorInfo.getMessage(), null)
          }
        }
      )
    } else if (call.method == "markAsRead") {
      val channelId: String = call.argument<String>("channelId")!!
      this.chatClient?.channels?.getChannel(
        channelId,
        object: CallbackListener<Channel>() {
          override fun onSuccess(channel: Channel) {
            println("Recovered channel")
            channel.getMessages().setAllMessagesConsumedWithResult(
              object: CallbackListener<Long>() {
                override fun onSuccess(index: Long) {
                  channel.dispose()
                  result.success(null)
                }
                override fun onError(errorInfo: ErrorInfo) {
                  println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
                  channel.dispose()
                  result.error("MarkAsReadError", errorInfo.getMessage(), null)
                }
              }
            )
          }
          override fun onError(errorInfo: ErrorInfo) {
            println("Error: ${errorInfo.getStatus()} ${errorInfo.getCode()} ${errorInfo.getMessage()}")
            result.error("MarkAsReadError", errorInfo.getMessage(), null)
          }
        }
      )
    } else {
      result.notImplemented()
    }
  }

  // Twilio callbacks
  override fun onChannelJoined(channel: Channel?) {
    println("onChannelJoined")
  }
  override fun onChannelInvited(channel: Channel?) {
    println("onChannelInvited")
  }
  override fun onChannelAdded(channel: Channel?) {
    println("onChannelAdded")
  }
  override fun onChannelUpdated(channel: Channel?, reason: Channel.UpdateReason?) {
    println("onChannelUpdated")
  }
  override fun onChannelDeleted(channel: Channel?) {
    println("onChannelDeleted")
  }
  override fun onChannelSynchronizationChange(channel: Channel?) {
    println("onChannelSynchronizationChange")
  }
  override fun onError(errorInfo: ErrorInfo?) {
    println("onError")
  }
  override fun onClientSynchronization(status: ChatClient.SynchronizationStatus?) {
    println("onClientSynchronization")
  }
  override fun onConnectionStateChange(state: ChatClient.ConnectionState?) {
    println("onConnectionStateChange")
  }
  override fun onTokenExpired() {
    println("onTokenExpired")
  }
  override fun onTokenAboutToExpire() {
    println("onTokenAboutToExpire")
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
