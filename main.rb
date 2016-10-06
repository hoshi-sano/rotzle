$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app'))
require 'dxruby'
require 'rotzle'

Rotzle.init
Window.loop do
  Rotzle.play
end
