$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app'))
require 'dxruby'
require 'rotzle'

Input.set_repeat(10, 3)
Rotzle.init
Window.loop do
  Rotzle.play
end
