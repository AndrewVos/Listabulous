class Palette
  attr_accessor :name, :colours

  def initialize(name, colours)
    @name = name
    @colours = colours
  end

  def self.default_palettes
    palettes = []

    palettes << Palette.new("Giant Goldfish", ["#69D2E7", "#A7DBD8", "#E0E4CC", "#F38630", "#FA6900"])
    palettes << Palette.new("mellon ball surprise", ["#D1F2A5", "#EFFAB4", "#FFC48C", "#FF9F80", "#F56991"])
    palettes << Palette.new("cheer up emo kid", ["#556270", "#4ECDC4", "#C7F464", "#FF6B6B", "#C44D58"])
    palettes << Palette.new("Good Friends", ["#D9CEB2", "#948C75", "#D5DED9", "#7A6A53", "#99B2B7"])
    palettes << Palette.new("let them eat cake", ["#774F38", "#E08E79", "#F1D4AF", "#ECE5CE", "#C5E0DC"])

    palettes
  end
end
