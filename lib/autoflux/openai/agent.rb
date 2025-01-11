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

      def call(prompt, **context)
        @memory << { role: :user, content: prompt }

        loop do
          res = complete
          @memory << res
          break res unless res[:tool_calls]&.any?

          res[:tool_calls].each do |call|
            @memory << { role: :tool, content: use(call, **context).to_json, tool_call_id: call[:id] }
          end
        end
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

      def tool(name)
        @_tools.find { |tool| tool.name == name }
      end

      def use(call, **context)
        name = call.dig(:function, :name)
        params = JSON.parse(call.dig(:function, :arguments), symbolize_names: true)

        tool(name)&.call(params, **context) || { error: "tool not found: #{name}" }
      rescue JSON::ParserError
        { error: "unable parse argument as JSON" }
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
