class Panel < Sprite
  FALL_SPEED = 10

  attr_reader :cell

  def initialize
    super(0, 0, self.class.const_get(:IMAGE))
  end

  def cell=(c)
    @cell = c
    self.x = 20 * c.x
    self.y = 20 * c.y
    @next_y = self.y
  end

  def fall_to(c)
    @cell.panel = nil
    c.instance_variable_set(:@panel, self)
    @cell = c
    @next_y = 20 * c.y
  end

  def linked_vanish!
    @linked_vanish = true
  end

  def update
    if self.y != @next_y
      self.y += FALL_SPEED
      @cell.board.falling!
      return
    end
    if @linked_vanish
      self.alpha -= 15
      if self.alpha > 0
        @cell.board.vanishing!
      else
        @linked_vanish = false
        @cell.panel = nil
      end
    end
  end
end

class RedPanel < Panel
  IMAGE = Image.new(20, 20, [230, 40, 30])
end

class GreenPanel < Panel
  IMAGE = Image.new(20, 20, [30, 200, 80])
end

class BluePanel < Panel
  IMAGE = Image.new(20, 20, [30, 100, 230])
end

class YellowPanel < Panel
  IMAGE = Image.new(20, 20, [255, 200, 0])
end
