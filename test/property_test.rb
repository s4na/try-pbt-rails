require "test_helper"
require "rantly"

class PropertyTest < ActiveSupport::TestCase
  # 文字列を2回reverseすると元に戻る
  test "reverse twice returns original string" do
    100.times do
      s = Rantly { string }
      assert_equal s, s.reverse.reverse
    end
  end

  # 配列のサイズは要素を追加すると1増える
  test "array size increases by 1 when element is pushed" do
    100.times do
      array = Rantly { array(range(0, 10)) { integer } }
      elem = Rantly { integer }
      original_size = array.size
      array.push(elem)
      assert_equal original_size + 1, array.size
    end
  end

  # ソートされた配列は元の配列と同じ要素を持つ
  test "sorted array has same elements as original" do
    100.times do
      array = Rantly { array(range(0, 20)) { integer } }
      sorted = array.sort
      assert_equal array.size, sorted.size
      assert_equal array.sort, sorted.sort
    end
  end

  # 整数の加算は交換法則を満たす
  test "integer addition is commutative" do
    100.times do
      a = Rantly { integer }
      b = Rantly { integer }
      assert_equal a + b, b + a
    end
  end

  # 空文字列との連結は元の文字列と等しい
  test "concatenating empty string returns original" do
    100.times do
      s = Rantly { string }
      assert_equal s, s + ""
      assert_equal s, "" + s
    end
  end
end
