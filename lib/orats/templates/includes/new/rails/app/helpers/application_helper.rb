module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def meta_description(page_meta_description)
    content_for(:meta_description) { page_meta_description }
  end

  def heading(page_heading)
    content_for(:heading) { page_heading }
  end

  def link_to_all_favicons
    '<link href="speeddial-160x160.png" rel="icon" type="image/png" />
      <link href="apple-touch-icon-228x228-precomposed.png" rel="apple-touch-icon-precomposed" sizes="228x228" type="image/png" />
      <link href="apple-touch-icon-152x152-precomposed.png" rel="apple-touch-icon-precomposed" sizes="152x152" type="image/png" />
      <link href="apple-touch-icon-144x144-precomposed.png" rel="apple-touch-icon-precomposed" sizes="144x144" type="image/png" />
      <link href="apple-touch-icon-120x120-precomposed.png" rel="apple-touch-icon-precomposed" sizes="120x120" type="image/png" />
      <link href="apple-touch-icon-114x114-precomposed.png" rel="apple-touch-icon-precomposed" sizes="114x114" type="image/png" />
      <link href="apple-touch-icon-76x76-precomposed.png" rel="apple-touch-icon-precomposed" sizes="76x76" type="image/png" />
      <link href="apple-touch-icon-72x72-precomposed.png" rel="apple-touch-icon-precomposed" sizes="72x72" type="image/png" />
      <link href="apple-touch-icon-60x60-precomposed.png" rel="apple-touch-icon-precomposed" sizes="60x60" type="image/png" />
      <link href="apple-touch-icon-57x57-precomposed.png" rel="apple-touch-icon-precomposed" sizes="57x57" type="image/png" />
      <link href="favicon-196x196.png" rel="icon" sizes="196x196" type="image/png" />
      <link href="favicon-160x160.png" rel="icon" sizes="160x160" type="image/png" />
      <link href="favicon-96x96.png" rel="icon" sizes="96x96" type="image/png" />
      <link href="favicon-64x64.png" rel="icon" sizes="64x64" type="image/png" />
      <link href="favicon-32x32.png" rel="icon" sizes="32x32" type="image/png" />
      <link href="favicon-24x24.png" rel="icon" sizes="24x24" type="image/png" />
      <link href="favicon-16x16.png" rel="icon" sizes="16x16" type="image/png" />
      <link href="favicon.ico" rel="icon" type="image/x-icon" />
      <link href="favicon.ico" rel="shortcut icon" type="image/x-icon" />'.html_safe
  end

  def humanize_boolean(input)
    input ||= ''
    case input.to_s.downcase
      when 't', 'true'
        'Yes'
      else
        'No'
    end
  end

  def css_for_boolean(input)
    if input
      'success'
    else
      'danger'
    end
  end
end