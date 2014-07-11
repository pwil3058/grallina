MSRCS = grammar.d sets.d symbols.d ../grallina/babs/lexan.d ../grallina/dunnart/templates.d cli.d errors.d workarounds.d

ddpg: ddpg.d dunnart.d $(MSRCS) Makefile
	dmd ddpg.d dunnart.d $(MSRCS)

dunnart.d: ddpg_bootstrap dunnart.ddgs
	./ddpg_bootstrap -f dunnart.ddgs

ddpg_bootstrap: ddpg.d bootstrap.d $(MSRCS) Makefile
	dmd -ofddpg_bootstrap -version=bootstrap ddpg.d bootstrap.d  $(MSRCS)
