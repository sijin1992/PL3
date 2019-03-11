package com.utu.star;

import android.app.Application;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.util.Log;

import com.adjust.sdk.Adjust;
import com.adjust.sdk.AdjustAttribution;
import com.adjust.sdk.AdjustConfig;
import com.adjust.sdk.LogLevel;
import com.adjust.sdk.OnAttributionChangedListener;


public class GlobalApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        //adjust init
        String appToken = "8nkantaldqbk";
        String environment = null;
        boolean isDebug = this.isApkDebugable(this);
        if (isDebug) {
            environment = AdjustConfig.ENVIRONMENT_SANDBOX;
        }else{
            environment = AdjustConfig.ENVIRONMENT_PRODUCTION;
        }
        AdjustConfig config = new AdjustConfig(this, appToken, environment);
        // Change the log level.
        if (isDebug) {
            config.setLogLevel(LogLevel.VERBOSE);
        }else{
            config.setLogLevel(LogLevel.SUPRESS);
        }

        config.setOnAttributionChangedListener(new OnAttributionChangedListener() {
            @Override
            public void onAttributionChanged(AdjustAttribution attribution) {
            }
        });

        Adjust.onCreate(config);
    }

    public static boolean isApkDebugable(Context context) {
        try {
            ApplicationInfo info= context.getApplicationInfo();
            return (info.flags&ApplicationInfo.FLAG_DEBUGGABLE)!=0;
        } catch (Exception e) {

        }
        return false;
    }
}
