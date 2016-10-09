module Rotzle
  # 共通
  require 'rotzle/scene'
  require 'rotzle/panel'
  require 'rotzle/board'
  # パズルシーン関連
  require 'rotzle/drop_cursor'
  require 'rotzle/puzzle_manager'
  require 'rotzle/puzzle_scene'

  module ModuleMethods
    def init
      @current_scene = PuzzleScene.new
      @play_method = method(:scene_play)
    end

    def current_scene
      @current_scene
    end

    def play
      @play_method.call
    end

    def scene_play
      @current_scene.play
    end
  end
  extend ModuleMethods
end
