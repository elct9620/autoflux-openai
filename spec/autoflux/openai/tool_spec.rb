# frozen_string_literal: true

RSpec.describe Autoflux::OpenAI::Tool do
  subject(:tool) do
    described_class.new(
      name: "uppercase",
      description: "Converts text to uppercase",
      parameters: {
        type: "object",
        properties: {
          text: { type: "string" }
        },
        required: ["text"]
      }
    ) { |params| { text: params[:text].upcase } }
  end

  it { is_expected.to have_attributes(name: "uppercase") }
  it { is_expected.to have_attributes(description: "Converts text to uppercase") }
  it {
    is_expected.to have_attributes(parameters: { type: "object", properties: { text: { type: "string" } },
                                                 required: ["text"] })
  }

  context "without parameters" do
    subject(:tool) do
      described_class.new(
        name: "uppercase",
        description: "Converts text to uppercase"
      ) { |params| { text: params[:text].upcase } }
    end

    it { is_expected.to have_attributes(parameters: nil) }
  end

  context "without executor" do
    subject(:tool) do
      described_class.new(
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
    end

    it "raises an error" do
      expect { tool.call({}) }.to raise_error(Autoflux::OpenAI::Error, "Executor is not defined")
    end
  end

  describe "#call" do
    subject(:call) { tool.call(params) }
    let(:params) { { text: "hello, world!" } }

    it { is_expected.to include(text: "HELLO, WORLD!") }

    context "when call with context" do
      subject(:call) { tool.call(params, workflow_id: 1) }
      let(:tool) do
        described_class.new(
          name: "uppercase",
          description: "Converts text to uppercase",
          parameters: {
            type: "object",
            properties: {
              text: { type: "string" }
            },
            required: ["text"]
          }
        ) { |params, workflow_id:| { text: "#{params[:text].upcase} (#{workflow_id})" } }
      end

      it { is_expected.to include(text: "HELLO, WORLD! (1)") }
    end
  end
end
