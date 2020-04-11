VERSION=0.5.1
METEOR_VERSION=1.10.1

meteor-spk.deps: mongo/mongod niscu/mongod gather-deps.sh start.js
	@echo "**** Gathering dependencies..."
	./gather-deps.sh $(METEOR_VERSION)

# The following rule is only triggered if the person who
# cloned this repo forgot to clone with "git clone --recursive".
#
# We use "false" to cause make to stop processing.
mongo/SConstruct:
	@echo "**** ERROR: You need to do 'git submodule init; git submodule update' ****"
	@false

mongo/mongod: mongo/SConstruct
	@echo "**** Building MongoDB 3.0 ..."
	cd mongo && scons -j6 mongod --disable-warnings-as-errors

niscu/SConstruct:
	@echo "**** ERROR: You need to do 'git submodule init; git submodule update' ****"
	@false

niscu/mongod: niscu/SConstruct
	@echo "**** Building NiscuDB (modified MongoDB)..."
	cd niscu && scons -j6 mongod --cxx="g++ -Wno-error=unused-variable -Wno-error=strict-overflow" --cc="gcc"

dist: meteor-spk-$(VERSION).tar.xz

meteor-spk-$(VERSION).tar.xz: meteor-spk meteor-spk.deps README.md NOTICE
	tar --transform 's,^,meteor-spk-$(VERSION)/,rSh' -Jcf meteor-spk-$(VERSION).tar.xz meteor-spk meteor-spk.deps README.md NOTICE

push: meteor-spk-$(VERSION).tar.xz
	grep -q "meteor-spk-$(VERSION)[.]tar" README.md
	gce-ss copy-files meteor-spk-$(VERSION).tar.xz fe:/var/www/dl.sandstorm.io/meteor-spk-$(VERSION).tar.xz

clean:
	rm -rf meteor-spk.deps tmp meteor-spk-$(VERSION).tar.xz

reallyclean: clean
	cd mongo && scons -c
	cd niscu && scons -c

.PHONY: dist clean reallyclean push
