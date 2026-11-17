package com.carbon.footprint;

import android.content.Context;
import android.content.res.Resources;
import android.util.Log;

import ohos.ace.adapter.capability.bridge.BridgeManager;
import ohos.ace.adapter.capability.bridge.BridgePlugin;

/**
 * 状态栏高度 Bridge：向 ArkTS 侧提供 Android 原生的真实状态栏高度（px）。
 *
 * 多机型适配要点：
 *  - 通过系统资源 status_bar_height 取值，该值由各厂商 ROM 按机型定义，
 *    普通屏 / 刘海屏 / 挖孔屏 / 折叠屏都能拿到正确值，避免硬编码。
 *  - 资源读取失败时按 density * 24dp 估算兜底，保证任何机型都有合理返回值。
 */
public class StatusBarBridgePlugin extends BridgePlugin {
    private static final String TAG = "StatusBarBridge";
    public static final String BRIDGE_NAME = "StatusBarBridge";
    private final Context mContext;

    public StatusBarBridgePlugin(Context context, BridgeManager manager) {
        super(context, BRIDGE_NAME, manager);
        this.mContext = context;
    }

    /**
     * JS 侧通过 callMethodSync("getStatusBarHeight") 调用此方法。
     * 返回状态栏高度，单位 px（ArkTS 侧再用 px2vp 转换）。
     */
    public int getStatusBarHeight() {
        // 方案一：系统资源（最通用，各厂商 ROM 已按机型适配）
        int height = getHeightFromResource();
        Log.i(TAG, "getStatusBarHeight resource = " + height);

        // 方案二：密度兜底 24dp（仅当资源读取失败时）
        if (height <= 0) {
            float density = mContext.getResources().getDisplayMetrics().density;
            height = Math.round(24 * density);
            Log.i(TAG, "getStatusBarHeight fallback density = " + density + " -> " + height);
        }
        return height;
    }

    /** 读取系统定义的 status_bar_height 资源（px） */
    private int getHeightFromResource() {
        try {
            Resources res = mContext.getResources();
            int resId = res.getIdentifier("status_bar_height", "dimen", "android");
            if (resId > 0) {
                return res.getDimensionPixelSize(resId);
            }
        } catch (Exception e) {
            Log.e(TAG, "getHeightFromResource error: " + e.getMessage());
        }
        return 0;
    }
}
