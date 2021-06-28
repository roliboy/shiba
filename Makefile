.PHONY: assemble
assemble:
	@echo -ne '' > shiba
	@cat src/constants.sh >> shiba
	@echo '' >> shiba
	@cat src/help.sh >> shiba
	@echo '' >> shiba
	@cat src/splash.sh >> shiba
	@echo '' >> shiba
	@cat src/argparser.sh >> shiba
	@echo '' >> shiba
	@cat src/handler.sh >> shiba
	@echo '' >> shiba
	@cat src/main.sh >> shiba
	@chmod +x ./shiba
