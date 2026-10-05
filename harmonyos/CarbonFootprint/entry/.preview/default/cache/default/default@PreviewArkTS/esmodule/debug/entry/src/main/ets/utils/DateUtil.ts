export class DateUtil {
    static readonly DAY_MS: number = 86400000;
    static pad2(n: number): string {
        return n < 10 ? '0' + n : '' + n;
    }
    static startOfDay(ts: number): number {
        const d = new Date(ts);
        d.setHours(0, 0, 0, 0);
        return d.getTime();
    }
    static startOfWeek(ts: number): number {
        const dayStart = DateUtil.startOfDay(ts);
        const dow = (new Date(dayStart).getDay() + 6) % 7; // 周一为一周开始
        return dayStart - dow * DateUtil.DAY_MS;
    }
    static startOfMonth(ts: number): number {
        const d = new Date(ts);
        d.setDate(1);
        d.setHours(0, 0, 0, 0);
        return d.getTime();
    }
    static startOfYear(ts: number): number {
        const d = new Date(ts);
        d.setMonth(0, 1);
        d.setHours(0, 0, 0, 0);
        return d.getTime();
    }
    /** MM-DD */
    static formatMD(ts: number): string {
        const d = new Date(ts);
        return DateUtil.pad2(d.getMonth() + 1) + '-' + DateUtil.pad2(d.getDate());
    }
    /** YYYY-MM-DD */
    static formatYMD(ts: number): string {
        const d = new Date(ts);
        return d.getFullYear() + '-' + DateUtil.pad2(d.getMonth() + 1) + '-' + DateUtil.pad2(d.getDate());
    }
    /** YYYY-MM */
    static formatYM(ts: number): string {
        const d = new Date(ts);
        return d.getFullYear() + '-' + DateUtil.pad2(d.getMonth() + 1);
    }
    /** YYYY 年 M 月 */
    static formatYearMonthCn(ts: number): string {
        const d = new Date(ts);
        return d.getFullYear() + '年' + (d.getMonth() + 1) + '月';
    }
    /** HH:mm */
    static formatHM(ts: number): string {
        const d = new Date(ts);
        return DateUtil.pad2(d.getHours()) + ':' + DateUtil.pad2(d.getMinutes());
    }
    /** MM-DD HH:mm */
    static formatMDHM(ts: number): string {
        return DateUtil.formatMD(ts) + ' ' + DateUtil.formatHM(ts);
    }
    /** YYYY-MM-DD HH:mm */
    static formatFull(ts: number): string {
        return DateUtil.formatYMD(ts) + ' ' + DateUtil.formatHM(ts);
    }
    /** 整数克 -> 千克字符串 */
    static gramsToKg(g: number): string {
        return (g / 1000).toFixed(2);
    }
}
