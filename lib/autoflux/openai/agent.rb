# frozen_string_literal: true

module Autoflux
  module OpenAI
    # The agent is design to use OpenAI as an agent
    class Agent
      def initialize(model:, client: Client.new, memory: [])
        @client = client
        @model = model
        @memory = memory
      end

      def call(prompt)
        @memory << { role: :user, content: prompt }
        complete
      end

      private

      def complete
        @client.call(
          model: @model,
          messages: @memory.to_a
        ).dig(:choices, 0, :message)
      end
    end
  end
end
