module Rotzle
  class DropCursor
    attr_reader :x, :next

    def initialize(panels, board)
      @panels = panels
      @board = board
      @hidden = false
      @x = 0
      @current = @panels.sample.new
      @current.target = @board.render_target
      @current.cell = @board[@x, 0]
      @next = @panels.sample.new
      @next.target = @board.render_target
    end

    def move_to(pos)
      @x = pos
      @current.cell = @board[@x, 0]
    end

    def move_left
      return if @x== 0
      move_to(@x - 1)
    end

    def move_right
      return if @x == @board.h_cell_num - 1
      move_to(@x + 1)
    end

    def drop
      @board[@x, 0].panel = @current
      @current = @next
      @current.cell = @board[@x, 0]
      @next = @panels.sample.new
      @next.target = @board.render_target
    end

    def draw
      return if @hidden
      @current.draw
    end
  end
end
