require 'palette'

describe Palette do
  describe ".new" do
    it "should get properties from initialize" do
      palette = Palette.new("boom!", "headshot!")
      palette.name.should == "boom!"
      palette.colours.should == "headshot!"
    end
  end
  describe ".default_palettes" do
    it "should return the default palettes" do
      default_palettes = Palette.default_palettes
      default_palettes.count.should == 5
    end
  end
end