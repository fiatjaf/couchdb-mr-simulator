all:
	./node_modules/.bin/webpack main.coffee main.js
run:
	make
	python -m SimpleHTTPServer 3000
