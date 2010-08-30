require "test/unit"

require "palette"

class TestPalette < Test::Unit::TestCase
  
  def test_initialize_sets_properties
    palette = Palette.new("boom!", "headshot!")
    assert_equal("boom!", palette.name)
    assert_equal("headshot!", palette.colours)
  end
  
  def test_default_palettes_returns_list_of_palettes
    default_palettes = Palette.default_palettes
    assert_equal(11, default_palettes.count)
  end
  
end