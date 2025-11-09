package com.example.test_app

import android.os.Bundle
import com.jcraft.jsch.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.test_app/ssh"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "execute") {
                    val host = call.argument<String>("host")!!
                    val port = call.argument<Int>("port")!!
                    val username = call.argument<String>("username")!!
                    val password = call.argument<String>("password")!!
                    val command = call.argument<String>("command")!!

                    // Запускаем в фоновом потоке
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val jsch = JSch()
                            val session = jsch.getSession(username, host, port)
                            session.setPassword(password)
                            session.setConfig("StrictHostKeyChecking", "no")
                            session.setConfig("UserKnownHostsFile", "/dev/null")
                            session.connect(10000)

                            val channel = session.openChannel("exec") as ChannelExec
                            channel.setCommand(command)
                            val stream = channel.inputStream
                            channel.connect()

                            val output = stream.bufferedReader().readText()
                            channel.disconnect()
                            session.disconnect()

                            // Возвращаем результат в UI-потоке
                            withContext(Dispatchers.Main) {
                                result.success(output)
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            withContext(Dispatchers.Main) {
                                result.error("SSH_ERROR", e.message ?: "Unknown error", e.toString())
                            }
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}