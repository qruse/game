// 웹 빌드 배포용 Worker.
// Cloudflare 정적 파일은 한 개 25 MiB 까지라서, 큰 파일(index.wasm, index.pck)은 gzip 으로 미리 줄여 *.gz 로 올린다.
// 브라우저가 원래 이름으로 요청하면 *.gz 를 찾아 "gzip 으로 압축된 원본"이라고 알려 주며 그대로 내려보낸다.

const TYPES = {
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".js": "application/javascript",
};

function contentType(path) {
  for (const [ext, t] of Object.entries(TYPES)) {
    if (path.endsWith(ext)) return t;
  }
  return "application/octet-stream";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const gzUrl = new URL(url.pathname + ".gz", url);
    const gz = await env.ASSETS.fetch(new Request(gzUrl, { method: "GET" }));
    if (!gz.ok) {
      return env.ASSETS.fetch(request);
    }
    const headers = new Headers(gz.headers);
    headers.set("Content-Encoding", "gzip");
    headers.set("Content-Type", contentType(url.pathname));
    headers.set("Cache-Control", "public, max-age=3600");
    headers.delete("Content-Length");
    return new Response(request.method === "HEAD" ? null : gz.body, {
      status: 200,
      headers,
      encodeBody: "manual",
    });
  },
};
