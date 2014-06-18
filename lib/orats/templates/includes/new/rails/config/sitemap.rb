# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.app_name.com"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Examples:
  #
  # add root_path
  # add foobar_path, priority: 0.7, changefreq: 'daily'
  #
  # Iteration example:
  #
  # Article.published.find_each do |article|
  #   add article_path("#{article.id}-#{article.permalink}"), priority: 0.9, lastmod: article.updated_at
  # end
end