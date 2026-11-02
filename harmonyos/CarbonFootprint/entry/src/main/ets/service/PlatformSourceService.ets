import { HttpClient } from '../network/HttpClient';
import { AppConfig } from '../common/AppConfig';
import { CalculationService } from './CalculationService';
import { SubType } from '../model/Models';

/** 平台返回的一条行为记录（已映射到本地行为字典） */
export interface PlatformRecord {
  type: string;
  subType: string;
  value: number;
  unit: string;
  factor: number;
  /** 行为发生时间戳（毫秒） */
  at: number;
  /** 来源说明，如「地铁行程」 */
  label: string;
}

export interface PlatformFetchResult {
  ok: boolean;
  records: PlatformRecord[];
  baseUrl: string;
  reason: string;
}

/**
 * 行为数据源适配器接口。
 * 当前只有 HTTP 实现（对接本地 mock 碳普惠服务）；
 * 将来接真实城市碳普惠平台，只需新增一个实现类，不改业务代码。
 */
export interface BehaviorSourceAdapter {
  readonly id: string;
  readonly name: string;
  fetch(): Promise<PlatformFetchResult>;
}

interface RemoteBehavior {
  type: string;
  subType: string;
  value: number;
  at: number;
  label: string;
}

interface RemoteBehaviorResp {
  code: number;
  data: RemoteBehavior[];
}

/** HTTP 适配器：从可配置的碳普惠服务拉取行为记录（赛题要求的「模拟接口」） */
export class HttpPlatformAdapter implements BehaviorSourceAdapter {
  readonly id: string = 'http';
  readonly name: string = '碳普惠平台';

  private static readonly EMULATOR_HOST: string = 'http://10.0.2.2:8080';
  private static readonly LOOPBACK_HOST: string = 'http://127.0.0.1:8080';

  /** 与 E3 相同的候选回退：配置地址 → 模拟器宿主别名 → 本机回环 */
  private candidates(configured: string): string[] {
    const raw: string[] = [configured.trim(), HttpPlatformAdapter.EMULATOR_HOST,
      HttpPlatformAdapter.LOOPBACK_HOST];
    const out: string[] = [];
    for (const u of raw) {
      if (u !== '' && out.indexOf(u) < 0) {
        out.push(u);
      }
    }
    return out;
  }

  async fetch(): Promise<PlatformFetchResult> {
    const configured = await AppConfig.getInclusiveBaseUrl();
    const list = this.candidates(configured);
    for (const base of list) {
      try {
        const resp = await HttpClient.getJson(base + '/api/behavior', {}, 2500);
        if (resp.code === 200) {
          const parsed = JSON.parse(resp.body) as RemoteBehaviorResp;
          if (parsed.data !== undefined && parsed.data.length > 0) {
            const out: PlatformRecord[] = [];
            for (const r of parsed.data) {
              const sub: SubType | null = CalculationService.findSub(r.type, r.subType);
              if (sub === null) {
                continue;
              }
              let v = r.value;
              if (!isFinite(v) || v <= 0) {
                continue;
              }
              if (v > sub.max) {
                v = sub.max;
              }
              const rec: PlatformRecord = {
                type: r.type,
                subType: r.subType,
                value: v,
                unit: sub.unit,
                factor: sub.factor,
                at: r.at,
                label: r.label
              };
              out.push(rec);
            }
            if (out.length > 0) {
              const ok: PlatformFetchResult = { ok: true, records: out, baseUrl: base, reason: '' };
              return ok;
            }
          }
        }
      } catch (e) {
        // 换下一个候选地址
      }
    }
    const fail: PlatformFetchResult = {
      ok: false, records: [], baseUrl: '',
      reason: '平台不可达。请先在电脑上启动 mock 服务（node mock/server.js 8080）'
    };
    return fail;
  }
}

/** 对外统一入口：目前只有 HTTP 适配器，将来可在此按配置切换实现 */
export class PlatformSourceService {
  private static adapter: BehaviorSourceAdapter = new HttpPlatformAdapter();

  static fetch(): Promise<PlatformFetchResult> {
    return PlatformSourceService.adapter.fetch();
  }
}
