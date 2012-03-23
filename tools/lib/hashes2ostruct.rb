require 'ostruct'

def hashes2ostruct(object)
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = hashes2ostruct(value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| hashes2ostruct(i) }
  else
    object
  end
end

if __FILE__ == $0
  require 'test/unit'
  
  class Tashes2ostructTest < Test::Unit::TestCase
    def test_hash
      struct = hashes2ostruct({"foo" => "bar", "colors" => ["red", "blue"]})
      assert_equal(struct.foo, "bar")
      assert_equal(struct.colors, ["red", "blue"])
      assert_nil(struct.bar)
    end
    
    def test_integer
      struct = hashes2ostruct({"foo" => 5})
      assert_equal(struct.foo, 5)
    end
    
    def test_array
      struct = hashes2ostruct([{"foo" => "bar"}, {"baz" => "bing"}])
      assert_equal(struct[0].foo, "bar")
      assert_equal(struct[1].baz, "bing")
    end
    
    def test_nested
      hash = {
        "foo" => "bar",
        "baz" => {"colors" => ["red", "blue"]}
      }
      struct = hashes2ostruct(hash)
      assert_equal(struct.foo, "bar")
      assert_equal(struct.baz.colors[1], "blue")
    end
  end
end
