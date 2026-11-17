package com.carbon.footprint;

import android.os.Bundle;
import android.util.Log;

import ohos.stage.ability.adapter.StageActivity;


/**
 * Example ace activity class, which will load ArkUI-X ability instance.
 * StageActivity is provided by ArkUI-X
 * @see <a href=
 * "https://gitee.com/arkui-crossplatform/doc/blob/master/contribute/tutorial/how-to-build-Android-app.md">
 * to build android library</a>
 */
public class MainActivity extends StageActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.e("HiHelloWorld", "MainActivity");
        setInstanceName("com.carbon.footprint:entry:EntryAbility:");
        super.onCreate(savedInstanceState);
        // 注册状态栏高度 Bridge，供 ArkTS 侧获取各机型真实的 status_bar_height。
        try {
            StatusBarBridgePlugin plugin = new StatusBarBridgePlugin(this, getBridgeManager());
            boolean ok = getBridgeManager().registerBridgePlugin(StatusBarBridgePlugin.BRIDGE_NAME, plugin);
            Log.i("StatusBarBridge", "register result = " + ok);
        } catch (Throwable t) {
            Log.e("StatusBarBridge", "register failed: " + t.getMessage());
        }
    }
}
