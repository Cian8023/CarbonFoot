import http from '@ohos.net.http';

export interface HttpResponse {
  code: number;
  body: string;
}

/**
 * HTTP 工具类：统一封装 GET/POST JSON 请求（超时、错误码）。
 */
export class HttpClient {
  static async postJson(url: string, body: string,
    extraHeaders: Record<string, string>, timeoutMs: number): Promise<HttpResponse> {
    const req = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: HttpClient.headerOf(extraHeaders),
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs
      };
      const resp = await req.request(url, options);
      const code = resp.responseCode;
      const text: string = HttpClient.resultToString(resp.result);
      return { code: code, body: text };
    } finally {
      req.destroy();
    }
  }

  static async getJson(url: string, extraHeaders: Record<string, string>,
    timeoutMs: number): Promise<HttpResponse> {
    const req = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: HttpClient.headerOf(extraHeaders),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs
      };
      const resp = await req.request(url, options);
      const code = resp.responseCode;
      const text: string = HttpClient.resultToString(resp.result);
      return { code: code, body: text };
    } finally {
      req.destroy();
    }
  }

  private static resultToString(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      const u8 = new Uint8Array(result);
      let s = '';
      for (let i = 0; i < u8.length; i++) {
        s += String.fromCharCode(u8[i]);
      }
      return s;
    }
    return JSON.stringify(result);
  }

  private static headerOf(extra: Record<string, string>): Record<string, string> {
    const header: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    const keys = Object.keys(extra);
    for (const k of keys) {
      header[k] = extra[k];
    }
    return header;
  }
}
