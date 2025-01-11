# frozen_string_literal: true

require_relative "openai/version"

module Autoflux
  # The lightweight OpenAI agent for Autoflux
  module OpenAI
    class Error < StandardError; end

    require_relative "openai/client"
    require_relative "openai/agent"
  end
end
