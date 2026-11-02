import fs from '@ohos.file.fs';
import util from '@ohos.util';
import image from '@ohos.multimedia.image';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { cameraPicker } from '@kit.CameraKit';
import camera from '@ohos.multimedia.camera';
import { AppInit } from '../common/AppInit';
import { AppConfig } from '../common/AppConfig';
import { HttpClient, HttpResponse } from '../network/HttpClient';
import { CalculationService } from './CalculationService';
import { BehaviorCategory, SubType } from '../model/Models';

export interface AiGuess {
  type: string;
  subType: string;
  value: number;
  unit: string;
}

/** 场景候选：模型给出的大类/子类型与置信度 */
export interface AiCandidate {
  type: string;
  subType: string;
  /** 置信度 0~1 */
  conf: number;
}

/** 票据提取结果：数值来自图片原文 */
export interface AiTicket {
  /** 展示名：地铁行程 / 公交行程 / 外卖订单 / 电费账单 / 水费账单 */
  label: string;
  type: string;
  subType: string;
  value: number;
  unit: string;
  /** 原文依据（里程、日期、金额等），展示给用户 */
  evidence: string;
  /** 票据上的发生时间；解析失败或异常时回落到当前时间 */
  at: number;
}

/**
 * 识别结果。
 * kind: ticket=票据提取 / scene=场景候选 / none=没看出低碳行为
 * 失败时 ok=false，只带回 reason，不编造结果。
 */
export interface AiResult {
  ok: boolean;
  kind: string;
  ticket: AiTicket | null;
  candidates: AiCandidate[];
  /** 失败分类：config / auth / network / image / server / model */
  failKind: string;
  reason: string;
}

/** 模型返回的原始 JSON 结构 */
interface ParsedAi {
  docType: string;
  km: number;
  kwh: number;
  waterL: number;
  count: number;
  date: string;
  evidence: string;
  candidates: AiCandidate[];
}

interface ChatChoiceMessage {
  content: string;
}
interface ChatChoice {
  message: ChatChoiceMessage;
}
interface ChatResponse {
  choices: ChatChoice[];
}

interface ChatImageUrl {
  url: string;
}
interface ChatContentPart {
  type: string;
  text?: string;
  image_url?: ChatImageUrl;
}
interface ChatMessage {
  role: string;
  content: ChatContentPart[];
}
interface ChatRequest {
  model: string;
  messages: ChatMessage[];
  /** 只要一段 JSON，600 足够，也省 token */
  max_tokens?: number;
  /** 低温输出更稳定，识别场景不需要发散 */
  temperature?: number;
  /** 仅 DeepSeek 官方端点开启，第三方兼容端点未必支持 */
  response_format?: ResponseFormat;
}

interface ResponseFormat {
  type: string;
}

/**
 * 端侧 AI 识别服务（创新拓展 2）：
 * 相册选图 → Base64 → 调用 OpenAI 兼容视觉接口 → 解析为行为字典 → 预填录入表单。
 * 未配置 API Key 或网络不可达时，进入「端侧特征识别」，保证路演可演示。
 */
export class AiRecognizeService {
  /** 打开系统相册选图，返回文件 uri */
  /**
   * 拉起系统相机拍摄（cameraPicker 安全 Picker，无需申请相机权限；
   * 模拟器使用内置虚拟相机画面，真机为真实拍摄）。
   */
  static async shootImage(): Promise<string> {
    const profile: cameraPicker.PickerProfile = {
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
    };
    const result: cameraPicker.PickerResult = await cameraPicker.pick(
      AppInit.getContext(), [cameraPicker.PickerMediaType.PHOTO], profile);
    if (result.resultCode !== 0 || result.resultUri === '') {
      throw new Error('未拍摄图片');
    }
    return result.resultUri;
  }

  /** 多选图片（批量识别用） */
  static async pickImages(max: number): Promise<string[]> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const opt = new photoAccessHelper.PhotoSelectOptions();
    opt.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    opt.maxSelectNumber = max;
    const result: photoAccessHelper.PhotoSelectResult = await picker.select(opt);
    if (result.photoUris.length === 0) {
      throw new Error('未选择图片');
    }
    return result.photoUris;
  }

  /**
   * 读取图片并压到长边 1600 的 JPEG，转 Base64。
   * 票据 OCR 需要看清小字，1024 偏低会把里程/度数糊掉；1600 在清晰度与体积间折中。
   */
  static async imageToBase64(uri: string): Promise<string> {
    const f = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    let raw: ArrayBuffer;
    try {
      const stat = fs.statSync(f.fd);
      raw = new ArrayBuffer(stat.size);
      fs.readSync(f.fd, raw);
    } finally {
      fs.closeSync(f.fd);
    }
    const source: image.ImageSource = image.createImageSource(raw);
    try {
      const info: image.ImageInfo = await source.getImageInfo();
      const longSide = Math.max(info.size.width, info.size.height);
      const scale = longSide > 1600 ? 1600 / longSide : 1;
      const pm: image.PixelMap = await source.createPixelMap({
        desiredSize: {
          width: Math.max(1, Math.round(info.size.width * scale)),
          height: Math.max(1, Math.round(info.size.height * scale))
        }
      });
      try {
        const packer: image.ImagePacker = image.createImagePacker();
        try {
          const jpeg = await packer.packing(pm, { format: 'image/jpeg', quality: 85 });
          return new util.Base64Helper().encodeToStringSync(new Uint8Array(jpeg));
        } finally {
          packer.release();
        }
      } finally {
        pm.release();
      }
    } finally {
      source.release();
    }
  }

  /** 用户取消标记：取消后不再把中止当成错误展示 */
  private static cancelled: boolean = false;

  /** 页面在开始识别前调用，清掉上一次的取消标记 */
  static begin(): void {
    AiRecognizeService.cancelled = false;
  }

  /** 页面调用：取消正在进行的识别（真正中止在途请求） */
  static cancel(): void {
    AiRecognizeService.cancelled = true;
    HttpClient.abort('ai');
  }

  /** 识别主流程：有 Key 走云端视觉模型；任何失败都不编造结果，只带回原因 */
  static async recognize(imageBase64: string): Promise<AiResult> {
    // 压缩阶段就点过取消的话，这里直接返回，不再发请求
    if (AiRecognizeService.cancelled) {
      return AiRecognizeService.fail('cancelled', '已取消识别');
    }
    const apiKey = await AppConfig.getAiApiKey();
    if (apiKey === '') {
      return AiRecognizeService.fail('config', '未配置 API Key，无法在线识别。请到「我的 > 设置 > 服务配置」填入 Key。');
    }
    const baseUrl = await AppConfig.getAiBaseUrl();
    const model = await AppConfig.getAiModel();

    const categories: BehaviorCategory[] = CalculationService.getCategories();
    const typeList: string[] = [];
    for (const c of categories) {
      for (const s of c.subTypes) {
        // 把单位与单次上限一并告诉模型，省得它返回 500 公里这类离谱数值
        typeList.push(`${c.name}/${s.name}(${s.unit}，上限${s.max})`);
      }
    }
    const prompt = '你是低碳行为识别助手。先判断图片类型，再输出结构化结果，只输出 JSON，不要解释：' +
      '{"docType":"metro|bus|takeout|electric|water|none","km":数字,"kwh":数字,"waterL":数字,' +
      '"count":数字,"date":"YYYY-MM-DD","evidence":"原文关键字段",' +
      '"candidates":[{"type":"大类","subType":"子类型","conf":0到1}]}。' +
      '规则：1) 行程/乘车记录截图 → docType=metro 或 bus，km 填里程（公里）；' +
      '2) 外卖/餐饮订单截图 → docType=takeout，count 填份数；' +
      '3) 电费账单 → docType=electric，kwh 填用电量（度）；' +
      '4) 水费账单 → docType=water，waterL 填用水量（升，1 吨=1000 升）；' +
      '5) 其他照片 → docType=none；' +
      '6) date 填票据上的日期，读不到就留空字符串；' +
      '7) 无论哪种情况都给出最多 3 个候选行为，按可能性降序，conf 为 0~1；' +
      '8) 完全无关时 candidates 返回空数组。可选行为（含单位与单次上限）：' +
      typeList.join('、');

    const textPart: ChatContentPart = { type: 'text', text: prompt };
    const imgUrl: ChatImageUrl = { url: 'data:image/jpeg;base64,' + imageBase64 };
    const imagePart: ChatContentPart = { type: 'image_url', image_url: imgUrl };
    const content: ChatContentPart[] = [textPart, imagePart];
    const message: ChatMessage = { role: 'user', content: content };
    const reqBody: ChatRequest = {
      model: model,
      messages: [message],
      max_tokens: 600,
      temperature: 0.1
    };
    // DeepSeek 支持 json_object 约束输出，能显著降低解析失败率；
    // 第三方兼容端点未必支持该字段，只在官方域名下开启，避免 400
    if (baseUrl.indexOf('api.deepseek.com') >= 0) {
      reqBody.response_format = { type: 'json_object' };
    }

    const headers: Record<string, string> = { 'Authorization': 'Bearer ' + apiKey };
    // 网络抖动或 5xx 时自动重试一次；用户取消则立即返回，不当成错误
    let resp: HttpResponse = { code: -1, body: '' };
    let netErr = '';
    let done = false;
    for (let attempt = 0; attempt < 2 && !done; attempt++) {
      try {
        const r = await HttpClient.postJson(baseUrl, JSON.stringify(reqBody), headers, 30000, 'ai');
        if (r.code >= 500 && attempt === 0) {
          continue;
        }
        resp = r;
        done = true;
      } catch (e) {
        if (AiRecognizeService.cancelled) {
          return AiRecognizeService.fail('cancelled', '已取消识别');
        }
        netErr = (e as Error).message;
      }
    }
    if (!done) {
      return AiRecognizeService.fail('network', '网络请求失败：' + netErr);
    }
    if (resp.code !== 200) {
      const detail = resp.body.length > 100 ? resp.body.substring(0, 100) : resp.body;
      return AiRecognizeService.fail(AiRecognizeService.failKindOf(resp.code),
        `接口返回 ${resp.code}：${AiRecognizeService.hintOf(resp.code)}。${detail}`);
    }
    let chat: ChatResponse;
    try {
      chat = JSON.parse(resp.body) as ChatResponse;
    } catch (e) {
      return AiRecognizeService.fail('model', '接口返回内容无法解析为 JSON');
    }
    if (chat.choices === undefined || chat.choices.length === 0) {
      return AiRecognizeService.fail('model', '接口未返回识别结果');
    }
    const content0 = chat.choices[0].message.content;
    const parsed = AiRecognizeService.parseContent(content0);
    if (parsed === null) {
      return AiRecognizeService.fail('model', '模型输出不是合法 JSON：' + content0.substring(0, 60));
    }
    return AiRecognizeService.buildResult(parsed);
  }

  /** 状态码 → 失败分类，页面据此给不同出路 */
  private static failKindOf(code: number): string {
    if (code === 401 || code === 403) {
      return 'auth';
    }
    if (code === 413) {
      return 'image';
    }
    return 'server';
  }

  private static fail(kind: string, reason: string): AiResult {
    const r: AiResult = {
      ok: false, kind: 'none', ticket: null, candidates: [], failKind: kind, reason: reason
    };
    return r;
  }

  /** 把模型输出组装成「票据结果 / 场景候选 / 无结果」 */
  private static buildResult(p: ParsedAi): AiResult {
    const dt = (p.docType === undefined || p.docType === null)
      ? 'none' : ('' + p.docType).trim().toLowerCase();
    if (dt === 'metro' || dt === 'bus' || dt === 'takeout' ||
      dt === 'electric' || dt === 'water') {
      const t = AiRecognizeService.ticketOf(p, dt);
      if (t !== null) {
        const r: AiResult = {
          ok: true, kind: 'ticket', ticket: t, candidates: [], failKind: '', reason: ''
        };
        return r;
      }
    }
    const cands = AiRecognizeService.sanitizeCandidates(p.candidates);
    if (cands.length === 0) {
      const none: AiResult = {
        ok: true, kind: 'none', ticket: null, candidates: [], failKind: '', reason: ''
      };
      return none;
    }
    const scene: AiResult = {
      ok: true, kind: 'scene', ticket: null, candidates: cands, failKind: '', reason: ''
    };
    return scene;
  }

  /** 票据字段 → 行为字典（超上限截断，缺失按 1 次估算，并把依据写进 evidence） */
  private static ticketOf(p: ParsedAi, dt: string): AiTicket | null {
    let type = '';
    let sub = '';
    let label = '';
    let raw = 0;
    if (dt === 'metro') {
      type = '出行'; sub = '地铁'; label = '地铁行程'; raw = Number(p.km);
    } else if (dt === 'bus') {
      type = '出行'; sub = '公交'; label = '公交行程'; raw = Number(p.km);
    } else if (dt === 'electric') {
      type = '节水节电'; sub = '节电'; label = '电费账单'; raw = Number(p.kwh);
    } else if (dt === 'water') {
      type = '节水节电'; sub = '节水'; label = '水费账单'; raw = Number(p.waterL);
    } else {
      // 一份外卖订单按 1 次计（订单里几份菜仍是一顿饭），份数只写进依据
      type = '光盘行动'; sub = '午餐'; label = '外卖订单'; raw = 1;
    }
    const s: SubType | null = CalculationService.findSub(type, sub);
    if (s === null) {
      return null;
    }
    // 模型可能把数字写成字符串，统一 Number() 后再判有效
    let v = isFinite(raw) && raw > 0 ? raw : 0;
    const parts: string[] = [];
    if (p.evidence !== undefined && p.evidence !== null && p.evidence !== '') {
      parts.push('' + p.evidence);
    }
    if (p.date !== undefined && p.date !== null && p.date !== '') {
      parts.push('' + p.date);
    }
    if (dt === 'takeout') {
      const n = Number(p.count);
      if (isFinite(n) && n > 1) {
        parts.push('订单 ' + n + ' 份，按 1 次计');
      }
    }
    if (v <= 0) {
      v = 1;
      parts.push('未读到具体数值，按 1 次估算');
    }
    if (v > s.max) {
      v = s.max;
      parts.push('已按单次上限 ' + s.max + s.unit + ' 截断');
    }
    const t: AiTicket = {
      label: label,
      type: type,
      subType: sub,
      value: v,
      unit: s.unit,
      evidence: parts.join(' · '),
      at: AiRecognizeService.parseDateTs(p.date)
    };
    return t;
  }

  /** 票据日期 → 时间戳；非法、未来或超过一年以前一律回落到当前时间 */
  private static parseDateTs(date: string): number {
    const now = Date.now();
    if (date === undefined || date === null || date === '') {
      return now;
    }
    const parts: string[] = ('' + date).trim().split('-');
    if (parts.length !== 3) {
      return now;
    }
    const y = Number(parts[0]);
    const m = Number(parts[1]);
    const d = Number(parts[2]);
    if (!isFinite(y) || !isFinite(m) || !isFinite(d) ||
      y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) {
      return now;
    }
    const ts = new Date(y, m - 1, d, 12, 0, 0).getTime();
    if (!isFinite(ts)) {
      return now;
    }
    // 不接受未来时间，也不接受一年以前（防止模型把年份读错）
    if (ts > now + 86400000 || ts < now - 365 * 86400000) {
      return now;
    }
    return ts;
  }

  /** 候选过滤：剔除字典外项、归一化置信度、按置信度降序后再取前 3 */
  private static sanitizeCandidates(raw: AiCandidate[]): AiCandidate[] {
    const all: AiCandidate[] = [];
    if (raw === undefined || raw === null) {
      return all;
    }
    for (const c of raw) {
      if (c === null || c === undefined) {
        continue;
      }
      const s: SubType | null = CalculationService.findSub(c.type, c.subType);
      if (s === null) {
        continue;
      }
      let conf = Number(c.conf);
      if (!isFinite(conf)) {
        conf = 0;
      }
      if (conf > 1) {
        conf = conf / 100;
      }
      if (conf < 0) {
        conf = 0;
      }
      const item: AiCandidate = { type: c.type, subType: c.subType, conf: conf };
      all.push(item);
      if (all.length >= 10) {
        break;
      }
    }
    // 先排序再截断，避免模型乱序时丢掉真正的第一名
    all.sort((a: AiCandidate, b: AiCandidate) => b.conf - a.conf);
    const out: AiCandidate[] = [];
    for (const it of all) {
      out.push(it);
      if (out.length >= 3) {
        break;
      }
    }
    return out;
  }

  /** 场景候选的默认数值（用户可改） */
  static suggestValue(type: string, subType: string): number {
    if (type === '出行') {
      if (subType === '步行') {
        return 2;
      }
      if (subType === '骑行') {
        return 5;
      }
      if (subType === '公交') {
        return 10;
      }
      if (subType === '地铁') {
        return 15;
      }
      return 10;
    }
    if (type === '节水节电') {
      return 2;
    }
    return 1;
  }

  /** 常见状态码的排查提示，直接给到界面上，省得用户对着 400 猜 */
  private static hintOf(code: number): string {
    if (code === 401 || code === 403) {
      return 'API Key 无效或无权限';
    }
    if (code === 404) {
      return '接口地址或模型名不存在';
    }
    if (code === 400) {
      return '请求被拒，常见原因是模型不支持图片输入';
    }
    if (code === 413) {
      return '请求体过大，图片未能压缩';
    }
    if (code === 429) {
      return '调用频率或额度超限';
    }
    if (code >= 500) {
      return '服务端异常';
    }
    return '请检查接口地址、模型名与密钥';
  }

  /** 解析模型输出（兼容 ```json 包裹） */
  private static parseContent(content: string): ParsedAi | null {
    const text = content.trim();
    const start2 = text.indexOf('{');
    const end2 = text.lastIndexOf('}');
    if (start2 < 0 || end2 <= start2) {
      return null;
    }
    try {
      const obj = JSON.parse(text.substring(start2, end2 + 1)) as ParsedAi;
      if (obj === null || obj === undefined) {
        return null;
      }
      if (obj.docType === undefined || obj.docType === null) {
        obj.docType = 'none';
      }
      if (obj.candidates === undefined || obj.candidates === null) {
        obj.candidates = [];
      }
      return obj;
    } catch (e) {
      return null;
    }
  }
}
