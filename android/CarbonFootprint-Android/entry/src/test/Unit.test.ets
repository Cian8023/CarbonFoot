/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import { describe, it, expect } from '@ohos/hypium';
import { DateUtil } from '../main/ets/utils/DateUtil';
import { CalculationService } from '../main/ets/service/CalculationService';

/**
 * 纯逻辑单元测试：只覆盖不依赖数据库/上下文的函数。
 * 依赖 DB、preferences、网络的服务用「测试执行报告」里的手工用例覆盖。
 */
export default function unitTest() {
  describe('DateUtil', () => {
    it('startOfDay 归零时分秒', 0, () => {
      const ts = new Date(2026, 10, 2, 15, 30, 45).getTime();
      const s = DateUtil.startOfDay(ts);
      const d = new Date(s);
      expect(d.getHours()).assertEqual(0);
      expect(d.getMinutes()).assertEqual(0);
      expect(d.getSeconds()).assertEqual(0);
      expect(d.getDate()).assertEqual(2);
    });

    it('startOfWeek 回到周一零点', 0, () => {
      // 2026-11-02 是周一
      const ts = new Date(2026, 10, 2, 15, 0, 0).getTime();
      const s = DateUtil.startOfWeek(ts);
      const d = new Date(s);
      expect(d.getDay()).assertEqual(1);
      expect(d.getDate()).assertEqual(2);
      expect(d.getHours()).assertEqual(0);
    });

    it('startOfMonth / startOfYear 边界正确', 0, () => {
      const ts = new Date(2026, 10, 2, 15, 0, 0).getTime();
      const m = new Date(DateUtil.startOfMonth(ts));
      expect(m.getMonth()).assertEqual(10);
      expect(m.getDate()).assertEqual(1);
      const y = new Date(DateUtil.startOfYear(ts));
      expect(y.getMonth()).assertEqual(0);
      expect(y.getDate()).assertEqual(1);
    });

    it('gramsToKg 保留两位小数', 0, () => {
      expect(DateUtil.gramsToKg(0)).assertEqual('0.00');
      expect(DateUtil.gramsToKg(1500)).assertEqual('1.50');
      expect(DateUtil.gramsToKg(3444)).assertEqual('3.44');
    });

    it('formatYMD / formatYM 补零', 0, () => {
      const ts = new Date(2026, 0, 5, 9, 0, 0).getTime();
      expect(DateUtil.formatYMD(ts)).assertEqual('2026-01-05');
      expect(DateUtil.formatYM(ts)).assertEqual('2026-01');
    });
  });

  describe('CalculationService.valueToPoints', () => {
    it('0 或负数返回 0', 0, () => {
      expect(CalculationService.valueToPoints(0)).assertEqual(0);
      expect(CalculationService.valueToPoints(-100)).assertEqual(0);
    });

    it('正数至少给基础分', 0, () => {
      const p = CalculationService.valueToPoints(100);
      expect(p >= 1).assertTrue();
    });

    it('减排越多积分越多（单调不减）', 0, () => {
      const a = CalculationService.valueToPoints(500);
      const b = CalculationService.valueToPoints(5000);
      expect(b >= a).assertTrue();
    });
  });
}
