import fs from '@ohos.file.fs';
import util from '@ohos.util';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { cameraPicker } from '@kit.CameraKit';
import camera from '@ohos.multimedia.camera';
import { AppInit } from '../common/AppInit';
import { AppConfig } from '../common/AppConfig';
import { HttpClient } from '../network/HttpClient';
import { CalculationService } from './CalculationService';
import { BehaviorCategory, SubType } from '../model/Models';

export interface AiGuess {
  type: string;
  subType: string;
  value: number;
  unit: string;
  demo: boolean;
  raw: string;
}

interface ParsedGuess {
  type: string;
  subType: string;
  value: number;
}

interface DemoCandidate {
  type: string;
  subType: string;
  value: number;
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
}

/**
 * 端侧 AI 识别服务（创新拓展 2）：
 * 相册选图 → Base64 → 调用 OpenAI 兼容视觉接口 → 解析为行为字典 → 预填录入表单。
 * 未配置 API Key 或网络不可达时，进入「离线演示识别」，保证路演可演示。
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

  static async pickImage(): Promise<string> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const opt = new photoAccessHelper.PhotoSelectOptions();
    opt.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    opt.maxSelectNumber = 1;
    const result: photoAccessHelper.PhotoSelectResult = await picker.select(opt);
    if (result.photoUris.length === 0) {
      throw new Error('未选择图片');
    }
    return result.photoUris[0];
  }

  /** 读取图片文件并转 Base64 */
  static async imageToBase64(uri: string): Promise<string> {
    const f = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      const stat = fs.statSync(f.fd);
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(f.fd, buf);
      return new util.Base64Helper().encodeToStringSync(new Uint8Array(buf));
    } finally {
      fs.closeSync(f.fd);
    }
  }

  /** 识别主流程：返回最可能的行为 guessed */
  static async recognize(imageBase64: string): Promise<AiGuess> {
    const apiKey = await AppConfig.getAiApiKey();
    if (apiKey === '') {
      return AiRecognizeService.demoGuess('未配置 API Key，使用离线演示识别');
    }
    const baseUrl = await AppConfig.getAiBaseUrl();
    const model = await AppConfig.getAiModel();

    const categories: BehaviorCategory[] = CalculationService.getCategories();
    const typeList: string[] = [];
    for (const c of categories) {
      for (const s of c.subTypes) {
        typeList.push(`${c.name}/${s.name}(${s.unit})`);
      }
    }
    const prompt = '你是低碳行为识别助手。判断图片中展示的低碳行为，从以下列表中选择最匹配的一项，' +
      '并估计数值。只输出 JSON：{"type":"大类","subType":"子类型","value":数字}。可选列表：' +
      typeList.join('、');

    const textPart: ChatContentPart = { type: 'text', text: prompt };
    const imgUrl: ChatImageUrl = { url: 'data:image/jpeg;base64,' + imageBase64 };
    const imagePart: ChatContentPart = { type: 'image_url', image_url: imgUrl };
    const content: ChatContentPart[] = [textPart, imagePart];
    const message: ChatMessage = { role: 'user', content: content };
    const reqBody: ChatRequest = { model: model, messages: [message] };

    const headers: Record<string, string> = { 'Authorization': 'Bearer ' + apiKey };
    const resp = await HttpClient.postJson(baseUrl, JSON.stringify(reqBody), headers, 30000);
    if (resp.code !== 200) {
      return AiRecognizeService.demoGuess('接口返回 ' + resp.code + '，使用离线演示识别');
    }
    const chat = JSON.parse(resp.body) as ChatResponse;
    if (chat.choices.length === 0) {
      return AiRecognizeService.demoGuess('无识别结果，使用离线演示识别');
    }
    const content0 = chat.choices[0].message.content;
    const guess = AiRecognizeService.parseContent(content0);
    if (guess === null) {
      return AiRecognizeService.demoGuess('结果解析失败，使用离线演示识别');
    }
    const sub = CalculationService.findSub(guess.type, guess.subType);
    if (sub === null) {
      return AiRecognizeService.demoGuess('结果不在行为字典中，使用离线演示识别');
    }
    const ok: AiGuess = {
      type: guess.type,
      subType: guess.subType,
      value: guess.value,
      unit: sub.unit,
      demo: false,
      raw: content0
    };
    return ok;
  }

  /** 解析模型输出（兼容 ```json 包裹） */
  private static parseContent(content: string): ParsedGuess | null {
    let text = content.trim();
    const start2 = text.indexOf('{');
    const end2 = text.lastIndexOf('}');
    if (start2 < 0 || end2 <= start2) {
      return null;
    }
    try {
      const obj = JSON.parse(text.substring(start2, end2 + 1)) as ParsedGuess;
      if (obj.type === undefined || obj.subType === undefined || !isFinite(obj.value)) {
        return null;
      }
      return obj;
    } catch (e) {
      return null;
    }
  }

  /** 离线演示识别：按内置候选轮换返回（无网络也能演示完整链路） */
  private static demoCandidates: DemoCandidate[] = [
    { type: '出行', subType: '骑行', value: 5 },
    { type: '光盘行动', subType: '午餐', value: 1 },
    { type: '旧物回收', subType: '纸类', value: 2 },
    { type: '节水节电', subType: '节电', value: 3 }
  ];
  private static demoIndex: number = 0;

  private static demoGuess(reason: string): AiGuess {
    const c = AiRecognizeService.demoCandidates[AiRecognizeService.demoIndex %
      AiRecognizeService.demoCandidates.length];
    AiRecognizeService.demoIndex++;
    const sub: SubType | null = CalculationService.findSub(c.type, c.subType);
    const g: AiGuess = {
      type: c.type,
      subType: c.subType,
      value: c.value,
      unit: sub !== null ? sub.unit : '',
      demo: true,
      raw: reason
    };
    return g;
  }
}
