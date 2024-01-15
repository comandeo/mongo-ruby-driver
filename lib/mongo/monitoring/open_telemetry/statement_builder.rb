# frozen_string_literal: true

#
# Copyright (C) 2015-present MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo
  class Monitoring
    # This module contains classes related to OpenTelemetry instrumentation.
    #
    # @api private
    module OpenTelemetry
      # This class is used to build a +db.statement+ attribute for an OpenTelemetry span
      # from a MongoDB command.
      class StatementBuilder
        # @param [ BSON::Document ] command The message that will be
        #   sent to the server.
        # @param [ Boolean ] obfuscate Whether to obfuscate the statement.
        def initialize(command, obfuscate)
          @command = command
          @command_name, @collection = command.first
          @obfuscate = obfuscate
        end

        # Builds the statement.
        #
        # @return [ String ] The statement as a JSON string.
        def build
          statement.to_json.freeze unless statement.empty?
        end

        private

        def statement
          {}.tap do |statement|
            statement['key'] = @command['key'] if @command.key?('key')
            statement['query'] = mask(@command['query']) if @command.key?('query')
            statement['filter'] = mask(@command['filter']) if @command.key?('filter')
            statement['sort'] = @command['sort'] if @command.key?('sort')
            statement['new'] = @command['new'] if @command.key?('new')
            if @command.key?('update') && @command_name == 'findAndModify'
              statement['update'] = mask(@command['update'])
            end
            statement['remove'] = @command['remove'] if @command.key?('remove')
            statement['updates'] = mask_and_trim(@command['updates']) if @command.key?('updates')
            statement['deletes'] = mask_and_trim(@command['deletes']) if @command.key?('deletes')
            statement['pipeline'] = @command['pipeline'].map { |e| mask(e) } if @command.key?('pipeline')
          end
        end

        def mask(hash)
          hash.each_with_object({}) do |(k, v), h|
            next if Mongo::Protocol::Msg::INTERNAL_KEYS.include?(k.to_s)

            value = case v
                    when Hash then mask(v)
                    when Array then v.map { |e| mask(e) }
                    else mask_value(k, v)
                    end
            h[k] = value
          end
        end

        def mask_and_trim(array)
          [
            mask(array.first)
          ].tap do |stmt|
            stmt << '...' if array.size > 1
          end
        end

        def mask_value(key, value)
          if key == @command_name && value == @collection
            @collection
          elsif @obfuscate
            '?'
          else
            value
          end
        end
      end
    end
  end
end
