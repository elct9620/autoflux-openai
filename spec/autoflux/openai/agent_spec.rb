# frozen_string_literal: true

RSpec.describe Autoflux::OpenAI::Agent do
  subject(:agent) { described_class.new(model: "gpt-4o-mini") }

  it { is_expected.to have_attributes(model: "gpt-4o-mini") }
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
          )
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
  end

  describe "#call" do
    subject(:call) { agent.call("Hello, world!") }

    it { is_expected.to include(role: "assistant", content: "Hello, world!") }
  end
end
