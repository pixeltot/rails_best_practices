puts self
@x = "Top-level variable"
puts "@x: " + @x

class MyClass
  puts self
  puts @x
  @y = "In MyClass"
  puts "@y: " + @y

  def my_method
    puts self
    puts @x
    puts @y
    @z = "In my_method"
    puts "@z: " + @z
  end
end
