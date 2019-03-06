﻿# coding: utf-8


LATEST_VERSION_REGEX = /(5\s*代\s*5\s*期|Version\s*5\.5)/
DICTIONARY_URL = "conlang/database/1.cgi"

converter.add(["page"], [""]) do |element|
  path, language = converter.path, converter.language
  deepness = converter.deepness
  virtual_deepness = (path =~ /index\.zml$/) ? deepness - 1 : deepness
  title = ""
  navigation_string, header_string, main_string = "", "", ""
  navigation_string << Tag.build("ul", "breadcrumb") do |this|
    this["itemscope"] = "itemscope"
    this["itemtype"] = "https://schema.org/BreadcrumbList"
    if virtual_deepness >= -1
      this << call(element, "breadcrumb-item", 1) do |item_tag, link_tag, name_tag|
        link_tag["href"] = "../" * deepness
        name_tag << NAMES[:top][language]
      end
    end
    if virtual_deepness >= 0
      first_category = path.split("/")[-deepness - 1]
      this << call(element, "breadcrumb-item", 2) do |item_tag, link_tag, name_tag|
        link_tag["href"] = "../../" + first_category
        name_tag << NAMES[first_category.intern][language]
      end
    end
    if virtual_deepness >= 1
      second_category = path.split("/")[-deepness]
      united_category = first_category + "_" + second_category
      this << call(element, "breadcrumb-item", 3) do |item_tag, link_tag, name_tag|
        link_tag["href"] = "../" + second_category
        name_tag << NAMES[united_category.intern][language]
      end
    end
    if virtual_deepness >= 2
      converted_path = path.match(/([0-9a-z\-]+)\.zml/).to_a[1].to_s
      converted_path += (element.attribute("link")&.value == "c") ? ".cgi" : ".html"
      name_element = element.elements.to_a("name").first
      title = name_element.inner_text(true).gsub("\"", "&quot;")
      this << call(element, "breadcrumb-item", 4) do |item_tag, link_tag, name_tag|
        link_tag["href"] = converted_path
        name_tag << apply(name_element, "page")
      end
    end
  end
  navigation_string << apply(element, "navigation")
  header_string << apply(element, "header")
  main_string << apply(element, "page")
  result = TEMPLATE.gsub(/#\{(.*?)\}/){self.instance_eval($1)}.gsub(/\r/, "")
  next result
end

converter.set("breadcrumb-item") do |element, level, &block|
  this = ""
  this << Tag.build("li") do |item_tag|
    item_tag["itemscope"] = "itemscope"
    item_tag["itemprop"] = "itemListElement"
    item_tag["itemtype"] = "https://schema.org/ListItem"
    item_tag << Tag.build("a") do |link_tag|
      link_tag["itemprop"] = "item"
      link_tag["itemtype"] = "https://schema.org/Thing"
      link_tag << Tag.build("span") do |name_tag|
        name_tag["itemprop"] = "name"
        block.call(item_tag, link_tag, name_tag)
      end
    end
    item_tag << Tag.build("meta", nil, false) do |meta_tag|
      meta_tag["itemprop"] = "position"
      meta_tag["content"] = level.to_s
    end
  end
  next this
end

converter.add(["ver"], ["navigation"]) do |element|
  this = ""
  this << Tag.build("div") do |this|
    if element.text == "*" || element.text =~ LATEST_VERSION_REGEX
      this.class = "version"
      converter.configs[:latest] = true
    else
      this.class = "version-caution"
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(nil, ["navigation"]) do |text|
  next ""
end

converter.add(["import-script"], ["header"]) do |element|
  this = ""
  this << Tag.build("script") do |this|
    this["src"] = converter.url_prefix + "file/script/" + element.attribute("src").to_s
  end
  next this + "\n"
end

converter.add(["base"], ["header"]) do |element|
  this = ""
  this << Tag.build("base") do |this|
    this["href"] = element.attribute("href").to_s
  end
  next this + "\n"
end

converter.add(nil, ["header"]) do |text|
  next ""
end

converter.add(["pb"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "index-container") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["hb"], ["page"]) do |element|
  this = ""
  this << Tag.build("h1") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["ab", "abo", "aba", "abd"], ["page"]) do |element|
  this = ""
  this << Tag.build do |this|
    case element.name
    when "ab"
      this.name, this.class = "a", "index"
    when "abo"
      this.name, this.class = "a", "old-index"
    when "aba"
      this.name, this.class = "a", "ancient-index"
    when "abd"
      this.name, this.class = "div", "disabled-index"
    end
    element.attributes.each_attribute do |attribute|
      if attribute.name == "date"
        this << Tag.build("span", "date") do |this|
          if element.attribute("date").value =~ /^\d+$/
            this << Tag.build("span", "hairia") do |this|
              this << element.attribute("date").to_s
            end
          else
            this << element.attribute("date").to_s
          end
        end
      else
        this[attribute.name] = attribute.to_s
      end
    end
    this << Tag.build("span", "content") do |this|
      this << apply(element, "page")
    end
  end
  next this
end

converter.add(["h1", "h2"], ["page"]) do |element|
  this = ""
  this << Tag.build(element.name) do |this|
    element.attributes.each_attribute do |attribute|
      if attribute.name == "number"
        this["id"] = element.attribute("number").to_s
        this << Tag.build("span", "number") do |this|
          this << element.attribute("number").to_s
        end
      else
        this[attribute.name] = attribute.to_s
      end
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["p"], ["page"]) do |element|
  this = ""
  this << Tag.build("p") do |this|
    this << apply(element, "page")
    if element.attribute("par")
      this.head << Tag.build("span", "paragraph") do |this|
        this << element.attribute("par").to_s
      end
    end
    if element.attribute("name")
      this.head << Tag.build("span", "name") do |this|
        this << element.attribute("name").to_s
      end
    end
  end
  next this
end

converter.add(["img"], ["page"]) do |element|
  this = ""
  this << Tag.build("img", nil, false) do |this|
    this["alt"] = ""
    element.attributes.each_attribute do |attribute|
      this[attribute.name] = attribute.to_s
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["a"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["an"], ["page"]) do |element|
  this = ""
  this << Tag.build("a", "normal") do |this|
    element.attributes.each_attribute do |attribute|
      this[attribute.name] = attribute.to_s
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["xl"], ["page"]) do |element|
  this = ""
  this << Tag.build("ul", "conlang") do |this|
    this << apply(element, "page.xl")
  end
  next this
end

converter.add(["li"], ["page.xl"]) do |element|
  this = ""
  this << Tag.build("li") do |this|
    this << apply(element, "page.xl.li")
  end
  next this
end

converter.add(["sh"], ["page.xl.li"]) do |element|
  this = ""
  this << apply(element, "page")
  next this
end

converter.add(["ja"], ["page.xl.li"]) do |element|
  this = ""
  this << Tag.build("ul") do |this|
    this << Tag.build("li") do |this|
      this << apply(element, "page")
    end
  end
  next this
end

converter.add(nil, ["page.xl.li"]) do |text|
  next ""
end

converter.add(["el"], ["page"]) do |element|
  this = ""
  this << Tag.build("table", "list") do |this|
    this << apply(element, "page.el")
  end
  next this
end

converter.add(["li"], ["page.el"]) do |element|
  this = ""
  this << Tag.build("tr") do |this|
    this << apply(element, "page.el.li")
  end
  next this
end

converter.add(["et", "ed"], ["page.el.li"]) do |element|
  this = ""
  this << Tag.build("td") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["trans"], ["page"]) do |element|
  this = ""
  this << Tag.build("table", "translation") do |this|
    this << apply(element, "page.trans")
  end
  next this
end

converter.add(["li"], ["page.trans"]) do |element|
  this = ""
  this << Tag.build("tr") do |this|
    this << apply(element, "page.trans.li")
  end
  next this
end

converter.add(["ja", "sh"], ["page.trans.li"]) do |element|
  this = ""
  this << Tag.build("td") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["section-table"], ["page"]) do |element|
  this = ""
  this << Tag.build("ul", "section-table") do |this|
    section_tag = Tag.new("li")
    subsection_tag = Tag.new("ul")
    element.each_xpath("/page/*[name() = 'h1' or name() = 'h2']") do |inner_element|
      case inner_element.name
      when "h1"
        unless section_tag.content.empty?
          section_tag << subsection_tag unless subsection_tag.content.empty?
          this << section_tag
        end
        section_tag = Tag.build("li") do |this|
          this << apply(inner_element, "page.section-table")
        end
        subsection_tag = Tag.new("ul")
      when "h2"
        subsection_tag << Tag.build("li") do |this|
          if inner_element.attribute("number")
            this << Tag.build("span", "number") do |this|
              this << inner_element.attribute("number").to_s
            end
            this << Tag.build("a") do |this|
              this["href"] = "#" + inner_element.attribute("number").to_s
              this << apply(inner_element, "page.section-table")
            end
          elsif inner_element.attribute("id")
            this << Tag.build("a") do |this|
              this["href"] = "#" + inner_element.attribute("id").to_s
              this << apply(inner_element, "page.section-table")
            end
          else
            this << apply(inner_element, "page.section-table")
          end
        end
      end
    end
    section_tag << subsection_tag unless subsection_tag.content.empty?
    this << section_tag
  end
  next this
end

converter.add(["ul", "ol"], ["page"]) do |element|
  this = pass_element(element, "page.ul")
  next this
end

converter.add(["li"], ["page.ul"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["table"], ["page"]) do |element|
  this = pass_element(element, "page.table")
  next this
end

converter.add(["tr"], ["page.table"]) do |element|
  this = pass_element(element, "page.table.tr")
  next this
end

converter.add(["th", "td"], ["page.table.tr"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["thl"], ["page.table.tr"]) do |element|
  this = ""
  this << Tag.build("th", "left") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["form"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["input"], ["page"]) do |element|
  this = pass_element(element, "page", false)
  next this
end

converter.add(["textarea"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["pdf"], ["page"]) do |element|
  this = ""
  this << Tag.build("object", "pdf") do |this|
    this["data"] = element.attribute("src").to_s + "#view=FitH&amp;statusbar=0&amp;toolbar=0&amp;navpanes=0&amp;messages=0"
    this["type"] = "application/pdf"
  end
  next this
end

converter.add(["slide"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "slide") do |this|
    this << Tag.build("script", "speakerdeck-embed") do |this|
      this["async"] = "async"
      this["data-id"] = element.attribute("id").to_s
      this["data-ratio"] = "1.33333333333333"
      this["src"] = "http://speakerdeck.com/assets/embed.js"
    end
  end
  next this
end

converter.add(["pre", "samp"], ["page"]) do |element|
  this = ""
  raw_string = element.texts.map{|s| s.to_s}.join.gsub(/\A\s*?\n/, "")
  indent_size = raw_string.match(/\A(\s*?)\S/)[1].length
  string = raw_string.rstrip.deindent
  this << Tag.build("table") do |this|
    case element.name
    when "pre"
      this.class = "code"
    when "samp"
      this.class = "sample"
    end
    this << "\n"
    string.each_line do |line|
      this << " " * indent_size
      this << Tag.build("tr") do |this|
        this << Tag.build("td") do |this|
          if line =~ /^\s*$/
            this << " "
          else
            this << line.chomp
          end
        end
      end
      this << "\n"
    end
    this << " " * (indent_size - 2)
  end
  next this
end

converter.add(["c", "m"], ["page", "page.section-table"]) do |element|
  this = ""
  this << Tag.build("span") do |this|
    case element.name
    when "c"
      this.class = "code"
    when "m"
      this.class = "monospace"
    end
    element.children.each do |child|
      case child
      when Element
        this << convert_element(child, "page")
      when Text
        this << child.to_s
      end
    end
  end
  next this
end

converter.add(["special"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["x"], ["page"]) do |element|
  this = ""
  content = apply(element, "page").to_s
  url = converter.url_prefix + DICTIONARY_URL
  link = !!converter.configs[:latest] && converter.path =~ /conlang\/.+\/\d+(\-\w{2})?\.zml/
  this << WordConverter.convert(content, url, link)
  next this
end

converter.add(["x"], ["page.section-table"]) do |element|
  this = ""
  content = apply(element, "page.section-table").to_s
  url = converter.url_prefix + DICTIONARY_URL
  this << WordConverter.convert(content, url, false)
  next this
end

converter.add(["xn"], ["page", "page.section-table"]) do |element|
  this = ""
  content = apply(element, "page").to_s
  url = converter.url_prefix + DICTIONARY_URL
  this << WordConverter.convert(content, url, false)
  next this
end

converter.add(["red"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "redact") do |this|
    this << "&nbsp;" * element.attribute("length").to_s.to_i
  end
  next this
end

converter.add(["sup", "sub"], ["page", "page.section-table"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["h"], ["page", "page.section-table"]) do |element|
  this = ""
  this << Tag.build("span", "hairia") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["k"], ["page", "page.section-table"]) do |element|
  this = ""
  this << Tag.build("span", "japanese") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["i"], ["page", "page.section-table"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["fl"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "foreign") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["small"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "small") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["br"], ["page"]) do |element|
  this = pass_element(element, "page", false)
  next this
end

converter.add_default(nil) do |text|
  string = text.to_s.clone
  string.gsub!("、", "、 ")
  string.gsub!("。", "。 ")
  string.gsub!("「", " 「")
  string.gsub!("」", "」 ")
  string.gsub!("『", " 『")
  string.gsub!("』", "』 ")
  string.gsub!("〈", " 〈")
  string.gsub!("〉", "〉 ")
  string.gsub!(/(、|。)\s+(」|』)/){$1 + $2}
  string.gsub!(/(」|』|〉)\s+(、|。|,|\.)/){$1 + $2}
  string.gsub!(/(\(|「|『)\s+(「|『)/){$1 + $2}
  string.gsub!(/(^|>)\s+(「|『)/){$1 + $2}
  next string
end