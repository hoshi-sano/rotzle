module Rotzle
  class NextPanelWindow < Sprite
    POSITION = [460, 100]
    WINDOW_IMAGE = Image.new(80, 80, C_WHITE)

    def initialize(drop_cursor)
      super(*POSITION, WINDOW_IMAGE)
      @drop_cursor = drop_cursor
      @next_panel_x = POSITION[0] + WINDOW_IMAGE.width / 2 - drop_cursor.next.image.width / 2
      @next_panel_y = POSITION[1] + WINDOW_IMAGE.height / 2 - drop_cursor.next.image.height / 2
    end

    def draw
      super
      Window.draw(@next_panel_x, @next_panel_y, @drop_cursor.next.image)
    end
  end
end
