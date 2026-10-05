import UIAbility from "@ohos:app.ability.UIAbility";
import type AbilityConstant from "@ohos:app.ability.AbilityConstant";
import type Want from "@ohos:app.ability.Want";
import type window from "@ohos:window";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        AppInit.bootstrap(this.context);
    }
    onDestroy(): void {
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code !== 0) {
                console.error('loadContent failed: ' + JSON.stringify(err));
            }
        });
    }
    onWindowStageDestroy(): void {
    }
    onForeground(): void {
    }
    onBackground(): void {
    }
}
