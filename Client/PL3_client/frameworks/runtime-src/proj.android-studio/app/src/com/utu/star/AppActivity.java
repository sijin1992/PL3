/****************************************************************************
Copyright (c) 2015 Chukong Technologies Inc.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package com.utu.star;

import android.app.AlarmManager;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.util.Log;
import android.view.KeyEvent;
import android.view.WindowManager;

import com.adjust.sdk.Adjust;
import com.adjust.sdk.AdjustEvent;
import com.tendcloud.tenddata.TalkingDataGA;

import org.PayPlugin.GooglePlayIABPlugin;
import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// import com.gameanalytics.sdk.*;

public class AppActivity extends Cocos2dxActivity{
    protected static final String TAG = "AppActivity";
    private PowerManager.WakeLock mWakeLock;
    static String hostIPAdress = "0.0.0.0";
    static String macAddress = "0";
    protected static Context mContext;

    protected GooglePlayIABPlugin mGooglePlayIABPlugin = null;
    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);

        if(nativeIsLandScape()) {
            //setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
			//setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_NOSENSOR)
        } else {
            //setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
			//setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_NOSENSOR)
        }
        
        //2.Set the format of window
        
        // Check the wifi is opened when the native is debug.
        if(nativeIsDebug())
        {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON, WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            if(!isNetworkConnected())
            {
                AlertDialog.Builder builder=new AlertDialog.Builder(this);
                builder.setTitle("Warning");
                builder.setMessage("Please open WIFI for debuging...");
                builder.setPositiveButton("OK",new DialogInterface.OnClickListener() {
                    
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        startActivity(new Intent(Settings.ACTION_WIFI_SETTINGS));
                        finish();
                        System.exit(0);
                    }
                });

                builder.setNegativeButton("Cancel", null);
                builder.setCancelable(true);
                builder.show();
            }
            hostIPAdress = getHostIpAddress();
            macAddress = getAndroidMacID();
        }
        mGooglePlayIABPlugin = new GooglePlayIABPlugin(this);
        mGooglePlayIABPlugin.onCreate(savedInstanceState);
        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        mWakeLock = pm.newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK,"MyLock");
        mWakeLock.acquire();

        //flurry
        //FlurryAgent.setLogEnabled(true);
        //FlurryAgent.setLogLevel(Log.ERROR);
        //FlurryAgent.init(this,  "TFY62MZDJ3T3CXGQ9M5Q");

        //GA

        // Initialize
        /*
        GameAnalytics.initializeWithGameKey(this, "9f6dec435610003c7a9bb88917d7563f", "3ba780a1f744b25e82745a661a0d4a2b124f994b");

        GameAnalytics.setEnabledInfoLog(true);
        GameAnalytics.setEnabledVerboseLog(true);
		*/
        //TD
        TalkingDataGA.init(this, "8BBCC0586EB448159D0922294706E2F8", "10001");
        TalkingDataGA.setVerboseLogDisabled();
        mContext = this.getApplicationContext();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (mGooglePlayIABPlugin != null && mGooglePlayIABPlugin.handleActivityResult(requestCode, resultCode, data)) {
            Log.d(GooglePlayIABPlugin.TAG, "onActivityResult handled by GooglePlayIABPlugin (" + requestCode + "," + resultCode + "," + data);
        } else {
            super.onActivityResult(requestCode, resultCode, data);
        }
    }

    public Cocos2dxGLSurfaceView onCreateView() {
        Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);
        // IABPluginDemo2dx should create stencil buffer
//        glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0);
        glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);

		// quan mian ping by wjj 20180720
		//this.hideSystemUI(glSurfaceView);

        return glSurfaceView;
    }

    @Override
    public void onPause()
    {
        super.onPause();
        if(mWakeLock != null)
        {
            mWakeLock.release();
            mWakeLock = null;
        }

        Adjust.onPause();
        TalkingDataGA.onPause(this);
    }
    @Override
    public void onResume()
    {
        super.onResume();
        PowerManager pm = (PowerManager)getSystemService(Context.POWER_SERVICE);
        mWakeLock = pm.newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK, "MyLock");
        mWakeLock.acquire();

        Adjust.onResume();
        TalkingDataGA.onResume(this);
    }
    @Override
    protected void onDestroy()
    {
        super.onDestroy();
        if(mWakeLock != null)
        {
            mWakeLock.release();
            mWakeLock = null;
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if(keyCode == KeyEvent.KEYCODE_BACK) {
            // 监控返回键
            exit();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
	
	private void exit() {
        AlertDialog.Builder builder=new AlertDialog.Builder(AppActivity.this);
        builder.setTitle("Exit");
        builder.setMessage("Quit the game?");
        builder.setPositiveButton("Yes",new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface arg0, int arg1) {
                finish();
                System.exit(0);
            }
        });
        builder.setNegativeButton("No", null);
        builder.show();
	}

    private boolean isNetworkConnected() {
            ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);  
            if (cm != null) {  
                NetworkInfo networkInfo = cm.getActiveNetworkInfo();  
            ArrayList networkTypes = new ArrayList();
            networkTypes.add(ConnectivityManager.TYPE_WIFI);
            try {
                networkTypes.add(ConnectivityManager.class.getDeclaredField("TYPE_ETHERNET").getInt(null));
            } catch (NoSuchFieldException nsfe) {
            }
            catch (IllegalAccessException iae) {
                throw new RuntimeException(iae);
            }
            if (networkInfo != null && networkTypes.contains(networkInfo.getType())) {
                    return true;  
                }  
            }  
            return false;  
        } 
     
    public String getHostIpAddress() {
        WifiManager wifiMgr = (WifiManager) getSystemService(WIFI_SERVICE);
        WifiInfo wifiInfo = wifiMgr.getConnectionInfo();
        int ip = wifiInfo.getIpAddress();
        return ((ip & 0xFF) + "." + ((ip >>>= 8) & 0xFF) + "." + ((ip >>>= 8) & 0xFF) + "." + ((ip >>>= 8) & 0xFF));
    }

    public static String getLocalIpAddress() {
        return hostIPAdress;
    }


    public String getAndroidMacID()
    {

        String str = null;

        WifiManager wifi = (WifiManager) getSystemService(Context.WIFI_SERVICE);
        WifiInfo info = wifi.getConnectionInfo();
        str = info.getMacAddress();

        if(str==null)
        {
            Log.e("获取android mac地址失败", "0000000");
        }
        Log.e("获取android mac地址 "+str, "00000000");

        return str;

    }

    public static String getLocalMacAddress(){
        String str = macAddress.replaceAll(":", "");
        return str;
    }

    public static String createUUID(){
        String uuid = UUID.randomUUID().toString().replaceAll("-", "");
        return uuid;
    }



    public static void adjustTrackEvent(final String strItemKey) {
        AdjustEvent event = new AdjustEvent(strItemKey);
        Adjust.trackEvent(event);
    }


    private static native boolean nativeIsLandScape();
    private static native boolean nativeIsDebug();
    
     public class FlurryUtil     {
        public void onStartSession(Context context){
            //FlurryAgent.setLogEvents(true);
            //FlurryAgent.onStartSession(context,"TFY62MZDJ3T3CXGQ9M5Q" );
        }

        public void onEndSession(Context context){
            //FlurryAgent.onEndSession(context);
        }

        public void onEvent(String eventID){
            Map<String, String> params = new HashMap<String, String>();
            //FlurryAgent.logEvent(eventID, params);
        }

        public void onEvent(String eventId, String paramValue) {
            HashMap<String, String> params = new HashMap<String, String>();
            params.put(eventId, paramValue);
            //FlurryAgent.logEvent(eventId, params);
        }

        public  void onEvent(String eventId, String paramKey, String paramValue) {
            Map<String, String> params = new HashMap<String, String>();
            params.put(paramKey, paramValue);
            //FlurryAgent.logEvent(eventId, params);
        }

        public  void onEventUseMap(String eventId, Map<String, String> map) {
            //FlurryAgent.logEvent(eventId, map);
        }

    }


    public static void onFlurryEvent(String eventId, String keys[] , String values[]){
        Map<String, String> params = new HashMap<String, String>();

        List<String> kk = new ArrayList<String>();

        for (String i : keys)
        {
            kk.add(i);
        }

        List<String> vv = new ArrayList<String>();

        for (String i : values)
        {
            vv.add(i);
        }

        int size = 0;
        if (kk.size() < vv.size()){
            size = vv.size();
        }else {
            size = kk.size();
        }

        for (int i = 0; i< size; i++){
            params.put(kk.get(i), vv.get(i));
        }

        //FlurryAgent.logEvent(eventId,params);
    }


    public static void onGAAddResourceEvent(String eventId, int eventNum, String event[]){
        Log.i("onGAAddResourceEvent", eventId);

        List<String> events = new ArrayList<String>();

        for (String i : event)
        {
            events.add(i);
        }

        List<String> ee = new ArrayList<String>();
        for (int i = 0; i < 2; i++) {
            if (i > events.size()-1){
                ee.add("");
            }else{
                ee.add(events.get(i));
            }
        }

        // GameAnalytics.addResourceEventWithFlowType(GAResourceFlowType.Source, eventId, eventNum, ee.get(0), ee.get(1));
    }

    public static void onGAAddProgressionEvent(String eventId, String event[]){

        Log.i("onGAAddProgressionEvent", eventId);
        List<String> events = new ArrayList<String>();
        for (String i : event)
        {
            events.add(i);
        }

        List<String> ee = new ArrayList<String>();
        for (int i = 0; i < 2; i++) {
            if (i > events.size()-1){
                ee.add("");
            }else{
                ee.add(events.get(i));
            }
        }

		/*
        Log.i("onGAAddProgressionEvent", eventId+" "+ee.get(0)+" "+ee.get(1));
        GameAnalytics.addProgressionEventWithProgressionStatus(GAProgressionStatus.Start, eventId, ee.get(0), ee.get(1));
        */

    }

    public static void onLoginEvent(String verson, String userID){
    	/*
        Log.i("onLoginEvent", verson+"  "+userID);

        GameAnalytics.configureBuild("android"+verson);
        GameAnalytics.configureUserId("80001" + userID);
        */
    }

	public static void RestartAPP(){
        Log.e("RestartAPP","BEGIN");
        Intent intent = new Intent(mContext, AppActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mContext.startActivity(intent);
        android.os.Process.killProcess(android.os.Process.myPid());
    }

    // quan mian ping  by wjj 20180720
     private void hideSystemUI(Cocos2dxGLSurfaceView glSurfaceView)
    {
        // Set the IMMERSIVE flag.
        // Set the content to appear under the system bars so that the content
        // doesn't resize when the system bars hide and show.
        glSurfaceView.setSystemUiVisibility(
                Cocos2dxGLSurfaceView.SYSTEM_UI_FLAG_LAYOUT_STABLE 
                | Cocos2dxGLSurfaceView.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | Cocos2dxGLSurfaceView.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | Cocos2dxGLSurfaceView.SYSTEM_UI_FLAG_HIDE_NAVIGATION // hide nav bar
                | Cocos2dxGLSurfaceView.SYSTEM_UI_FLAG_FULLSCREEN // hide status bar
                | Cocos2dxGLSurfaceView.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }
}
