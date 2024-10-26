defmodule IckyVenus.HtmlRenderer do
  import EEx

  def render_html(html_path, assigns \\ []) do
    content = eval_file(html_path, assigns: assigns)

    eval_file("lib/icky_venus/root.html.eex", assigns: [content: content])
  end
end
