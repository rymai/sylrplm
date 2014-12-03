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

  def h_help_key(key)
    #ret = h_help_elem(h_help_root, key)[:el]
    #puts "h_help_key(#{key})=(#{ret.count})#{ret.inspect}"
    #ret.each do |tt|
    #puts "h_help_key(#{key})=#{tt.inspect}"
    #end
    #ret=h_help_replace(ret)
    elem = h_elem_key(key)
    #puts "========= h_help_key(#{key})elem=#{elem}"
    unless elem.nil?
      ret = h_help_level(elem, false)
    else
      ret="<h2>No help definition for the key '#{key}'</h2>"
    end
    #puts "h_help_key(#{key})=#{ret}"
    ret
  end

  def h_help_elem(elem,key)
    helem=nil
    el = elem.elements["msg[@key='#{key}']"]
    if(el==nil)
      elem.each_element("msg") { |element|
        amsg=h_help_elem(element,key)
        if(amsg!=nil)
          msg_ul=h_help_ul(element)
          #puts "h_help_elem:msg_ul="+element.attribute(:key).to_s+":"+msg_ul
          if msg_ul!=""
            amsg[:el].text+=msg_ul
          end
          helem={:el=>amsg[:el], :main_elem=>element}
        return helem
        end
      }
    else
      msg_ul=h_help_ul(el)
      #puts "h_help_elem:msg_ul="+el.attribute(:key).to_s+":"+msg_ul
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
        title=child.attribute(:title)
        childs_src<<"<a href='/help?help=#{key}'>#{title}</a>"
      }
    end
    suite={:previous_src=>previous_src, :main_src=>main_src, :upper_src=>upper_src, :next_src=>next_src, :childs_src=>childs_src}
  end

  def h_help_root
    xmlHelp = REXML::Document.new(File.new("public/help_#{session[:lng]}.xml"))
    root_help = xmlHelp.root
  end

  def h_help_all
    ret=""
    #TODO syl ret=read_help_file
    if ret==""
      ret=build_help_all
    #TODO syl pour eviter d'ecrire si heroku write_help_file(ret)
    end
    ret
  end

  def build_help_all
    root_help = h_help_root
    #sommaire
    msg = "<h1>#{t(:help_summary)}</h1><a class='help_tr' name='help_summary'></a>\n"
    msg += "<h2>#{t(:help_root_title)}</h2>\n"
    msg += h_help_summary(root_help,0)
    #msg += "<hr>\n"
    #contenu
    msg += h_help_level(root_help)
    msg
  end

  def write_help_file(hlp)
    filename = get_help_file_name
    #puts "help_helper.write_help_file:"+filename
    f=File.new(filename,"w")
    f.write(hlp)
  end

  def read_help_file
    filename = get_help_file_name
    #puts "help_helper.read_help_file:"+filename
    if File.exist?(filename)
      ret=File.new(filename).read
    else
      puts "read_help_file:pas de fichier help:"+filename
      ret=""
    end
  end

  def get_help_file_name
    dirname = "#{RAILS_ROOT}/work"
    filename = dirname+"/help_"+I18n.locale.to_s+".html"
  end

  def h_elem_key(key, parent=nil)
    #puts "h_elem_key:key=#{key} parent=#{parent}"
    ret=nil
    if parent.nil?
      parent = h_help_root
    #puts "h_elem_key:key=#{key} parent=#{parent}"
    end
    parent.elements.each("msg") { |element|
      if(element.attributes["key"]) == key.to_s
      #puts "h_elem_key:key=#{key} element=#{element.inspect}"
      ret = element
      break
      else
        ret= h_elem_key(key, element)
      end
    }
    ret
  end

  def h_help_level(elem, with_anchor=true)
    #puts "=============== h_help_level:with_anchor=#{with_anchor} #{elem} "
    msg=""
    unless elem.nil?
      msg+="<ul class='help_key'>\n"
      unless elem.attributes["title"].nil?
        if with_anchor==true
          msg+="<a class='help_tr' name='"+elem.attributes["key"]+"'></a>\n"
          if(elem.attributes["href"]!=nil)
            msg+="<a class='help_tr' href='"+elem.attributes["href"]+"'>"+elem.attributes["title"]+"</a>\n"
          else
            msg+="<a class='help_tr' >"+elem.attributes["title"]+"</a>\n"
          end
          msg+="<a class='help_tr' href='#help_summary'>"+h_img_tit("help_upper",t(:help_summary))+"</a>\n"
        else
          msg+="<b>#{elem.attributes["title"]}</br></b>"
        end
      end
      msg+=h_help_transform(elem.text)
      msg+=h_help_ul(elem)
      elem.elements.each("msg") { |element|
        msg+="<li class='help_key'>\n"
        msg+=  h_help_level(element, with_anchor)
        msg+="</li>\n"
      }
      msg+="</ul>\n"
    end
    msg
  end

  def h_help_summary(elem,level)
    level+=1
    msg=""
    msg+="<ul class='help_key'>\n"
    if(elem.attributes["title"]!=nil)
      msg+="<a class='help_tr' href='#"+elem.attributes["key"]+"'>"+elem.attributes["title"]+"</a>\n"
    end
    if level <= PlmServices.get_property(:HELP_SUMMARY_LEVEL).to_i
      elem.elements.each("msg") { |element|
        msg+="<li class='help_key'>\n"
        msg+=  h_help_summary(element, level)
        msg+="</li>\n"
      }
    end
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
    txt=hlp
    special=true
    #decode=""
    txt.each_byte do |c|
    #decode+=c.to_s+" "
      if c!=10 && c!=13 && c!=32 && c!='\t'
      special=false
      end
    end
    if !special
      txt = h_help_replace(txt)
    end
    txt+"\n"
  end

  def h_help_replace(txt)
    #puts "h_help_transform:"+txt.length.to_s+":"+txt
    txt.gsub!('#br#','<br/>')
    txt.gsub!('\n\n','\n')
    ###txt.gsub!('\n','<br/>')
    txt.gsub!(':'+10.chr,':<br/>')
    txt.gsub!('.'+10.chr,'.<br/>')
    txt.gsub!('\t','')
    txt.gsub!(/#bloc=(.+?)=bloc#/){|bloc| PlmServices.exec_bloc(bloc, "#{$1}")}
    #
    txt.gsub! /#hlp=(.+?)=hlp#/,
    "<img class='help' id='\\1' src='/images/help.png' onclick=\"return helpPopup('\\1');\"></img>"
    #
    txt.gsub! /#img=(.+?)=img#/,
    "<img class='help_tr' src='/images/\\1'></img>"
    #
    txt.gsub! /#jump=(.+?)=jump#/,
    "<a class='help_tr' href='/main/helpgeneral#\\1' target='_top'>"+t(:help_jump)+"</a>"
    #
    txt.gsub! /#lnk=(.+?)=lnk#/,
    #"<a class='help_tr' href='\\1' target='_blank' title='"+t(:help_lnk_acces)+"'><img src='/images/submit.png'></img></a>"
    "<a class='help_tr' href='\\1' target='_blank' title='"+t(:help_lnk_acces)+"'>\\1</a>"
    #
    txt
  end

  #help on a chapter
  def help_chapter(chapter, cls=nil)
    ret = ""
    ret << "<a onclick=\"return helpWindow('#{chapter}');\""
    ret<< " class=\"#{cls}\"" unless cls.nil?
    ret<<">#{t(chapter)}</a>"
    ret
  end

  def help_window(cls=nil)
    ret = ""
    ret << "<a onclick=\"return helpWindow('help_#{params[:controller]}_#{params[:action]}');\""
    ret<< " class=\"#{cls}\"" unless cls.nil?
    ret << ">#{t(:help_window)}</a>"
    ret
  end

  def h_help_menu(name,link)
    bloc=""
    if(link!=nil && link.strip()!="")
      bloc<<"<a href='/help?help="+link+"'>"+h_img(name)+"</a>"
    end
  end

  # memorisation du click sur le help
  def tip_help()
    bloc=""
    bloc<<"<img class='help' id='tip_help' src='/images/help.png' onclick='return helpTip();'>"
    bloc
  end

  def show_help(key, with_img = true)
    txt=t(key.to_s)
    bloc=""
    if with_img
      bloc<<"<img class=\"help\" id=\"#{key.to_s}\"  src=\"/images/help.png\"
    onclick=\"return helpPopup('#{key.to_s}');\" >"
    else
      bloc<<"<a href='/help?help="+key.to_s+"' onclick=\"return helpPopup('#{key.to_s}');\">"+txt+"</a>"
    end
    bloc
  end

end
