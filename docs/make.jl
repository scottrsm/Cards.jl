using Cards
import Pkg

Pkg.add("Documenter")
using Documenter

makedocs(
	sitename = "Cards",
	format = Documenter.HTML(),
	modules = [Cards]
	)

	# Documenter can also automatically deploy documentation to gh-pages.
	# See "Hosting Documentation" and deploydocs() in the Documenter manual
	# for more information.
	deploydocs(
		repo = "github.com/scottrsm/Cards.jl.git"
	)
