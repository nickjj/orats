namespace :orats do
  desc 'Create favicons from a single base png'
  task :favicons do
    require 'favicon_maker'

    FaviconMaker.generate do
      setup do
        template_dir Rails.root.join('app', 'assets', 'favicon')
        output_dir Rails.root.join('public')
      end

      favicon_base_path = "#{template_dir}/favicon_base.png"

      unless File.exist?(favicon_base_path)
        puts
        puts 'A base favicon could not be found, make sure one exists at:'
        puts favicon_base_path
        puts
        exit 1
      end

      from File.basename(favicon_base_path) do
        icon 'speeddial-160x160.png'
        icon 'apple-touch-icon-228x228-precomposed.png'
        icon 'apple-touch-icon-152x152-precomposed.png'
        icon 'apple-touch-icon-144x144-precomposed.png'
        icon 'apple-touch-icon-120x120-precomposed.png'
        icon 'apple-touch-icon-114x114-precomposed.png'
        icon 'apple-touch-icon-76x76-precomposed.png'
        icon 'apple-touch-icon-72x72-precomposed.png'
        icon 'apple-touch-icon-60x60-precomposed.png'
        icon 'apple-touch-icon-57x57-precomposed.png'
        icon 'favicon-196x196.png'
        icon 'favicon-160x160.png'
        icon 'favicon-96x96.png'
        icon 'favicon-64x64.png'
        icon 'favicon-32x32.png'
        icon 'favicon-24x24.png'
        icon 'favicon-16x16.png'
        icon 'favicon.ico', size: '64x64,32x32,24x24,16x16'
      end

      each_icon do |filepath|
        puts "Creating favicon @ #{filepath}"
      end
    end
  end
end