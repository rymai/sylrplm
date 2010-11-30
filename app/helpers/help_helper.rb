module HelpHelper
  
  def h_help(key)
    root_help=h_help_root
    msg=h_help_elem(root_help,key)
    if(msg==nil)
      help={:key=>key, 
                    :title=>t(:help_no_help_title),
                    :text=>t(:help_no_help,:key=>key),
      } 
    else      
      txt=nil
      hlp=msg[:el].text
      title=nil
      if(hlp==nil)
        txt=t(:help_no_help,:key=>key)
      else   
        txt=h_help_transform(hlp)             
      end
      suitable_helps=h_help_suitable(root_help,key)
      title=msg[:el].attributes["title"]
      href=msg[:el].attributes["href"]
      help={:key=>key, 
              :title=>title,
              :href=>href,
              :text=>txt,
              :previous_src=>suitable_helps[:previous_src],
              :main_src=>suitable_helps[:main_src],
              :upper_src=>suitable_helps[:upper_src],
              :next_src=>suitable_helps[:next_src],
              :childs_src=>suitable_helps[:childs_src]}
    end
    help
  end
  
  def h_help_elem(elem,key)
    helem=nil
    el = elem.elements["msg[@key='#{key}']"]
    if(el==nil)
      elem.each_element("msg") { |element| 
        amsg=h_help_elem(element,key)
        if(amsg!=nil)   
          msg_ul=h_help_ul(element)
          puts "h_help_elem:msg_ul="+element.attribute(:key).to_s+":"+msg_ul
          if msg_ul!=""
            amsg[:el].text+=msg_ul
          end
          helem={:el=>amsg[:el], :main_elem=>element}
          return helem
        end
      }
    else
      msg_ul=h_help_ul(el)
      puts "h_help_elem:msg_ul="+el.attribute(:key).to_s+":"+msg_ul
      if msg_ul!=""
        el.text+=msg_ul
      end      
      helem={:el=>el, :main_elem=>elem}
    end    
    helem
  end
  
  def h_help_suitable(root_help,key)
    previous_src=nil
    main_src=nil
    upper_src=nil
    next_src=nil
    childs_src=nil
    msg=h_help_elem(root_help,key)
    if(msg!=nil)
      if(msg[:el]!=nil)
        if(msg[:el].previous_element!=nil)
          previous_src=msg[:el].previous_element.attribute(:key).to_s
          #previous_src="<a href='/help?help=#{previous_src}' title='previous'>"+img("previous")+"</a>"
        end
        if(msg[:main_elem]!=nil)
          main_src=msg[:main_elem].attribute(:key).to_s
          if(main_src.to_s.strip()!="") 
            #main_src="<a href='/help?help=#{main_src.to_s}' title='main'>"+img("main")+"</a>"
          end
        end         
        if(msg[:el].parent!=nil)
          upper_src=msg[:el].parent.attribute(:key).to_s
          if(upper_src.to_s.strip()!="") 
            #upper_src="<a href='/help?help=#{upper_src.to_s}' title='upper'>"+img("upper")+"</a>"
          end
        end                      
        if(msg[:el].next_element!=nil)
          next_src=msg[:el].next_element.attribute(:key).to_s
          #next_src="<a href='/help?help=#{next_src}' title='next'>"+img("next")+"</a>"
        end
      end
      childs_src=[]
      msg[:el].each_element { |child| 
        key=child.attribute(:key)
        childs_src<<"<a href='/help?help=#{key}'>#{key}</a>"
      }
    end
    suite={:previous_src=>previous_src, :main_src=>main_src, :upper_src=>upper_src, :next_src=>next_src, :childs_src=>childs_src}       
  end
  
  
  
  def h_help_root
    #xmlHelp = REXML::Document.new(File.new("/home/syl/trav/rubyonrails/sylrplm/public/help.xml"))
    xmlHelp = REXML::Document.new(File.new("public/help_"+session[:lng]+".xml"))
    root_help = xmlHelp.root
  end
  
  def h_help_all   
    root_help=h_help_root
    #sommaire
    msg="<h1><a class='help_tr' name='help_summary'>"+t(:help_summary)+"</a></h1>\n"
    msg+=h_help_summary(root_help)
    msg+="<hr>\n"
    #contenu
    msg+=h_help_level(root_help)  
  end
  
  
  def h_help_level(elem)
    #puts "h_help_level:"+elem.name
    #puts "h_help_level:"+h_help_root.name
    msg=""
    msg+="<ul class='help_key'>\n"
    if elem.attributes["title"]!=nil
      msg+="<a class='help_tr' name='"+elem.attributes["key"]+"'></a>\n"
      if(elem.attributes["href"]!=nil)
        msg+="<a class='help_tr' href='"+elem.attributes["href"]+"'>"+elem.attributes["title"]+"</a>\n"
      else
        msg+="<a class='help_tr' >"+elem.attributes["title"]+"</a>\n"
        #msg=msg+elem.attributes["title"]+"<br/>"
      end
      msg+="<a class='help_tr' href='#help_summary'>"+h_img_tit("help_upper",t(:help_summary))+"</a>\n"
      ## msg+="<A HREF='javascript:javascript:history.go(-1)'>"+h_img_tit("previous",t(:help_previous))+"</A>"
    end
    msg+=h_help_transform(elem.text)
    msg+=h_help_ul(elem)
    elem.elements.each("msg") { |element| 
      msg+="<li class='help_key'>\n"
      msg+=  h_help_level(element)
      msg+="</li>\n"  
    }
    msg+="</ul>\n"
    msg
  end
  
  def h_help_summary(elem)
    msg=""
    msg+="<ul class='help_key'>\n"
    if(elem.attributes["title"]!=nil)
      msg+="<a class='help_tr' href='#"+elem.attributes["key"]+"'>"+elem.attributes["title"]+"</a>\n"
    end
    elem.elements.each("msg") { |element| 
      msg+="<li class='help_key'>\n"
      msg+=  h_help_summary(element)
      msg+="</li>\n"  
    }
    msg+="</ul>\n"
    msg
  end
  
  def h_help_ul(elem)
    msg=""
    elem.elements.each("ul") { |elem_ul|    
      msg=msg+"<ul class='help_ul'>\n"
      if(elem_ul.attributes["title"]!=nil)
        if(elem_ul.attributes["href"]!=nil)
          msg=msg+"<a class='help_tr' href='"+elem_ul.attributes["href"]+"'>"+elem_ul.attributes["title"]+"</a>\n"
        else
          msg=msg+"<b>"+elem_ul.attributes["title"]+"</b>\n"
        end
      end
      msg=msg+  h_help_transform(elem_ul.text)
      elem_ul.elements.each("li") { |elem_li|
        msg=msg+"<li class='help_ul'>\n"
        if(elem_li.attributes["title"]!=nil)
          if(elem_li.attributes["href"]!=nil)
            msg=msg+"<a class='help_tr' href='"+elem_li.attributes["href"]+"'>"+elem_li.attributes["title"]+"</a>\n"
          else
            msg=msg+"<b>"+elem_li.attributes["title"]+"</b>\n"
          end
          msg=msg+"</li>\n" 
          if(elem_li.text!=nil)
            msg=msg+ h_help_transform(elem_li.text)
          end
          msg=msg+  h_help_ul(elem_li)
        else
          if(elem_li.text!=nil)
            msg=msg+ h_help_transform(elem_li.text)
          end
          msg=msg+  h_help_ul(elem_li)
          msg=msg+"</li>\n" 
        end                       
      }
      msg=msg+"</ul>\n"     
    }
    msg
  end
  
  def h_help_transform(hlp)
    
    #ind=hlp.index("aaaa")
    #puts "help_helper:"+ind.to_s+":"+hlp.to_s
    #if ind!=nil
    #  puts "help_helper:"+hlp.to_s+"="+hlp.unpack('U'*hlp.length).collect {|x| x.to_s 10}.inspect 
    #end
    txt=hlp
    special=true
    decode=""
    txt.each_byte do |c|
      decode+=c.to_s+" "
      if c!=10 and c!=13 and c!=32 and c!='\t' 
        special=false 
      end
    end
    if(special)
      ###puts "h_help_transform:"+txt+":"+decode
    end
    if !special
      #puts "h_help_transform:"+txt.length.to_s+":"+txt
      txt.gsub!('\n\n','\n')
      txt.gsub!('\n','<br/>')
      txt.gsub!(10.chr,'<br/>')
      txt.gsub!('\t','')
      txt.gsub! /#hlp=(.+?)=hlp#/, 
              "<img class='help' id='\\1' src='images/help.gif' onclick=\"return helpPopup('\\1');\"></img>"
      txt.gsub! /#img=(.+?)=img#/, 
              "<img class='help_tr' src='images/\\1'></img>"
      txt.gsub! /#jump=(.+?)=jump#/, 
              "<a class='help_tr' href='#\\1' target='_top'>"+t(:help_jump)+"</a>"
      txt.gsub! /#lnk=(.+?)=lnk#/, 
              "<a class='help_tr' href='\\1' target='_blank'>"+t(:help_lnk_acces)+"</a>"
      #txt.gsub! /#ul=#/, 
      #          "<ul class='help_tr'>"
      #txt.gsub! /#=ul#/, 
      #          "</ul>"
      #txt.gsub! /#li=#/, 
      #          "<li class='help_tr'>"
      #txt.gsub! /#=li#/, 
      #          "</li>"
      #puts "h_help_transform:"+txt.length.to_s+"|"+txt+"|"
    end
    
    txt+"\n"
    
  end
end
