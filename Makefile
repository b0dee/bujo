install:
	cp -f bujo.sh /usr/local/bin/bujo
	cp -f completion.sh /usr/share/bash-completion/completions/bujo

dev:
	ln -f -s $(shell pwd)/bujo.sh /usr/local/bin/bujo
	ln -f -s $(shell pwd)/completion.sh /usr/share/bash-completion/completions/bujo

