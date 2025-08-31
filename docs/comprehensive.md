## Applications, Scripts, and Frameworks compatible with llm-env

Many tools, libraries, and frameworks have adopted the `OPENAI_API_KEY` and `OPENAI_API_BASE` environment variables as a standard for interoperability, making them ideal for use with the `llm-env` manager.

### Python Ecosystem

* **[LangChain](https://www.langchain.com/)**: A powerful framework for building applications with large language models.
* **[LlamaIndex](https://www.llamaindex.ai/)**: A data framework for LLM applications that helps with data ingestion, structuring, and retrieval.
* **[LiteLLM](https://docs.litellm.ai/)**: A library that provides a single, unified `completion()` function for all LLM APIs, configured via environment variables.
* **[Haystack](https://haystack.deepset.ai/)**: An open-source framework for building applications like question-answering and semantic search.
* **[Griptape](https://www.griptape.ai/)**: A framework for building, deploying, and managing LLM-powered applications.
* **[OpenAI Python Library](https://github.com/openai/openai-python)**: The core library that automatically loads API keys and other variables from your environment.
* **[Aider](https://aider.chat/)**: An AI pair programming tool that works with any OpenAI-compatible API.

### JavaScript / TypeScript Ecosystem

* **[AI SDK](https://sdk.vercel.ai/)**: A comprehensive library by Vercel for building AI applications that defaults to using `OPENAI_API_KEY`.
* **[OpenAI Node.js Library](https://github.com/openai/openai-node)**: The official client that automatically loads API keys from `process.env`.
* **[LobeChat](https://lobehub.com/)**: An open-source, high-performance UI that uses the OpenAI API format for its backend.
* **[Anything LLM](https://anythingllm.com/)**: A full-stack application for creating private chatbots.

### Command-Line Interface (CLI) Tools

* **[`llm` by Simon Willison](https://llm.datasette.io/)**: A popular CLI tool for interacting with LLMs.
* **[`promptfoo`](https://promptfoo.dev/)**: A CLI tool for testing and evaluating LLM prompts across different providers.
* **[OpenAI Codex CLI](https://github.com/microsoft/Codex-CLI)**: A tool that brings the power of OpenAI's models to your terminal.
* **[`ask-cli`](https://github.com/santhoshtr/ask-cli)**: A simple, generic CLI tool for asking questions to an LLM.

### Frameworks & Server-Side Tools

* **[Vercel AI Gateway](https://vercel.com/ai/gateway)**: A proxy that provides an OpenAI-compatible API endpoint for various providers.
* **[Together.ai API](https://www.together.ai/)**: An API designed to be fully compatible with the OpenAI API, allowing for a simple `OPENAI_API_BASE` and key switch.
* **[Runpod vLLM Serverless](https://www.runpod.io/)**: A platform for LLMs that implements an OpenAI-compatible API.
* **[Open WebUI](https://openwebui.com/)**: A self-hostable, multi-user, and multi-model web UI that works with various backends.
