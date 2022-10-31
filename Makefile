ASSETS := \
	assets/paintball.min.css \
	assets/paintball.min.css.br \
	assets/paintball.min.css.gz

.PHONY: all php js clean dist-clean
.PHONY: all
all: php js

.PHONY: php
php: vendor

.PHONY: js
js: $(ASSETS)

.PHONY: dist-clean
dist-clean: clean
	rm -rf composer.phar vendor node_modules

.PHONY: clean
clean:
	rm -rf assets/*.css assets/*.css.gz assets/*.css.br

vendor: composer.lock composer.phar
	./composer.phar install --prefer-dist

composer.lock: composer.json composer.phar
	./composer.phar update --prefer-dist

composer.phar:
	curl -sSL 'https://getcomposer.org/installer' | php -- --stable
	touch -r composer.json $@

node_modules: package-lock.json
	npm install

package-lock.json: package.json
	npm update

.PRECIOUS: %.css
%.css: %.scss node_modules
	npx sass --no-source-map --quiet $< | \
		npx postcss --no-map --use autoprefixer -o $@

.PRECIOUS: %.min.css
%.min.css: %.css node_modules
	npx postcss --no-map --use cssnano -o $@ $<

%.gz: %
	@rm -f $@
	zopfli -i10000 $<

.PHONY: check-style
check-style: node_modules
	npx stylelint 'assets/*.scss'

BROTLI := $(shell if [ -e /usr/bin/brotli ]; then echo brotli; else echo bro; fi )
%.br: %
ifeq ($(BROTLI),bro)
	bro --quality 11 --force --input $< --output $@ --no-copy-stat
else
	brotli -Zfo $@ $<
endif
	@chmod 644 $@
	@touch $@
