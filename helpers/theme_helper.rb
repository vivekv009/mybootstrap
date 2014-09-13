# coding: utf-8
require 'hpricot'
require 'open-uri'
require 'json'

def view_on_twitter(status)
  return if status.twitter_id.nil? or status.twitter_id.empty?
  return link_to('voir sur Twitter', File.join('https://twitter.com', status.user.twitter_account, 'status', status.twitter_id), {class: 'u-syndication', rel: 'syndication'})
end

def tag_links(article, prefix="tags")
  new_article = article
  new_article.tags.shift
  "#{prefix}" + " " + new_article.tags.map { |tag| link_to tag.display_name, "#{tag.permalink_url(nil, true)}/", :rel => "tag"}.sort.join(", ")
end

def tagged_author(article)
  article.tags.first.display_name
end  

def render_similar_posts(article)
  unless article.tags.empty?
    mylist = Array.new
    article.tags.each do |tag| 
      mylist += Tag.find_by_name(tag.name).articles.where('state= ? and published = ? and id != ?', 'published', true, article.id)
    end
    mylist = mylist.uniq
    mylist.sort_by {rand}[0,4]
  end
end

def display_thumbnail(article)
  img = get_image(article)
  
  if img
    uri = img.attributes['src']
    if uri.include?('http://')
      path = File.join(Rails.root, 'public', uri.split('/')[3..-2].join('/'))
    else
      path = File.join(uri.split('/')[0..-2].join('/'))
    end

    picture = uri.split('/').last
    filepath = File.join(path, "#{picture}")

    if filepath.include?('https')
       return image_tag(uri.gsub(picture, "#{picture}"), :alt => img.attributes['alt'], :class => 'thumb circular')
    end
  end
  
  return image_tag(File.join(this_blog.base_url, "images", "theme", "placeholder.jpg"), :alt => h(article.title), :class => 'thumb circular')
end

def note_title(content)
  content.strip_html.slice(0..80)
end

def t_month(month)
  return month	
  # months = {
  #   'january' => 'janvier',
  #   'february' => 'fevrier',
  #   'march' => 'mars',
  #   'april' => 'avril',
  #   'may' => 'mai',
  #   'june' => 'juin',
  #   'july' => 'juillet',
  #   'august' => 'aout',
  #   'september' => 'septembre',
  #   'october' => 'octobre',
  #   'november' => 'novembre',
  #   'december' => 'décembre'
  # }
  
  # return months[month] ? months[month] : 'Oooops'
end

def get_image(article)
  doc = Hpricot(article.body + article.extended)
  img = doc.at("img.centered")
  
  return img if img
  doc.at("img")
end

def twitter_card(article, description)
  img = get_image(article)

  <<-HTML
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:creator" content="@fdevillamil" />
  <meta name="twitter:site" content="@fdevillamil" />
  <meta name="twitter:title" content="#{h(article.title)}" />
  <meta name="twitter:description" content="#{h(description)}" />
  <meta name="twitter:domain" content="t37.net" />
  <meta name="twitter:image" content="#{img.attributes['src'] if img}" />
  HTML
end

def open_graph(article, description)
  img = get_image(article)
  
  <<-HTML
  <meta property="og:locale" content="en_US" />
  <meta property="og:description" content="#{h(description)}" />
  <meta property="og:url" content="#{article.permalink_url}" />
  <meta property="og:type" content="article" />
  <meta property="og:image" content="#{img.attributes['src'] if img}" />
  HTML
end

def google_plus(article, description)
  img = get_image(article)
  
  <<-HTML
  <meta itemprop="name" content="#{h(article.title)}" />
  <meta itemprop="description" content="#{h(description)}" />
  <meta itemprop="image" content="#{img.attributes['src'] if img}" />
  HTML
end

#To relace heroku domain
def replace_heroku_domain(permalink_url, custom_domain)
  if permalink_url.include?("http://inuni-blog.herokuapp.com") 
    path = permalink_url.split("http://inuni-blog.herokuapp.com")[1] 
  elsif permalink_url.include?("http://localhost:3000")
    path = permalink_url.split("http://localhost:3000")[1]
  end      

  path = custom_domain + path
end  

def get_title
  page = params[:page] ? "<br />page #{params[:page]}" : ""
  if controller.action_name == 'archives' or controller.action_name == 'search' or (controller.controller_name == 'tags' and controller.action_name == 'show')
     # return content_tag(:h1, link_to("#{this_blog.blog_name}<br />Archives".html_safe, controller: 'articles', action: 'archives').html_safe).html_safe
     return content_tag(:h1, link_to("#{this_blog.blog_name}<br />".html_safe, controller: 'articles', action: 'archives').html_safe).html_safe
  end
  
  # if controller.action_name == 'search'
  #   return content_tag(:h1, link_to("Results for #{params[:q]}#{page}".html_safe, controller: 'articles', action: 'search', q: params[:q], page: params[:page]).html_safe).html_safe
  # end
  
  # if controller.controller_name == 'tags' and controller.action_name == 'show'
  #   published = params[:id] == 'english' ? "Articles In English" : "Articles publiés dans #{@grouping.display_name}"
  #   return content_tag(:h1, link_to("#{published}#{page}".html_safe, controller: 'tags', action: 'show', id: params[:id], page: params[:page]).html_safe).html_safe
  # end

  if controller.controller_name == 'notes' and controller.action_name == 'show'
    return content_tag(:h1, link_to(truncate(@note.html(:body).strip_html, length: 66, separator: ' ', omissions: '...'), controller: 'notes', action: 'show', id: params[:id]))
  end
  
  return content_tag(:h1, link_to("#{this_blog.blog_name}#{page}".html_safe, this_blog.base_url).html_safe).html_safe
end
