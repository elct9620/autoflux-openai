# frozen_string_literal: true

RSpec.describe Autoflux::OpenAI::Agent do
  subject(:agent) { described_class.new(model: "gpt-4o-mini") }

  it { is_expected.to have_attributes(model: "gpt-4o-mini") }
  it { is_expected.to have_attributes(name: "openai") }
  it { is_expected.to have_attributes(memory: []) }
  it { is_expected.to have_attributes(tools: nil) }

  before do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [
            {
              message: {
                role: "assistant",
                content: "Hello, world!"
              }
            }
          ]
        }.to_json
      )
  end

  context "with name" do
    subject(:agent) { described_class.new(model: "gpt-4o-mini", name: "test") }

    it { is_expected.to have_attributes(name: "test") }
  end

  context "with tools" do
    subject(:agent) do
      described_class.new(
        model: "gpt-4o-mini",
        tools: [
          Autoflux::OpenAI::Tool.new(
            name: "uppercase",
            description: "Converts text to uppercase",
            parameters: {
              type: "object",
              properties: {
                text: { type: "string" }
              },
              required: ["text"]
            }
          ) { |params| params[:text].upcase }
        ]
      )
    end

    it do
      is_expected.to have_attributes(tools: [
                                       { type: :function,
                                         function: {
                                           name: "uppercase", description: "Converts text to uppercase",
                                           parameters: {
                                             type: "object",
                                             properties: { text: { type: "string" } },
                                             required: ["text"]
                                           }
                                         } }
                                     ])
    end

    it { expect(agent.tool("uppercase")).to be_a(Autoflux::OpenAI::Tool) }
    it { expect(agent.use({ function: { name: "uppercase", arguments: { text: "hello" }.to_json } })).to eq("HELLO") }
  end

  context "with options" do
    subject(:agent) { described_class.new(model: "gpt-4o-mini", temperature: 0.5) }

    it "is expected to call with extra options" do
      agent.call("Hello, world!")
      expect(
        a_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(body: hash_including(temperature: 0.5))
      ).to have_been_made.once
    end
  end

  describe "#call" do
    subject(:call) { agent.call("Hello, world!") }
    let(:tool) { spy(Autoflux::OpenAI::Tool, name: "uppercase") }
    let(:agent) do
      described_class.new(
        model: "gpt-4o-mini",
        tools: [tool]
      )
    end

    it { is_expected.to eq("Hello, world!") }

    context "with tool calls" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              choices: [
                {
                  message: {
                    role: "assistant",
                    tool_calls: [
                      {
                        id: "1",
                        function: {
                          name: "uppercase",
                          arguments: { text: "hello" }.to_json
                        }
                      }
                    ]
                  }
                }
              ]
            }.to_json
          )
          .then
          .to_return(
            status: 200,
            body: {
              choices: [
                {
                  message: {
                    role: "assistant",
                    content: "HELLO"
                  }
                }
              ]
            }.to_json
          )
      end

      it { is_expected.to eq("HELLO") }
      it "is expected to use tool" do
        call
        expect(tool).to have_received(:call).with({ text: "hello" }).once
      end
    end
  end
end
