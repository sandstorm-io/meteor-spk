VERSION=0.1.0

meteor-spk.deps: mongo/mongod gather-deps.sh start.js
	@echo "**** Gathering dependencies..."
	./gather-deps.sh

mongo/mongod:
	@echo "**** Building NiscuDB (modified MongoDB)..."
	cd mongo && scons -j6 mongod

dist: meteor-spk-$(VERSION).tar.xz

meteor-spk-$(VERSION).tar.xz: meteor-spk meteor-spk.deps README.md NOTICE
	tar --transform 's,^,meteor-spk-$(VERSION)/,' -Jcf meteor-spk-$(VERSION).tar.xz meteor-spk meteor-spk.deps README.md NOTICE

push: meteor-spk-$(VERSION).tar.xz
	gcutil push fe meteor-spk-$(VERSION).tar.xz /var/www/dl.sandstorm.io/meteor-spk-$(VERSION).tar.xz

clean:
	rm -rf meteor-spk.deps tmp meteor-spk-$(VERSION).tar.xz
	cd mongo && scons -c

.PHONY: dist clean push

