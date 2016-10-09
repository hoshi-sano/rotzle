module Rotzle
  module PuzzleManager
    module ModuleMethods
      def init
        @board = Board.new(15, 10)
        @update_method = method(:only_update)
      end

      def update_components
        @update_method.call
      end

      def draw_components
        @board.draw
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
          @update_method = method(:only_update)
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
