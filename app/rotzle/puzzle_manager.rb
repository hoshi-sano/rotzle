module Rotzle
  module PuzzleManager
    module ModuleMethods
      def init
        @board = Board.new(15, 10)
        @next_panel_window = NextPanelWindow.new(@board.drop_cursor)
        @update_method = method(:only_update)
        @default_randam_fall_interval = 2
        @randam_fall_interval = @default_randam_fall_interval
      end

      def update_components
        @update_method.call
      end

      def draw_components
        @board.draw
        @next_panel_window.draw
      end

      def only_update
        @board.update
      end

      def wait_falling
        @board.update
        return if @board.animating?
        vanishing_cells = @board.mark_and_sweep
        @board.unmark
        if vanishing_cells.any?
          @update_method = method(:wait_vanishing)
        else
          if @randam_fall_interval <= 0
            @randam_fall_interval = @default_randam_fall_interval
            @board.garbage_panel_random_fall
            @board.fall
            @update_method = method(:wait_falling)
          else
            @randam_fall_interval -= 1
            @update_method = method(:only_update)
          end
        end
      end

      def wait_vanishing
        @board.update
        return if @board.animating?
        @board.fall
        @update_method = method(:wait_falling)
      end

      def wait_rotating
        @board.update
        return if @board.animating?
        @board.fall
        @update_method = method(:wait_falling)
      end

      def wait_dropping
        @board.update
        return if @board.animating?
        # TODO: switch clockwise/counterclockwise
        @board.rotate_clockwise
        @update_method = method(:wait_rotating)
      end

      def check_keys
        return if @board.animating?
        if Input.key_push?(K_LEFT)
          @board.drop_cursor.move_left
        elsif Input.key_push?(K_RIGHT)
          @board.drop_cursor.move_right
        elsif Input.key_push?(K_Z)
          @board.drop_cursor.drop
          @board.fall
          @update_method = method(:wait_dropping)
        end
      end
    end
    extend ModuleMethods
  end
end
