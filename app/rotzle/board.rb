class Board
  attr_reader :render_target, :x, :y

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

    # ランダム生成
    100.times do
      klass = [RedBall, GreenBall, BlueBall, YellowBall].sample
      self[rand(h_cell_num), rand(v_cell_num)].ball = klass.new
    end
    fall
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
        @next_ary[i][v_cell_num - 1 - j].ball =  self[i, j].ball
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
        @next_ary[h_cell_num - 1 - i][j].ball =  self[i, j].ball
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
    all_cells { |cell| cell.ball = nil }
    @current_angle = 0
    @rot_unit = nil
    @next_angle = nil
    swith_current_ary
  end

  def current_angle
    @current_angle ||= 0
  end

  def draw
    bg_image.draw
    all_cells(&:draw)
    Window.draw_ex(@x, @y, @render_target, angle: current_angle)
  end

  def fall_point_cell(col_number, row_number)
    fall_row = @current[row_number..-1].reverse
               .find { |ary| ary[col_number].ball.nil? }
    return nil unless fall_row
    fall_row[col_number]
  end

  def mark_and_sweep
    select_cells { |cell| cell.check }
  end

  def unmark
    all_cells(&:unmark!)
  end

  class Cell
    attr_reader :x, :y, :ball, :board

    def initialize(x, y, board)
      @x = x
      @y = y
      @board = board
      @marked = false
    end

    def ball=(b)
      @ball = b
      return unless b
      @ball.cell = self
      @ball.target = @board.render_target
    end

    def update
      return unless @ball
      @ball.update
    end

    def draw
      return unless @ball
      @ball.draw
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
      @ball.linked_vanish!
    end

    def check
      return false if !@ball
      return true if @marked
      same = recursive_check
      if same.size >= 5
        same.each(&:mark!)
        true
      else
        false
      end
    end

    def recursive_check
      same = check_targets.compact.select { |c| !c.checked? && c.ball.is_a?(@ball.class) }
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
      return unless @ball
      prev_cell = @ball.cell
      next_cell = @board.fall_point_cell(prev_cell.x, prev_cell.y)
      return unless next_cell
      @ball.fall_to(next_cell)
    end

    def inspect
      @ball ? 'o' : ' '
    end
  end
end
