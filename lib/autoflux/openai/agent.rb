# frozen_string_literal: true

module Autoflux
  module OpenAI
    # The agent is design to use OpenAI as an agent
    class Agent
      attr_reader :model, :memory

      def initialize(model:, client: Client.new, tools: [], memory: [])
        @client = client
        @model = model
        @memory = memory
        @_tools = tools
      end

      def call(prompt)
        @memory << { role: :user, content: prompt }
        complete
      end

      def tools # rubocop:disable Metrics/MethodLength
        return unless @_tools.any?

        @tools ||= @_tools.map do |tool|
          {
            type: :function,
            function: {
              name: tool.name,
              description: tool.description,
              parameters: tool.parameters
            }
          }
        end
      end

      private

      def complete
        @client.call(
          model: @model,
          messages: @memory.to_a,
          tools: tools
        ).dig(:choices, 0, :message)
      end
    end
  end
end
