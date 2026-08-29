// Node.js 18+ required (native fetch)

const BASE_URL   = process.env.AICORE_BASE_URL;
const TOKEN      = process.env.AICORE_TOKEN;
const DEPLOY_ID  = process.env.AICORE_DEPLOYMENT_ID;
const RG         = process.env.AICORE_RG;

const QUESTIONS = [
  "What is SAP BTP and what does it offer?",
  "How does GenAI Hub differ from calling OpenAI directly?",
  "What SAP services are available for building AI-powered apps?",
];

class SAPAIClient {
  constructor({ baseUrl, token, deploymentId, resourceGroup }) {
    this.baseUrl   = baseUrl;
    this.deployId  = deploymentId;
    this.headers   = {
      "Authorization":    `Bearer ${token}`,
      "Content-Type":     "application/json",
      "AI-Resource-Group": resourceGroup,
    };
  }

  get endpoint() {
    return `${this.baseUrl}/inference/deployments/${this.deployId}/chat/completions`;
  }

  /** Standard (non-streaming) chat completion */
  async chat(messages) {
    const res = await fetch(this.endpoint, {
      method:  "POST",
      headers: this.headers,
      body:    JSON.stringify({ messages, max_tokens: 300 }),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`HTTP ${res.status}: ${err}`);
    }
    const data = await res.json();
    return data.choices[0].message.content.trim();
  }

  /** Streaming chat completion via SSE */
  async stream(messages) {
    const res = await fetch(this.endpoint, {
      method:  "POST",
      headers: this.headers,
      body:    JSON.stringify({ messages, max_tokens: 300, stream: true }),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`HTTP ${res.status}: ${err}`);
    }

    let fullText = "";
    const decoder = new TextDecoder();

    for await (const chunk of res.body) {
      const lines = decoder.decode(chunk).split("\n").filter(Boolean);
      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const payload = line.slice(6).trim();
        if (payload === "[DONE]") break;
        try {
          const json  = JSON.parse(payload);
          const delta = json.choices?.[0]?.delta?.content ?? "";
          process.stdout.write(delta);
          fullText += delta;
        } catch { /* skip malformed chunks */ }
      }
    }
    process.stdout.write("\n");
    return fullText;
  }
}

async function main() {
  const client = new SAPAIClient({
    baseUrl:       BASE_URL,
    token:         TOKEN,
    deploymentId:  DEPLOY_ID,
    resourceGroup: RG,
  });

  for (const question of QUESTIONS) {
    console.log(`\n${"=".repeat(60)}`);
    console.log(`Q: ${question}`);

    console.log("--- Non-streaming answer ---");
    const answer = await client.chat([
      { role: "system", content: "You are a concise SAP expert." },
      { role: "user",   content: question },
    ]);
    console.log(`A: ${answer}`);

    console.log("--- Streaming answer ---");
    process.stdout.write("A: ");
    await client.stream([
      { role: "system", content: "You are a concise SAP expert." },
      { role: "user",   content: question },
    ]);
  }
}

main().catch(err => { console.error(err); process.exit(1); });
