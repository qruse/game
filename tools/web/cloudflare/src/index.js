// 웹 빌드 배포용 Worker.
// Cloudflare 정적 파일은 한 개 25 MiB 까지라서, 큰 파일(index.wasm, index.pck)은 gzip 으로 줄여 R2 버킷(project-d20-web)에 <이름>.gz 로 올린다.
// 정적 파일에 없는 요청만 이 Worker 로 온다: R2 에서 <이름>.gz 를 찾아 "gzip 으로 압축된 원본"이라고 알려 주며 그대로 내려보낸다.
// 올리기: tools/web/deploy_web.ps1

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
    // Cloudflare 가 압축을 풀어 보내면 ETag 가 W/"..." 로 바뀌어 돌아오므로 따옴표와 W/ 를 떼고 비교한다
    const inm = (request.headers.get("If-None-Match") || "").replace(/^W\//, "").replace(/"/g, "").trim();
    const obj = await env.WEB.get(url.pathname.slice(1) + ".gz", inm ? { onlyIf: { etagDoesNotMatch: inm } } : {});
    if (obj === null) {
      return env.ASSETS.fetch(request);
    }
    const headers = new Headers();
    headers.set("ETag", obj.httpEtag);
    headers.set("Content-Encoding", "gzip");
    headers.set("Content-Type", contentType(url.pathname));
    // 배포하면 같은 이름이 바뀌므로 매번 ETag 로 확인한다 (안 바뀌었으면 304)
    headers.set("Cache-Control", "public, max-age=0, must-revalidate");
    if (!("body" in obj)) {
      return new Response(null, { status: 304, headers });
    }
    headers.set("Content-Length", String(obj.size));
    return new Response(request.method === "HEAD" ? null : obj.body, {
      status: 200,
      headers,
      encodeBody: "manual",
    });
  },
};
