module USerializer
  class Attribute
    attr_reader :key

    def initialize(key, opts, block)
      @key = key
      @opts = opts
      @block = block

      @conditional_block = opts[:if] || proc { true }
    end

    def merge_attributes(res, ser, opts)
      return unless @conditional_block.call(ser.object, opts)

      res[@key] = @block ? @block.call(ser.object, opts) : ser.send(@key)
    end
  end
end
