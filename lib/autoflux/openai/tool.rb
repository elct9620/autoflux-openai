# frozen_string_literal: true

module Autoflux
  module OpenAI
    # The tool is simple tool wrapper for the agent
    class Tool
      attr_reader :name, :description, :parameters

      def initialize(name:, description:, parameters: nil, &executor)
        @name = name
        @description = description
        @parameters = parameters
        @executor = executor
      end

      def call(params, **context)
        raise Error, "Executor is not defined" unless @executor

        @executor.call(params, **context)
      end
    end
  end
end
