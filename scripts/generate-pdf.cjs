const { createReadStream } = require("node:fs");
const { spawn } = require("node:child_process");
const { once } = require("node:events");
const { mkdir, mkdtemp, readdir, rm, stat, writeFile } = require("node:fs/promises");
const { createServer } = require("node:http");
const { tmpdir } = require("node:os");
const { dirname, extname, join, resolve, sep } = require("node:path");

const siteDirectory = resolve(process.env.SITE_DIRECTORY || "docs");
const outputPath = resolve(
  process.env.PDF_OUTPUT || "output/pdf/easydread-epk.pdf",
);
const pagePath = process.env.PDF_PAGE || "/epk/";
const chromiumShutdownTimeoutMs = 5_000;

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".gif": "image/gif",
  ".html": "text/html; charset=utf-8",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".js": "text/javascript; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ttf": "font/ttf",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".xml": "application/xml; charset=utf-8",
};

function serveSite() {
  const server = createServer(async (request, response) => {
    try {
      const url = new URL(request.url, "http://127.0.0.1");
      let requestedPath = decodeURIComponent(url.pathname);
      if (requestedPath.endsWith("/")) requestedPath += "index.html";

      const filePath = resolve(siteDirectory, `.${requestedPath}`);
      if (!filePath.startsWith(`${siteDirectory}${sep}`)) {
        response.writeHead(403).end("Forbidden");
        return;
      }

      const file = await stat(filePath);
      if (!file.isFile()) throw new Error("Not a file");

      response.writeHead(200, {
        "Content-Length": file.size,
        "Content-Type": contentTypes[extname(filePath)] || "application/octet-stream",
      });
      createReadStream(filePath).pipe(response);
    } catch {
      response.writeHead(404).end("Not found");
    }
  });

  return new Promise((accept, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => accept(server));
  });
}

async function findChromiumExecutable() {
  if (process.env.CHROMIUM_EXECUTABLE) {
    return process.env.CHROMIUM_EXECUTABLE;
  }

  const browserRoot = "/ms-playwright";
  const directories = await readdir(browserRoot, { withFileTypes: true });
  const chromiumDirectory = directories.find(
    (entry) => entry.isDirectory() && entry.name.startsWith("chromium-"),
  );

  if (!chromiumDirectory) {
    throw new Error(`No Chromium installation found under ${browserRoot}`);
  }

  return join(
    browserRoot,
    chromiumDirectory.name,
    "chrome-linux",
    "chrome",
  );
}

async function launchChromium(chromiumExecutable, profileDirectory) {
  const chromium = spawn(chromiumExecutable, [
    "--headless",
    "--no-sandbox",
    "--disable-gpu",
    "--hide-scrollbars",
    "--remote-debugging-port=0",
    `--user-data-dir=${profileDirectory}`,
    "about:blank",
  ], {
    stdio: ["ignore", "ignore", "pipe"],
  });

  const webSocketUrl = await new Promise((accept, reject) => {
    let diagnostics = "";
    const timeout = setTimeout(() => {
      reject(new Error(`Chromium did not open a debugging port:\n${diagnostics}`));
    }, 10_000);

    chromium.stderr.on("data", (chunk) => {
      diagnostics += chunk;
      const match = diagnostics.match(/DevTools listening on (ws:\/\/\S+)/);
      if (match) {
        clearTimeout(timeout);
        accept(match[1]);
      }
    });
    chromium.once("error", (error) => {
      clearTimeout(timeout);
      reject(error);
    });
    chromium.once("exit", (code, signal) => {
      clearTimeout(timeout);
      reject(new Error(
        `Chromium stopped before PDF generation with ${
          signal ? `signal ${signal}` : `exit code ${code}`
        }:\n${diagnostics}`,
      ));
    });
  });

  return { chromium, webSocketUrl };
}

async function waitForExit(childProcess, timeoutMs) {
  if (childProcess.exitCode !== null || childProcess.signalCode !== null) return true;

  let timeoutId;
  const exit = once(childProcess, "exit").then(() => true);
  const timeout = new Promise((accept) => {
    timeoutId = setTimeout(() => accept(false), timeoutMs);
  });

  const didExit = await Promise.race([exit, timeout]);
  clearTimeout(timeoutId);
  return didExit;
}

async function stopChromium(chromium) {
  if (chromium.exitCode !== null || chromium.signalCode !== null) return;

  chromium.kill("SIGTERM");
  if (await waitForExit(chromium, chromiumShutdownTimeoutMs)) return;

  chromium.kill("SIGKILL");
  await waitForExit(chromium, chromiumShutdownTimeoutMs);
}

class DevToolsConnection {
  constructor(webSocket) {
    this.webSocket = webSocket;
    this.nextId = 1;
    this.pendingCommands = new Map();
    this.eventWaiters = [];

    webSocket.addEventListener("message", ({ data }) => {
      const message = JSON.parse(data.toString());
      if (message.id) {
        const pending = this.pendingCommands.get(message.id);
        if (!pending) return;
        this.pendingCommands.delete(message.id);
        if (message.error) pending.reject(new Error(message.error.message));
        else pending.accept(message.result);
        return;
      }

      const waiterIndex = this.eventWaiters.findIndex(
        (waiter) =>
          waiter.method === message.method &&
          waiter.sessionId === message.sessionId,
      );
      if (waiterIndex !== -1) {
        const [waiter] = this.eventWaiters.splice(waiterIndex, 1);
        waiter.accept(message.params);
      }
    });
  }

  send(method, params = {}, sessionId) {
    const id = this.nextId++;
    return new Promise((accept, reject) => {
      this.pendingCommands.set(id, { accept, reject });
      this.webSocket.send(JSON.stringify({ id, method, params, sessionId }));
    });
  }

  waitForEvent(method, sessionId) {
    return new Promise((accept) => {
      this.eventWaiters.push({ accept, method, sessionId });
    });
  }
}

async function connectToDevTools(webSocketUrl) {
  const webSocket = new WebSocket(webSocketUrl);
  await new Promise((accept, reject) => {
    webSocket.addEventListener("open", accept, { once: true });
    webSocket.addEventListener("error", reject, { once: true });
  });
  return new DevToolsConnection(webSocket);
}

async function printToPdf(connection, url) {
  const { targetId } = await connection.send("Target.createTarget", {
    url: "about:blank",
  });
  const { sessionId } = await connection.send("Target.attachToTarget", {
    flatten: true,
    targetId,
  });
  await connection.send("Page.enable", {}, sessionId);

  const loaded = connection.waitForEvent("Page.loadEventFired", sessionId);
  await connection.send("Page.navigate", { url }, sessionId);
  await loaded;
  await connection.send(
    "Runtime.evaluate",
    {
      awaitPromise: true,
      expression: "document.fonts.ready.then(() => true)",
      returnByValue: true,
    },
    sessionId,
  );

  const { data } = await connection.send(
    "Page.printToPDF",
    {
      displayHeaderFooter: false,
      generateDocumentOutline: true,
      generateTaggedPDF: true,
      preferCSSPageSize: true,
      printBackground: true,
    },
    sessionId,
  );
  await writeFile(outputPath, Buffer.from(data, "base64"));
}

async function main() {
  await mkdir(dirname(outputPath), { recursive: true });

  const server = await serveSite();
  const address = server.address();
  const profileDirectory = await mkdtemp(join(tmpdir(), "easydread-chromium-"));
  let launchedBrowser;
  let connection;

  try {
    const url = `http://127.0.0.1:${address.port}${pagePath}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Page request failed: ${response.status} ${response.statusText}`);
    }
    await response.body.cancel();

    const chromiumExecutable = await findChromiumExecutable();
    launchedBrowser = await launchChromium(chromiumExecutable, profileDirectory);
    connection = await connectToDevTools(launchedBrowser.webSocketUrl);
    await printToPdf(connection, url);

    const output = await stat(outputPath);
    if (!output.isFile() || output.size === 0) {
      throw new Error(`Chromium did not create a usable PDF at ${outputPath}`);
    }

    console.log(`Generated ${outputPath} from ${url}`);
  } finally {
    if (connection) connection.webSocket.close();
    if (launchedBrowser) await stopChromium(launchedBrowser.chromium);
    await rm(profileDirectory, {
      force: true,
      maxRetries: 10,
      recursive: true,
      retryDelay: 100,
    });
    await new Promise((accept, reject) => {
      server.close((error) => (error ? reject(error) : accept()));
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
