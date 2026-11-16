module USerializer
  class Attribute
    attr_reader :key

    def initialize(key, opts, block)
      @key = key
      @opts = opts
      @block = block

      @skip_nil = opts[:skip_nil] || false
      @conditional_block = opts[:if]
    end

    def merge_attributes(res, ser, opts)
      return unless allow?(ser, opts)

      value = @block ? @block.call(ser.object, opts) : ser.send(@key)

      return if value.nil? && @skip_nil

      res[@key] = value
    end

    private

    def allow?(ser, opts)
      @conditional_block.nil? || @conditional_block.call(ser.object, opts)
    end
  end
end
