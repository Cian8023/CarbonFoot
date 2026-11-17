import { describe, it, expect } from '@ohos/hypium';

/**
 * ohosTest 入口。
 *
 * ace 的构建脚本会固定编译 ohosTest target（用于跨平台产物的插桩校验），
 * 即使用户没有写测试也会去解析这个入口，所以必须存在。
 * 这里只放一个最小用例，保证编译链路完整。
 */
export default function testsuite() {
  describe('CarbonFootprintSmoke', () => {
    it('placeholder_should_pass', 0, () => {
      expect(1).assertEqual(1);
    });
  });
}