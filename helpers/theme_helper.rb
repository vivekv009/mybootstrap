# coding: utf-8
require 'hpricot'
require 'open-uri'
require 'json'

def view_on_twitter(status)
  return if status.twitter_id.nil? or status.twitter_id.empty?
  return link_to('voir sur Twitter', File.join('https://twitter.com', status.user.twitter_account, 'status', status.twitter_id), {class: 'u-syndication', rel: 'syndication'})
end

def tag_links(article, prefix="tags")
  t(".#{prefix}").to_s + " " + article.tags.map { |tag| link_to tag.display_name, "#{tag.permalink_url(nil, true)}/", :rel => "tag"}.sort.join(", ")
end

def render_similar_posts(article)
  unless article.tags.empty?
    mylist = Array.new
    article.tags.each do |tag| 
      mylist += Tag.find_by_name(tag.name).articles
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
      path = File.join(Rails.root, 'public', uri.split('/')[0..-2].join('/'))
    end

    picture = uri.split('/').last
    filepath = File.join(path, "thumb_#{picture}")

    if File.exists?(filepath) 
      return image_tag(uri.gsub(picture, "thumb_#{picture}").gsub("medium_", ""), :alt => img.attributes['alt'], :class => 'thumb circular')
    end
  end
  
  return image_tag(File.join(this_blog.base_url, "images", "theme", "placeholder.jpg"), :alt => h(article.title), :class => 'thumb circular')
end

def note_title(content)
  content.strip_html.slice(0..80)
end

def t_month(month)
  return "janvier" if month == "january"
  return "fevrier" if month == "february"
  return "mars" if month == "march"
  return "avril" if month == "april"
  return "mai" if month == "may"
  return "juin" if month == "june"
  return "juillet" if month == "july"
  return "aout" if month == "august"
  return "septembre" if month == "september"
  return "octobre" if month == "october"
  return "novembre" if month == "november"
  return "décembre" if month == "december"
  return "oops"
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
  <meta property="og:locale" content="fr_fr" />
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