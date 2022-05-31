module USerializer
  class Attribute
    attr_reader :key

    def initialize(key, opts, block)
      @key = key
      @opts = opts
      @block = block

      @skip_nil = opts[:skip_nil] || false
      @conditional_block = opts[:if] || proc { true }
    end

    def merge_attributes(res, ser, opts)
      return unless @conditional_block.call(ser.object, opts)

      value = @block ? @block.call(ser.object, opts) : ser.send(@key)

      return if value.nil? && @skip_nil

      res[@key] = value
    end
  end
end
