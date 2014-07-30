meteor-bundle.deps: mongo/mongod gather-deps.sh start.js
	@echo "**** Gathering dependencies..."
	./gather-deps.sh

mongo/mongod:
	@echo "**** Building NiscuDB (modified MongoDB)..."
	cd mongo && scons -j6 mongod

clean:
	rm -rf meteor-spk.deps tmp
	cd mongo && scons -c

