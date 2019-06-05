ASSETS := \
	assets/paintball.min.css \
	assets/paintball.min.css.br \
	assets/paintball.min.css.gz

.PHONY: all php js clean dist-clean
all: php js

php: vendor

js: $(ASSETS)

dist-clean: clean
	rm -rf composer.phar vendor node_modules

clean:
	rm -rf assets/*.css assets/*.css.gz assets/*.css.br

vendor: composer.lock composer.phar
	COMPOSER_ALLOW_SUPERUSER=1 ./composer.phar install --prefer-dist -vvv

composer.lock: composer.json composer.phar
	COMPOSER_ALLOW_SUPERUSER=1 ./composer.phar update --prefer-dist -vvv

composer.json: composer.json5
	json5 --space=4 --out-file=$@ $<

composer.phar:
	curl -sSL 'https://getcomposer.org/installer' | php -- --stable
	touch -r composer.json $@

node_modules: package-lock.json
	npm install

package-lock.json: package.json
	npm update

.PRECIOUS: %.css
%.css: %.sass node_modules
	npx sass --indented --no-source-map --quiet $< | \
		npx postcss --no-map --use autoprefixer -o $@

.PRECIOUS: %.min.css
%.min.css: %.css node_modules
	npx cleancss -o $@ $<

%.gz: %
	gzip -9 < $< > $@

%.br: %
	brotli --force --best --output=$@ --no-copy-stat $<
