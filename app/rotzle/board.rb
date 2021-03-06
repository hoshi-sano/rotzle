module Rotzle
  class Board
    attr_reader :render_target, :x, :y, :drop_cursor

    def initialize(x_size, y_size)
      @x = 100
      @y = 100
      max_size = [x_size, y_size].max
      @render_target = RenderTarget.new(20 * max_size + 20, 20 * max_size + 20)
      @hrz_img = Sprite.new(-5, -5, Image.new(20 * x_size + 10, 20 * y_size + 10, C_WHITE))
      @hrz_img.target = @render_target
      @vrt_img = Sprite.new(-5, -5, Image.new(20 * y_size + 10, 20 * x_size + 10, C_WHITE))
      @vrt_img.target = @render_target
      @x_size = x_size
      @y_size = y_size
      @horizontal_ary = Array.new(@y_size).map.with_index { |_, cy|
        Array.new(@x_size).map.with_index { |_, cx| Cell.new(cx, cy, self) }
      }
      @vertical_ary = Array.new(@x_size).map.with_index { |_, cy|
        Array.new(@y_size).map.with_index { |_, cx| Cell.new(cx, cy, self) }
      }
      @next_ary = @horizontal_ary
      swith_current_ary

      panel_classes = [RedPanel, GreenPanel, BluePanel, YellowPanel]
      # ランダム生成
      100.times do
        self[rand(h_cell_num), rand(v_cell_num)].panel = panel_classes.sample.new
      end
      fall

      @drop_cursor = DropCursor.new(panel_classes, self)
    end

    def swith_current_ary
      if @next_ary.equal?(@horizontal_ary)
        @render_target.ox = -((@render_target.width / 2)  - (@hrz_img.image.width / 2))
        @render_target.oy = -((@render_target.height / 2) - (@hrz_img.image.height / 2))
      else
        @render_target.ox = -((@render_target.width / 2)  - (@vrt_img.image.width / 2))
        @render_target.oy = -((@render_target.height / 2) - (@vrt_img.image.height / 2))
      end
      @current = @next_ary
      @next_ary = nil
    end

    def h_cell_num
      @current.first.size
    end

    def v_cell_num
      @current.size
    end

    def vertical?
      @current.equal?(@vertical_ary)
    end

    def horizontal?
      !vertical?
    end

    def bg_image
      vertical? ? @vrt_img : @hrz_img
    end

    # 時計回りに回転
    def rotate_clockwise(angle = 90)
      @next_ary = vertical? ? @horizontal_ary : @vertical_ary
      @current_angle = 0
      @next_angle = angle
      @rot_unit = 10
      (0...h_cell_num).each do |i|
        (0...v_cell_num).to_a.reverse.each do |j|
          @next_ary[i][v_cell_num - 1 - j].panel =  self[i, j].panel
        end
      end
    end

    # 反時計回りに回転
    def rotate_counterclockwise(angle = 90)
      @next_ary = vertical? ? @horizontal_ary : @vertical_ary
      @current_angle = 360
      @next_angle = 360 - angle
      @rot_unit = -10
      (0...h_cell_num).to_a.reverse.each do |i|
        (0...v_cell_num).each do |j|
          @next_ary[h_cell_num - 1 - i][j].panel =  self[i, j].panel
        end
      end
    end

    def fall
      @current.reverse.each do |ary|
        ary.each(&:fall)
      end
    end

    def [](x, y)
      return nil unless (0...h_cell_num).include?(x) && (0...v_cell_num).include?(y)
      @current[y][x]
    end

    def falling!
      @falling = true
    end

    def vanishing!
      @vanishing = true
    end

    def animating?
      @falling || @vanishing || rotating?
    end

    def rotating?
      !!@rot_unit
    end

    def all_cells
      @current.each do |ary|
        ary.each do |cell|
          yield(cell)
        end
      end
    end

    def select_cells
      res = []
      @current.each do |ary|
        ary.each do |cell|
          res << cell if yield(cell)
        end
      end
      res
    end

    def update
      @falling = false
      @vanishing = false
      if rotating?
        @current_angle += @rot_unit
        finish_rotate if @current_angle == @next_angle
      end
      all_cells(&:update)
    end

    def finish_rotate
      all_cells { |cell| cell.panel = nil }
      @current_angle = 0
      @rot_unit = nil
      @next_angle = nil
      adjust_drop_cursor_position
      swith_current_ary
    end

    def adjust_drop_cursor_position
      return unless @drop_cursor.x > @next_ary.first.size - 1
      @drop_cursor.move_to(@next_ary.first.size - 1)
    end

    def current_angle
      @current_angle ||= 0
    end

    def draw
      bg_image.draw
      all_cells(&:draw)
      @drop_cursor.draw
      Window.draw_ex(@x, @y, @render_target, angle: current_angle)
    end

    def fall_point_cell(col_number, row_number)
      fall_row = @current[row_number..-1].reverse
                 .find { |ary| ary[col_number].panel.nil? }
      return nil unless fall_row
      fall_row[col_number]
    end

    def mark_and_sweep
      select_cells { |cell| cell.check }
    end

    def unmark
      all_cells(&:unmark!)
    end

    def garbage_panel_random_fall
      fall_row = @current[0]
      num = rand(fall_row.size)
      fall_row.sample(num).each do |cell|
        cell.panel = GarbagePanel.new
      end
    end

    class Cell
      attr_reader :x, :y, :panel, :board

      def initialize(x, y, board)
        @x = x
        @y = y
        @board = board
        @marked = false
      end

      def panel=(b)
        @panel = b
        return unless b
        @panel.cell = self
        @panel.target = @board.render_target
      end

      def update
        return unless @panel
        @panel.update
      end

      def draw
        return unless @panel
        @panel.draw
      end

      def unmark!
        @checked = false
        @marked = false
      end

      def check!
        @checked = true
      end

      def checked?
        !!@checked
      end

      def mark!
        @marked = true
        @panel.linked_vanish!
        check_targets.compact.each do |c|
          c.panel.linked_vanish! if c.panel && c.panel.garbage?
        end
      end

      def check
        return false if !@panel || @panel.garbage?
        return true if @marked
        same = recursive_check
        if same.size >= 3
          same.each(&:mark!)
          true
        else
          false
        end
      end

      def recursive_check
        same = check_targets.compact.select { |c| !c.checked? && c.panel.is_a?(@panel.class) }
        check!
        if same.any?
          same << self
          same << same.map(&:recursive_check)
        end
        same.flatten.compact.uniq
      end

      def check_targets
        [
          @board[@x - 1, @y],
          @board[@x + 1, @y],
          @board[@x, @y - 1],
          @board[@x, @y + 1],
        ]
      end

      def fall
        return unless @panel
        prev_cell = @panel.cell
        next_cell = @board.fall_point_cell(prev_cell.x, prev_cell.y)
        return unless next_cell
        @panel.fall_to(next_cell)
      end

      def inspect
        @panel ? 'o' : ' '
      end
    end
  end
end
