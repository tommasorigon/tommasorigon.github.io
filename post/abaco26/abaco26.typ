// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  pagenumbering: "1",
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#import "@preview/fontawesome:0.5.0": *

#show: doc => article(
  title: [ABACO26],
  subtitle: [#emph[Nonparametric predictive inference for discrete data via Metropolis-adjusted Dirichlet sequences];],
  authors: (
    ( name: [Tommaso Rigon],
      affiliation: [#emph[Università degli Studi di Milano-Bicocca];],
      email: [] ),
    ),
  date: [2026-02-06],
  lang: "en",
  pagenumbering: "1",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Warm thanks
<warm-thanks>
#block[
#block[
Davide Agnoletto (Duke University)

#align(left)[#box(image("img/davide.jpg"))]
]
#block[
]
#block[
David Dunson (Duke University)

#align(left)[#box(image("img/david.jpeg"))]
]
]
= Foundations
<foundations>
- De Finetti's representation Theorem (De Finetti 1937) it provides the fundamental justification to the two approaches to Bayesian statistics: the hypothetical approach and the predictive approach.

#block[
#callout(
body: 
[
Let $(Y_n)_(n gt.eq 1)$, be a sequence of exchangeable random variables. Then there exists a unique probability measure $Pi$ such that, for any $n gt.eq 1$ and $A_1 \, dots.h \, A_n$ $ bb(P) (Y_1 in A_1 \, dots.h \, Y_n in A_n) = integral_(cal(P)) product_(i = 1)^n p (A_i) thin Pi (upright(d) p) . $

]
, 
title: 
[
De Finetti's representation theorem
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
- In a hierarchical formulation, we will say that $(Y_n)_(n gt.eq 1)$ is exchangeable if and only if \$\$
  \\begin{aligned}
  Y\_i \\mid P &\\overset{\\textup{iid}}{\\sim} P, \\qquad i \\ge 1, \\\\
  P &\\sim \\Pi,
  \\end{aligned}
  \$\$ where $P$ is a random probability measure and $Pi$ is the prior law.

= Hypothetical approach
<hypothetical-approach>
- The hypothetical approach represents the the most common way to operate within the Bayesian community.

- In a parametric setting, $Pi$ has support on a class $Theta subset.eq bb(R)^p$ with $p < oo$, such that $bold(theta) in Theta$ indexes the class of distributions $cal(P)_(bold(theta)) = { P_(bold(theta)) : bold(theta) in Theta subset.eq bb(R)^p }$.

- Bayes' rule takes the well-known formulation: $ pi (bold(theta) divides y_(1 : n)) prop pi (bold(theta)) product_(i = 1)^n p_(bold(theta)) (y_i) \, $ where $pi$ and $p_(bold(theta))$ denote the probability density functions associated with $Pi$ and $P_(bold(theta))$, respectively.

- However, when the link between observations and parameter of interest cannot be easily expressed through a distribution function, the traditional hypothetical approach fails.

- Solution: generalized posterior distributions, sometimes called Gibbs-posteriors.

- This is a lively recent topic, see for instance: Chernozhukov and Hong (2003); Bissiri et al. (2016) Heide et al. (2020); Grünwald and Mehta (2020); Knoblauch et al. (2022); Matsubara et al. (2022); Matsubara et al. (2023); Jewson and Rossell (2022); Rigon et al. (2023); Agnoletto et al. (2025).

= Generalizations of the hypothetical approach
<generalizations-of-the-hypothetical-approach>
- Bissiri et al. (2016) showed that the generalized posterior $ pi_omega (bold(theta) divides y_(1 : n)) prop pi (bold(theta)) exp {- omega sum_(i = 1)^n ell (bold(theta) ; y_i)} \, $ is the only coherent update of the prior beliefs about $ bold(theta)^(\*) = arg min_(bold(theta) in Theta) integral_(cal(Y)) ell (bold(theta) ; y) thin F_0 (upright(d) y) \, $ where $ell (bold(theta) \, y)$ is a loss function, $omega$ is the loss-scale, and $F_0$ is the unknown true sampling distribution.

- Learning the loss scale $omega$ from the data is a delicate task. Assuming a prior for $omega$ can lead to degenerate estimates if not accompanied by additional adjustments to the loss function.

- However, there are several solutions for its calibration: Holmes and Walker (2017); Lyddon et al. (2019); Syring and Martin (2019); Matsubara et al. (2023).

= Predictive approach
<predictive-approach>
- Taking a predictive approach, one can implicitly characterize the prior via de Finetti theorem by specifying the sequence of predictive distributions of an exchangeable sequence: $ P_n (A) := bb(P) (Y_(n + 1) in A divides y_(1 : n)) \, #h(2em) n gt.eq 1 . $ This leads to an exchangeable sequences iff the conditions in Fortini et al. (2000) are satisfied.

- Example: the predictive construction of a Dirichlet process prior is such that $Y_1 tilde.op P_0$ and $Y_(n + 1) divides y_(1 : n) tilde.op P_n$ for $n gt.eq 1$, where $ P_n (A) = frac(alpha, alpha + n) P_0 (A) + frac(1, alpha + n) sum_(i = 1)^n bb(1) (y_i in A) \, $ for any measurable set $A$.

- The possibility of specifying a sequence of one-step-ahead predictive distributions is appealing:
  - it bypasses direct elicitation of the prior;
  - it explicitly connects prediction and inference (see the next slide);

= Connecting inference and prediction I
<connecting-inference-and-prediction-i>
- The posterior $P divides y_(1 : n)$ is usually obtained through Bayes theorem, but this is not the only way.

- We can characterize both prior and posterior of $P$ through the predictive distributions $P_n$, which indeed contains all the necessary information.

- If $(Y_n)_(n gt.eq 1)$ is exchangeable, then the prior and posterior mean of $P$ coincide with the predictive: $ P_0 (A) = bb(P) (Y_1 in A) = bb(E) { P (A) } \, #h(2em) P_n (A) = bb(P) (Y_(n + 1) in A divides y_(1 : n)) = bb(E) (P (A) divides y_(1 : n)) \, #h(2em) n gt.eq 1 . $

- A deeper result holds, which is a corollary of Finetti theorem (Fortini and Petrone 2012).

#block[
#callout(
body: 
[
Let $(Y_n)_(n gt.eq 1)$ be an exchangeable sequence with predictive distributions $(P_n)_(n gt.eq 1)$. Then $P_n$ converges weakly (a.s. $bb(P)$) to a random probability measure $P$ distributed according to $Pi$ as $n arrow.r oo$.

]
, 
title: 
[
De Finetti's representation theorem (predictive form)
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
= Connecting inference and prediction II
<connecting-inference-and-prediction-ii>
- In other words, the sequence of predictive distributions $P_n$ converges to a random probability measure $P$ with prior distribution $Pi$. The source of randomness is the data \
  $ Y_1 \, Y_2 \, Y_3 \, dots.h $ Intuitively, before observing the data, our predictions eventually reflect the prior.

- Given $y_(1 : n)$, the sequence $P_(n + m)$ converges weakly (a.s. $bb(P)$) as $m arrow.r oo$ to a random probability measure with posterior distribution $Pi (dot.op divides y_(1 : n))$. The source of randomness is the future data \
  $ Y_(n + 1) \, Y_(n + 2) \, Y_(n + 3) \, dots.h . $

- This provides a natural alternative interpretation of the posterior distribution $P divides y_(1 : n)$ and a practical algorithm for sampling from it, called predictive resampling.

- Intuitively, posterior uncertainty arises from lack of knowledge about future observations. If we knew them, the posterior would collapse to a point mass (Bayesian consistency).

- This reasoning is at the heart of martingale posteriors (Fong et al. 2023).

= Generalizations of the predictive approach
<generalizations-of-the-predictive-approach>
- Defining a sequence of predictive laws $P_n$ that guarantees exchangeability---i.e., satisfies the two-step-ahead conditions of Fortini et al. (2000)---is a difficult task in practice.

- Solution: replace exchangeability with the weaker requirement that $(Y_n)_(n gt.eq 1)$ is conditionally identically distributed (CID), also known as martingale posteriors.

- The CID condition requires $ bb(P) (Y_(n + k) in dot.op divides y_(1 : n)) = bb(P) (Y_(n + 1) in dot.op divides y_(1 : n)) = P_n (dot.op) \, #h(2em) upright("for all") quad k gt.eq 1 \, #h(0em) n gt.eq 1 . $ It is sufficient to verify this condition for $k = 1$ in order to ensure its validity for all $k gt.eq 1$.

- Equivalently, Fong et al. (2023) express the above condition in a way that emphasizes the martingale property of the predictive distributions $ bb(E) { P_(n + 1) (dot.op) divides y_(1 : n) } = P_n (dot.op) \, #h(2em) n gt.eq 1 . $

- This is another lively recent topic: Fortini and Petrone (2020); Berti et al. (2021); Fortini et al. (2021); Berti et al. (2023a); Berti et al. (2023b); Fong et al. (2023); Fong and Yiu (2024a); Fong and Yiu (2024b); Cui and Walker (2024); Fortini and Petrone (2024) and more…

= Nonparametric modelling of count data
<nonparametric-modelling-of-count-data>
- Bayesian nonparametric modeling of counts distributions is a challenging task. Nonparametric mixtures of discrete kernels (Canale and Dunson 2011) can be cumbersome in practice.

- Alternatively, one could directly specify a DP prior on the data generator as \$\$
    Y\_i\\mid P \\overset{\\textup{iid}}{\\sim} P,\\quad P\\sim\\mathrm{DP}(\\alpha, P\_0),
  \$\$ for $Y_i in cal(Y) = { 0 \, 1 \, dots.h }$, $i = 1 \, dots.h \, n$, where $alpha$ is the precision parameter and $P_0$ a base parametric distribution, such as a Poisson.

- The Dirichlet process is mathematically convenient. However, the corresponding posterior lacks smoothing, which can lead to poor performance.

- Within the hypothetical approach, it is unclear how to specify a nonparametric process with the same simplicity and flexibility as the DP prior while allowing for smoothing.

- Our proposal: a predictive sequence tailored to count data inspired by kernel density estimators.

= Illustrative example I
<illustrative-example-i>
#align(center)[#box(image("img/example_plot.jpg", width: 7.29167in))]
- Left plot: posterior mean of a DP. Right plot: posterior mean of the proposed MAD sequence.

= A recursive predictive rule
<a-recursive-predictive-rule>
- Intuitively, a better estimator would be obtained by replacing the indicator $bb(1) (dot.op)$ of the DP predictive scheme with a kernel that allows the borrowing of information between nearby values.

- Let $Y_1 tilde.op P_0$ and $Y_(n + 1) divides y_(1 : n) tilde.op P_n$ for $n gt.eq 1$, and let $K_n (dot.op divides y_n)$ be a sequence of transition kernels. We define the predictive distribution recursively: $ P_n (dot.op) = bb(P) (Y_(n + 1) in dot.op divides y_(1 : n)) = (1 - w_n) P_(n - 1) (dot.op) + w_n K_n (dot.op divides y_n) \, #h(2em) n gt.eq 1 \, $ where $(w_n)_(n gt.eq 1)$ are decreasing weights such that $w_n in (0 \, 1)$, $sum_(n gt.eq 1) w_n = oo$, and $sum_(n gt.eq 1) w_n^2 < oo$.

- The choice of weights $w_n = (alpha + n)^(- 1)$ gives the following DP-like predictive rule $ P_n (dot.op) = frac(alpha, alpha + n) P_0 (dot.op) + frac(1, alpha + n) sum_(i = 1)^n K_i (dot.op divides y_i) . $ Hence, the predictive law of a DP is a special case whenever $K_i (dot.op divides y_i) = delta_(y_i) (dot.op)$.

#block[
#callout(
body: 
[
The above sequence, beyond the DP special case, is not exchangeable and it will depend on the order of the data. Moreover, without further restrictions, is not necessarily CID!

]
, 
title: 
[
Tip
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
= Metropolis-adjusted Dirichlet (MAD) sequences
<metropolis-adjusted-dirichlet-mad-sequences>
- We assume that $K_n (dot.op divides y_n)$ is a Metropolis-Hastings kernel centered in $y_n$ having pmf: $ k_n (y divides y_n) = gamma_n (y \, y_n) k_(\*) (y divides y_n) + bb(1) (y = y_n) #scale(x: 180%, y: 180%)[\[] sum_(z in cal(Y)) #scale(x: 120%, y: 120%)[{] 1 - gamma_n (z \, y_n) #scale(x: 120%, y: 120%)[}] k_(\*) (z divides y_n) #scale(x: 180%, y: 180%)[\]] \, $ with acceptance probability $ gamma_n (y \, y_n) = gamma (y \, y_n \, P_(n - 1)) = min {1 \, frac(p_(n - 1) (y) k_(\*) (y_n divides y), p_(n - 1) (y_n) k_(\*) (y divides y_n))} \, $ where $p_(n - 1)$ is the probability mass functions associated to $P_(n - 1)$ and $k_(\*) (dot.op divides y_n)$ is the pmf of a discrete base kernel centered at $y_n$.

- We refer to $P_n$ above as the Metropolis-adjusted Dirichlet (MAD) distribution with weights $(w_n)_(n gt.eq 1)$, base kernel $k_(\*)$ and initial distribution $P_0$. We call $(Y_n)_(n gt.eq 1)$ a MAD sequence.

#block[
#callout(
body: 
[
Let $(Y_n)_(n gt.eq 1)$ be a MAD sequence. Then, for every set of weights $(w_n)_(n gt.eq 1)$, discrete base kernel $k_(\*)$, and initial distribution $P_0$, the sequence $(Y_n)_(n gt.eq 1)$ is conditionally identically distributed (CID).

]
, 
title: 
[
Theorem (Agnoletto, R. and Dunson, 2025)
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
= Bayesian properties of CID sequences I
<bayesian-properties-of-cid-sequences-i>
#block[
#callout(
body: 
[
Consider a MAD sequence $(Y_n)_(n gt.eq 1)$. Then, $bb(P)$-a.s.,

$(a)$ The sequence is asymptotically exchangeable, that is \$\$
    (Y\_{n+1}, Y\_{n+2}, \\ldots) \\overset{\\textup{d}}{\\longrightarrow} (Z\_1, Z\_2, \\ldots), \\qquad n \\rightarrow \\infty,
\$\$ where $(Z_1 \, Z_2 \, dots.h)$ is an exchangeable sequence with directing random probability measure $P$;

$(b)$ the corresponding sequence of predictive distributions $(P_n)_(n gt.eq 1)$ weakly converge to a random probability measures $P$ (a.s. $bb(P)$).

]
, 
title: 
[
Corollary (Aldous 1985; Berti et al. 2004)
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
- An asymptotic equivalent of de Finetti's theorem holds: each MAD sequence has a corresponding unique prior on $P$.

- The ordering dependence will vanish asymptotically and, informally, $Y_i divides P tilde.op^(upright(i i d)) P$ for large $n$.

- The random probability measure $P$ exists and is defined as the limit of the predictive distributions. However, it is not available explicitly.

= Bayesian properties of CID sequences II
<bayesian-properties-of-cid-sequences-ii>
#block[
#callout(
body: 
[
Let $theta = P (f) = sum_(y in cal(Y)) f (y) p (y)$ and analogously $theta_n = P_n (f) = sum_(y in cal(Y)) f (y) p_n (y)$ be any functional of interest. Consider a MAD sequence $(Y_n)_(n gt.eq 1)$.

Then, $bb(P)$-a.s., for every $n gt.eq 1$ and every integrable function $f : cal(Y) arrow.r bb(R)$, we have $ bb(E) (theta divides y_(1 : n)) = bb(E) { P (f) divides y_(1 : n) } = P_n (f) = theta_n $

]
, 
title: 
[
Corollary (Aldous 1985; Berti et al. 2004)
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
- Broadly speaking, the posterior mean of any functional of interest of $P$ coincides with the functional of the predictive.

- Moreover, $bb(E) { P (f) } = P_0 (f) = theta_0$ for every integrable function $f$, so that $P_0$ retains the role of a base measure as for standard Dirichlet sequences, providing an initial guess at $P$.

- Uncertainty quantification for $theta = P (f)$ is carried out by predictive resampling (Fong et al. 2023).

= Predictive resampling for MAD sequences
<predictive-resampling-for-mad-sequences>
#strong[Algorithm (Fortini and Petrone 2020):]

+ Compute $P_n (dot.op)$ from the observed data $y_(1 : n)$
+ Set $N gt.double n$
+ For $j = 1 \, dots.h \, B$
  #block[
  #set enum(numbering: "a.", start: 1)
  + For $i = n + 1 \, dots.h \, N$
    #block[
    #set enum(numbering: "i.", start: 1)
    + Sample $Y_i divides y_(1 : i - 1) tilde.op P_(i - 1)$
    + Update $P_i (dot.op) = (1 - w_i) P_(i - 1) (dot.op) + w_i K_(i - 1) (dot.op divides y_i)$
    ]
  + End For
  ]
+ End For
+ Return $P_N^((1)) (dot.op) \, dots.h \, P_N^((B)) (dot.op)$, an iid sample from the distribution of $P_N (dot.op) divides y_(1 : n)$

= On the choice of the base kernel
<on-the-choice-of-the-base-kernel>
- In principle, any discrete distribution can be chosen as the base kernel $k_(\*)$. However, it is natural to consider choices that allow the kernel to be centered at $y_n$ while permitting control over the variance.

- We consider a rounded Gaussian distribution centered in $y_n$, with pmf $ k_(\*) (y divides y_n \, sigma) = frac(integral_(y - 1 \/ 2)^(y + 1 \/ 2) cal(N) (t divides y_n \, sigma^2) upright(d) t, sum_(z in cal(Y)) integral_(z - 1 \/ 2)^(z + 1 \/ 2) cal(N) (t divides y_n \, sigma^2) upright(d) t) \, $ for $n gt.eq 1$, where $cal(N) (dot.op divides y_n \, sigma^2)$ denotes a normal density function with mean $y_n$ and variance $sigma^2$.

#align(center)[#box(image("img/ker_plot_slide.jpg", width: 8.85417in))]
= Role of the weights in controlling posterior variability
<role-of-the-weights-in-controlling-posterior-variability>
- It can be shown that the distribution of $P (A) divides y_(1 : n)$ is approximated by $cal(N) (P_n (A) \, Sigma_n r_n^(- 1))$ for $n$ large, where the variance is $ Sigma_n r_n^(- 1) approx bb(E) { [P_(n + 1) (A) - P_n (A)]^2 divides y_(1 : n) } sum_(k > n + 1) w_k^2 . $

- Weights that decay to zero quickly induce fast learning and convergence to the asymptotic exchangeable regime.

- But small values of $w_n$ leads to poor learning and underestimation of the posterior variability.

- Possible choices are $w_n = (alpha + n)^(- 1)$, $w_n = (alpha + n)^(- 2 \/ 3)$ (Martin and Tokdar 2009), and $w_n = (2 - n^(- 1)) (n + 1)^(- 1)$ (Fong et al. 2023).

- We consider adaptive weights $ w_n = (alpha + n)^(- lambda_n) \, #h(2em) lambda_n = lambda + (1 + lambda) exp #scale(x: 240%, y: 240%)[{] - 1 / N_(\*) n #scale(x: 240%, y: 240%)[}] \, $ with $lambda in \( 0.5 \, 1 \]$, $N_(\*) > 0$.

= Illustrative example II
<illustrative-example-ii>
#align(center)[#box(image("img/example_complete.jpg", width: 8.85417in))]
= Multivariate count and binary data
<multivariate-count-and-binary-data>
- Extending MAD sequences for multivariate data is straightforward using a factorized base kernel $ k_(\*) (bold(y) divides bold(y)_n) = product_(j = 1)^d k_(\*) (y_j divides y_(n \, j)) \, $ with $bold(y) = (y_1 \, dots.h \, y_d)$ and $bold(y)_n = (y_(n \, 1) \, dots.h \, y_(n \, d))$.

- MAD sequences can be employed for modeling multivariate binary data using an appropriate base kernel.

- A natural step further is to use MAD sequences for nonparametric regression and classification.

= Simulations I
<simulations-i>
Out-of-sample prediction accuracy evaluated in terms of MSE and AUC for regression and classification, respectively.

#table(
  columns: (16.67%, 16.67%, 16.67%, 16.67%, 16.67%, 16.67%),
  align: (auto,auto,auto,auto,auto,auto,),
  table.header([], [Regression (MSE)], [], [], [Classification (AUC)], [],),
  table.hline(),
  [], [#strong[$n = 40$];], [#strong[$n = 80$];], [], [#strong[$n = 150$];], [#strong[$n = 300$];],
  [GLM], [120.77 \[51.51\]], [94.93 \[8.37\]], [], [0.796 \[0.014\]], [0.809 \[0.007\]],
  [BART], [101.17 \[12.69\]], [74.17 \[10.00\]], [], [0.863 \[0.026\]], [0.932 \[0.009\]],
  [RF], [99.98 \[7.45\]], [87.75 \[6.53\]], [], [0.882 \[0.025\]], [0.913 \[0.015\]],
  [DP], [1450.21 \[5.53\]], [1395.61 \[8.72\]], [], [0.644 \[0.011\]], [0.724 \[0.012\]],
  [#strong[MAD-1];], [91.07 \[10.35\]], [73.96 \[7.60\]], [], [0.873 \[0.014\]], [0.899 \[0.008\]],
  [#strong[MAD-2/3];], [88.83 \[13.00\]], [73.18 \[9.58\]], [], [0.869 \[0.015\]], [0.899 \[0.009\]],
  [#strong[MAD-dpm];], [87.41 \[12.36\]], [72.07 \[9.48\]], [], [0.872 \[0.014\]], [0.901 \[0.008\]],
  [#strong[MAD-ada];], [#strong[90.61 \[10.28\]];], [#strong[73.45 \[7.69\]];], [], [#strong[0.874 \[0.014\]];], [#strong[0.900 \[0.008\]];],
)
= Simulations II
<simulations-ii>
#align(center)[#box(image("img/pl_cov_sim.jpg", width: 85.0%))]
= Application
<application>
- We analyze the occurrence rates of 4 species corvids in Finland in year 2009 across different temperatures and habitats.

#align(center)[#box(image("img/pl_appl_slide_1.jpg", width: 65.0%))]
= Application II
<application-ii>
#align(center)[#box(image("img/pl_appl_slide_2.jpg", width: 85.0%))]
= Thank you!
<thank-you>
#align(center)[#box(image("img/QR.png", width: 2.5in))]
The main paper is:

Agnoletto, D., Rigon, T., and Dunson D.B. (2025+). Nonparametric predictive inference for discrete data via Metropolis-adjusted Dirichlet sequences. #emph[arXiv:2507.08629]

#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
References
]
)
]
#block[
#block[
Agnoletto, D., Rigon, T., and Dunson, D. B. (2025), “Bayesian inference for generalized linear models via quasi-posteriors,” #emph[Biometrika];, 112.

] <ref-Agnoletto2025>
#block[
Aldous, D. J. (1985), “Exchangeability and related topics, ecole d'eté de saint-flour XIII, lectures notes n 1117,” Springer Verlag.

] <ref-aldous1985exchangeability>
#block[
Berti, P., Dreassi, E., Leisen, F., Pratelli, L., and Rigo, P. (2023b), “Kernel based dirichlet sequences,” #emph[Bernoulli];, Bernoulli Society for Mathematical Statistics; Probability, 29, 1321--1342.

] <ref-berti2023kernel>
#block[
Berti, P., Dreassi, E., Leisen, F., Pratelli, L., and Rigo, P. (2023a), “Bayesian predictive inference without a prior,” #emph[Statistica Sinica];, Academia Sinica, Institute of Statistical Science, 34, 2405--2429.

] <ref-berti2023without>
#block[
Berti, P., Dreassi, E., Pratelli, L., and Rigo, P. (2021), “A class of models for Bayesian predictive inference,” #emph[Bernoulli];, 27, 702--726.

] <ref-berti_pratelli_2021>
#block[
Berti, P., Pratelli, L., and Rigo, P. (2004), “Limit theorems for a class of identically distributed random variables,” 32, 2029--2052.

] <ref-berti2004limit>
#block[
Bissiri, P. G., Holmes, C. C., and Walker, S. G. (2016), “A general framework for updating belief distributions,” #emph[Journal of the Royal Statistical Society: Series B (Statistical Methodology)];, Wiley Online Library, 78, 1103--1130.

] <ref-bissiri2016general>
#block[
Canale, A., and Dunson, D. B. (2011), “Bayesian kernel mixtures for counts,” #emph[Journal of the American Statistical Association];, Taylor & Francis, 106, 1528--1539.

] <ref-canale2011bayesian>
#block[
Chernozhukov, V., and Hong, H. (2003), “An MCMC approach to classical estimation,” #emph[Journal of econometrics];, Elsevier, 115, 293--346.

] <ref-chernozhukov2003mcmc>
#block[
Cui, F., and Walker, S. G. (2024), “Martingale posterior distributions for log-concave density functions,” #emph[arXiv preprint arXiv:2401.14515];.

] <ref-cui2024martingale>
#block[
De Finetti, B. (1937), “La prévision: Ses lois logiques, ses sources subjectives,” in #emph[Annales de l'institut henri poincaré];, pp. 1--68.

] <ref-de1937prevision>
#block[
Fong, E., Holmes, C. C., and Walker, S. G. (2023), “Martingale posterior distributions,” #emph[Journal of the Royal Statistical Society Series B: Statistical Methodology];, 85, 1357--1391.

] <ref-fong_holmes_2023>
#block[
Fong, E., and Yiu, A. (2024b), “Bayesian quantile estimation and regression with martingale posteriors,” #emph[arXiv preprint arXiv:2406.03358];.

] <ref-fong2024bayesian>
#block[
Fong, E., and Yiu, A. (2024a), “Asymptotics for parametric martingale posteriors,” #emph[arXiv preprint arXiv:2410.17692];.

] <ref-fong2024asymptotics>
#block[
Fortini, S., Ladelli, L., and Regazzini, E. (2000), “Exchangeability, predictive distributions and parametric models,” #emph[Sankhya: The Indian Journal of Statistics, Series A];, 62, 86--109.

] <ref-fortini2000exchangeability>
#block[
Fortini, S., and Petrone, S. (2012), “Predictive construction of priors in bayesian nonparametrics,” #emph[Brazilian Journal of Probability and Statistics];, 26, 423--449.

] <ref-fortini2012predictive>
#block[
Fortini, S., and Petrone, S. (2020), “Quasi-Bayes properties of a procedure for sequential learning in mixture models,” #emph[Journal of the Royal Statistical Society Series B: Statistical Methodology];, Oxford University Press, 82, 1087--1114.

] <ref-fortini_petrone_2020>
#block[
Fortini, S., and Petrone, S. (2024), “Exchangeability, prediction and predictive modeling in bayesian statistics,” #emph[arXiv preprint arXiv:2402.10126];.

] <ref-fortini2024exchangeability>
#block[
Fortini, S., Petrone, S., and Sariev, H. (2021), “Predictive constructions based on measure-valued pólya urn processes,” #emph[Mathematics];, MDPI, 9, 2845.

] <ref-fortini2021predictive>
#block[
Grünwald, P. D., and Mehta, N. A. (2020), “Fast rates for general unbounded loss functions: from ERM to generalized Bayes,” #emph[The Journal of Machine Learning Research];, JMLRORG, 21, 2040--2119.

] <ref-grunwald2020fast>
#block[
Heide, R. de, Kirichenko, A., Grunwald, P., and Mehta, N. (2020), “Safe-bayesian generalized linear regression,” in #emph[Proceedings of the twenty third international conference on artificial intelligence and statistics];, PMLR, pp. 2623--2633.

] <ref-heide2020safe>
#block[
Holmes, C. C., and Walker, S. G. (2017), “Assigning a value to a power likelihood in a general Bayesian model,” #emph[Biometrika];, Oxford University Press, 104, 497--503.

] <ref-holmes2017assigning>
#block[
Jewson, J., and Rossell, D. (2022), “General bayesian loss function selection and the use of improper models,” #emph[Journal of the Royal Statistical Society Series B: Statistical Methodology];, Oxford University Press, 84, 1640--1665.

] <ref-jewson_rossell_2022>
#block[
Knoblauch, J., Jewson, J., and Damoulas, T. (2022), “An optimization-centric view on bayes' rule: Reviewing and generalizing variational inference,” #emph[Journal of Machine Learning Research];, 23, 1--109.

] <ref-knoblauch2022optimization>
#block[
Lyddon, S. P., Holmes, C. C., and Walker, S. G. (2019), “General Bayesian updating and the loss-likelihood bootstrap,” #emph[Biometrika];, Oxford University Press, 106, 465--478.

] <ref-lyddon2019general>
#block[
Martin, R., and Tokdar, S. T. (2009), “Asymptotic properties of predictive recursion: Robustness and rate of convergence,” #emph[Electornic Journal of Statistics];, 3, 1455--1472.

] <ref-martin2009asymptotic>
#block[
Matsubara, T., Knoblauch, J., Briol, F.-X., and Oates, C. J. (2022), “Robust generalised bayesian inference for intractable likelihoods,” #emph[Journal of the Royal Statistical Society Series B: Statistical Methodology];, Oxford University Press, 84, 997--1022.

] <ref-matsubara2022robust>
#block[
Matsubara, T., Knoblauch, J., Briol, F.-X., and Oates, C. J. (2023), “Generalized bayesian inference for discrete intractable likelihood,” #emph[Journal of the American Statistical Association];, Taylor & Francis, 1--11.

] <ref-matsubara2023generalized>
#block[
Rigon, T., Herring, A. H., and Dunson, D. B. (2023), “A generalized Bayes framework for probabilistic clustering,” #emph[Biometrika];, Oxford University Press, 10, 559--578.

] <ref-rigon2023generalized>
#block[
Syring, N., and Martin, R. (2019), “Calibrating general posterior credible regions,” #emph[Biometrika];, Oxford University Press, 106, 479--486.

] <ref-syring2019calibrating>
] <refs>



