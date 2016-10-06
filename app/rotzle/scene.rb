module Rotzle
  # 各シーンのベースとなるクラス
  class Scene
    class << self
      # このシーンで利用するManagerモジュールを指定するためのメソッド
      # Managerは以下のメソッドをコール可能であることが期待される
      #   * update_components: 要素の毎フレーム毎の処理の実行用
      #   * draw_components: 要素の描画用
      #   * check_keys: 当該シーン特有のキー入力処理用
      def manager_module(mod)
        @manager_module = mod
      end
    end

    def initialize(*args)
      @manager = self.class.instance_variable_get(:@manager_module)
      args.any? ? @manager.init(*args) : @manager.init
    end

    # シーン切替時の前処理
    def pre_process
    end

    # シーン切替時の後処理
    def post_process
    end

    def play
      @manager.update_components
      @manager.draw_components
      @manager.check_keys
    end
  end
end
