# coding: utf-8
require 'hpricot'
require 'open-uri'
require 'json'

def category_name(permalink)
  Category.find_by_permalink(permalink).name
end

def tag_links(article, prefix="Tags")
  _(prefix) + " " + article.tags.map { |tag| link_to tag.display_name, "#{tag.permalink_url(nil, true)}/", :rel => "tag"}.sort.join(", ")
end

def display_comments_counter(article)
  link_to(content_tag(:i, "", :class => 'icon-comment icon-white') + " " + pluralize(article.published_comments.size,
    _('%d comment', article.published_comments.size),
    _('%d comment', article.published_comments.size),
    _('%d comments', article.published_comments.size)), article.permalink_url, :class => 'btn btn-mini btn-info').html_safe
end

def render_breadcrumb
  breadcrumb = content_tag(:li, "Vous êtes ici : ")
  separator = " <span class='divider'>&gt;</span> "
  
  if controller.controller_name == "articles" and controller.action_name == "index" and !params[:page]
    breadcrumb << content_tag(:li, "Ergonomie Web, Expérience Utilisateur, Startups et Ruby on Rails", :class => 'active')
  else
    breadcrumb << content_tag(:li, link_to("Le rayon UX", this_blog.base_url) + separator)
  end
    
  if controller.action_name == "redirect" and @article 
    if @article.categories.first
      breadcrumb << content_tag(:li, link_to(@article.categories.first.name, @article.categories.first.permalink_url) + separator) 
    end
    breadcrumb << content_tag(:li, "#{@article.title}", :class => "active")
  elsif controller.controller_name == 'tags'
    if params[:id]
      breadcrumb << content_tag(:li, link_to("Thématiques", "/tags/") + separator)
      mytag = Tag.find_by_name(params[:id])
      breadcrumb << content_tag(:li, "#{mytag.display_name}", :class => "active")
    else
      breadcrumb << content_tag(:li, "Thématiques", :class => "active")
    end
  elsif controller.controller_name == 'categories'
    if params[:id]
      breadcrumb << content_tag(:li, link_to("Catégories", { :controller => "categories", :action => "index" }) + separator)
      mycategory = Category.find_by_permalink(params[:id])
      breadcrumb << content_tag(:li, mycategory.display_name, :class => 'active')
    else
      breadcrumb << content_tag(:li, "Catégories", :class => 'active')
    end
  elsif controller.action_name == 'view_page'
    breadcrumb << content_tag(:li, @page.title)
  end
  
  return content_tag(:ul, breadcrumb.html_safe, :class => 'breadcrumb')
end


def show_pages_links
  html = ''.html_safe
  pages = Page.find(:all, :conditions => {:published => true})
  pages.each do |page|
    html << content_tag(:li, link_to_permalink(page, page.title, nil, render_active_page(page.name)))
  end
  html
end

def render_similar_posts(article)
  unless article.tags.empty?
  	mylist = Array.new
  	article.tags.each do |tag| 
  		mylist += Tag.find_by_name(tag.name).articles
  	end
    mylist = mylist.uniq
    tablo = mylist.sort_by {rand}[0,4]
    i = 0
    html = "<div id='related' class='row'>"
    html << "<h3>À lire également</h3>"
    html << "<p>Si <em>#{article.title}</em> vous a intéressé, vous pouvez poursuivre votre lecture avec ces billets similaires :</p>"
    html << "</div>"
    html << '<div class="row">'
    tablo.each do |article|
    html << "<div class='col-lg-3'>"
      thumb = display_thumbnail(article)
      html << link_to_permalink(article, thumb)
      html << "<small>#{link_to article.title, article.permalink_url}</small>"
      html << "</div>"
      i = i + 1
    end
    html << "</div>"
  end
end

def display_thumbnail(article)
  doc = Hpricot(article.body + article.extended)
  img = doc.at("img.carousel")
  
  img = doc.at("img") unless img
  
  if img
    foo = img.attributes['src'].split('/').last

    if File.exists?(img.attributes['src'].gsub(foo, "thumb_#{foo}").gsub("medium_", "")) 
      return image_tag(img.attributes['src'].gsub(foo, "thumb_#{foo}").gsub("medium_", ""), :alt => img.attributes['alt'], :class => 'thumb')
    end
  end
  return image_tag(File.join(this_blog.base_url, "images", "theme", "placeholder.jpg"), :alt => h(article.title), :class => 'thumb')
end

def note_title(content)
  content.strip_html.slice(0..113)
end
