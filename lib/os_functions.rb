module OsFunctions
  
  # universal-darwin9.0 shows up for RUBY_PLATFORM on os X leopard with the bundled ruby. 
  # Installing ruby in different manners may give a different result, so beware.
  # Examine the ruby platform yourself. If you see other values please comment
  # in the snippet on dzone and I will add them.
  
  def os
    case RUBY_PLATFORM
    when /darwin/i
      "mac"
    when /mswin/i
      "win"
    when /linux/i
      "linux"
    else
      nil
    end
  end
  
end 