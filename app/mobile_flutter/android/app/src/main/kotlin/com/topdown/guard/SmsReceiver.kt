package com.topdown.guard
import android.content.*
import android.provider.Telephony
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
class SmsReceiver: BroadcastReceiver(){override fun onReceive(context: Context, intent: Intent){if(intent.action!="android.provider.Telephony.SMS_RECEIVED")return;val msgs=Telephony.Sms.Intents.getMessagesFromIntent(intent);for(m in msgs){Thread{try{val body=JSONObject();body.put("sender",m.originatingAddress ?: "unknown");body.put("message",m.messageBody ?: "");body.put("user_profile","senior");val conn=URL("http://10.0.2.2:8000/api/analyze").openConnection() as HttpURLConnection;conn.requestMethod="POST";conn.setRequestProperty("Content-Type","application/json");conn.doOutput=true;OutputStreamWriter(conn.outputStream).use{it.write(body.toString())};val resp=conn.inputStream.bufferedReader().readText();if(resp.contains("\"verdict\":\"block\"")||resp.contains("\"touch_block_required\":true")){context.startService(Intent(context,OverlayBlockService::class.java))}}catch(_:Exception){}}.start()}}}
