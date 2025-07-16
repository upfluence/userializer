require 'oj'

module USerializer
  class RawSerializer
    def initialize(obj, _)
      @obj = obj
    end

    def serializable_hash(_)
      @obj
    end

    def merge_root(res, key, _, _)
      res[key] = @obj
    end

    def to_hash
      res = {}

      merge_root(res, @root_key, true, nil)

      res
    end

    def to_json
      Oj.dump(to_hash, mode: :compat)
    end
  end
end
