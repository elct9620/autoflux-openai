# frozen_string_literal: true

RSpec.describe Autoflux::OpenAI::Client do
  subject(:client) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return("my-api-key")
  end

  describe "#call" do
    subject(:call) { client.call(payload) }
    let(:payload) do
      {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "You are a helpful assistant." }
        ]
      }
    end

    before do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          body: payload.to_json,
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer my-api-key"
          }
        ).to_return(
          status: 200,
          body: { choices: [{ message: { role: "user", content: "Thank you!" } }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it { is_expected.to include(choices: [{ message: { role: "user", content: "Thank you!" } }]) }

    context "when the response is not JSON" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            body: payload.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer my-api-key"
            }
          ).to_return(
            status: 200,
            body: "Not a JSON response",
            headers: { "Content-Type" => "text/plain" }
          )
      end

      it { is_expected.to be_empty }
    end

    context "when the response is not unauthorized" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            body: payload.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer my-api-key"
            }
          ).to_return(
            status: 401,
            body: "Unauthorized",
            headers: { "Content-Type" => "text/plain" }
          )
      end

      it { expect { call }.to raise_error(Autoflux::OpenAI::AuthoriztionError, "Unauthorized") }
    end

    context "when the response is bad request" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            body: payload.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer my-api-key"
            }
          ).to_return(
            status: 400,
            body: "Bad request",
            headers: { "Content-Type" => "text/plain" }
          )
      end

      it { expect { call }.to raise_error(Autoflux::OpenAI::BadRequestError, "Bad request") }
    end

    context "when the response is rate limited" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            body: payload.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer my-api-key"
            }
          ).to_return(
            status: 429,
            body: "Rate limited",
            headers: { "Content-Type" => "text/plain" }
          )
      end

      it { expect { call }.to raise_error(Autoflux::OpenAI::RateLimitError, "Rate limited") }
    end
  end
end
