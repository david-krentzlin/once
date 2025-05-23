# frozen_string_literal: true

module Once
  module Storage
    module Redis
      # Codecs are strategies to encode keys and values in the redis storage.
      # They allow users with an extension point to create their own keyspace partitioning and representation of values.
      module Codec
        # Abstract class for value encoding and decoding
        class Key
          def encode(key, timestamp, window)
            raise NotImplementedError, 'Subclasses must implement the encode method'
          end

          def decode(encoded_key, window)
            raise NotImplementedError, 'Subclasses must implement the decode method'
          end
        end

        # Abstract class for value encoding and decoding
        class Value
          def encode(status, timestamp)
            raise NotImplementedError, 'Subclasses must implement the encode method'
          end

          def decode(encoded_value)
            raise NotImplementedError, 'Subclasses must implement the decode method'
          end
        end

        # The identity codec does not change the key or value.
        class IdentityKey < Key
          def encode(key, _timestamp, _window)
            key
          end

          def decode(encoded_key, _window)
            encoded_key
          end
        end

        # NamespacedKey codec prefixes the key with a namespace.
        class NamespacedKey < Key
          def initialize(namespace)
            super()
            @namespace = namespace.to_s
          end

          def encode(key, _timestamp, _window)
            return key if @namespace.empty?

            "#{@namespace}:#{key}"
          end

          def decode(encoded_key, _window)
            return encoded_key if @namespace.empty?

            encoded_key.sub("#{@namespace}:", '')
          end
        end

        # BinaryValue codec encodes the value as a 64 bit packed binary.
        # This is efficient storage suitable for most usecases.
        #
        # The lower u8 are interepreted as the state (started, succeeded, failed).
        # The uper u56 are interpreted as the timestamp.
        class BinaryValue < Value
          def encode(status, timestamp)
            [(status << 56) | timestamp].pack('Q>')
          end

          def decode(encoded_value)
            raw = encoded_value.unpack1('Q>')
            status = (raw >> 56) & 0xFF
            timestamp = raw & 0x00FF_FFFF_FFFF_FFFF

            [status, timestamp]
          end
        end
      end
    end
  end
end
