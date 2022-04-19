-- The CommonMark spec suggests that 
-- "```somelang" should produce <code class="language-somelang">
-- 
-- That's what most CommonMark implementation do.
-- Pandoc, however, outputs <code class="somelang">
--
-- This makes using external highlighters much more difficult
-- since you cannot match all code blocks with a known language
-- using a single CSS selector.
--
-- This filter takes over the code block rendering process
-- to produce CommonMark-style output.

function CodeBlock(block)
  if FORMAT:match 'html' then
    local lang_attr = ""
    if (#block.classes > 0) then
      lang_attr = string.format([[class="language-%s"]], block.classes[1])
    else
      -- Ignore code blocks where language is not specified
    end

    local code = block.text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")

    local html = string.format('<pre><code %s>%s</code></pre>', lang_attr, code)
    return pandoc.RawBlock('html', html)
  end
end
