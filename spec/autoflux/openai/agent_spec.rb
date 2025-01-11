# frozen_string_literal: true

RSpec.describe Autoflux::OpenAI::Agent do
  subject(:agent) { described_class.new(model: "gpt-4o-mini") }

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

  describe "#call" do
    subject(:call) { agent.call("Hello, world!") }

    it { is_expected.to include(role: "assistant", content: "Hello, world!") }
  end
end
