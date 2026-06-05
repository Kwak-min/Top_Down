
package com.topdown.guard
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.os.IBinder
import android.provider.Settings
import android.view.*
import android.widget.TextView
class OverlayBlockService: Service(){private var view:View?=null;override fun onBind(i:Intent?):IBinder?=null;override fun onStartCommand(i:Intent?,f:Int,s:Int):Int{if(!Settings.canDrawOverlays(this))return START_NOT_STICKY;if(view==null){val tv=TextView(this);tv.text="\uC704\uD5D8\uD55C \uBB38\uC790\uC785\uB2C8\uB2E4\n\uB204\uB974\uC9C0 \uB9C8\uC138\uC694\n\uAC00\uC871\uC774\uB098 \uBCF4\uD638\uC790\uC5D0\uAC8C \uD655\uC778\uD558\uC138\uC694";tv.textSize=30f;tv.setTextColor(Color.WHITE);tv.setBackgroundColor(Color.rgb(185,28,28));tv.gravity=Gravity.CENTER;val p=WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT,WindowManager.LayoutParams.MATCH_PARENT,WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,android.graphics.PixelFormat.TRANSLUCENT);(getSystemService(WINDOW_SERVICE) as WindowManager).addView(tv,p);view=tv};return START_NOT_STICKY}override fun onDestroy(){view?.let{(getSystemService(WINDOW_SERVICE) as WindowManager).removeView(it)};view=null}}
