Para = function(e)
  if (not quarto.doc.isFormat("revealjs") and not quarto.doc.isFormat("beamer") and not quarto.doc.isFormat("pptx")) then
    if (e == pandoc.Para '. . .') then
      return {}
    end
  end
  return nil
end