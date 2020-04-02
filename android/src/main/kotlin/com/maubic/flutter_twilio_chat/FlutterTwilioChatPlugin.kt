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
      val region: String = call.argument<String>("region") ?: "gll"
      val properties: ChatClient.Properties = ChatClient.Properties.Builder()
        //.setRegion(region)
        .createProperties()
      val plugin: FlutterTwilioChatPlugin = this
      println("Creating chat client")
      println(token)
      ChatClient.setLogLevel(android.util.Log.DEBUG);
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
                  result.success(null)
                }
              }
            )
          }
        }
      )
    } else {
      result.notImplemented()
    }
  }

  override fun onChannelJoined(channel: Channel?) {}
  override fun onChannelInvited(channel: Channel?) {}
  override fun onChannelAdded(channel: Channel?) {}
  override fun onChannelUpdated(channel: Channel?, reason: Channel.UpdateReason?) {}
  override fun onChannelDeleted(channel: Channel?) {}
  override fun onChannelSynchronizationChange(channel: Channel?) {}
  override fun onError(errorInfo: ErrorInfo?) {}
  override fun onClientSynchronization(status: ChatClient.SynchronizationStatus?) {}
  override fun onConnectionStateChange(state: ChatClient.ConnectionState?) {}
  override fun onTokenExpired() {}
  override fun onTokenAboutToExpire() {}
  override fun onUserUpdated(user: User?, reason: User.UpdateReason?) {}
  override fun onUserSubscribed(user: User?) {}
  override fun onUserUnsubscribed(user: User?) {}
  override fun onNewMessageNotification(channelSid: String?, messageSid: String?, messageIndex: Long) {
    println("onNewMessageNotification")
  }
  override fun onAddedToChannelNotification(channelSid: String?) {}
  override fun onInvitedToChannelNotification(channelSid: String?) {}
  override fun onRemovedFromChannelNotification(channelSid: String?) {}
  override fun onNotificationSubscribed() {}
  override fun onNotificationFailed(errorInfo: ErrorInfo?) {}
}
