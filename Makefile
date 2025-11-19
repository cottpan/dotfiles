DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*) bin
CONFIG_DIRS := $(wildcard .config/??*)
EXCLUSIONS := .DS_Store .git .gitmodules .travis.yml .github .gitignore .config
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

all:

list: ## Show dot files in this repo
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)
	@$(foreach val, $(CONFIG_DIRS), /bin/ls -dF $(val);)

install: ## Create symlink to home directory
	@echo 'Deploying dotfiles to home directory...'
	@echo ''
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@echo 'Creating .config directory if it does not exist...'
	@mkdir -p $(HOME)/.config
	@echo 'Deploying .config subdirectories...'
	@$(foreach val, $(CONFIG_DIRS), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

deploy: ## Deploy
	@$(DOTPATH)/etc/init/install.sh

clean: ## Remove the dot files
	@echo 'Remove dot files in your home directory...'
	@-$(foreach val, $(DOTFILES), rm -vrf $(HOME)/$(val);)
	@echo 'Remove .config subdirectories...'
	@-$(foreach val, $(CONFIG_DIRS), rm -vrf $(HOME)/$(val);)

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'