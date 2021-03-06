# no static linking for macos
LDFLAGS := -ldflags '-s'
# statically link binaries (to support alpine + scratch containers)
STATICLDFLAGS := -ldflags '-s -extldflags "-static"'
# avoid building code that is incompatible with static linking
TAGS := -tags netgo,osusergo,sqlite_omit_load_extension

.PHONY: all
all: build lint test

.PHONY: test
test:
	go test -v $(TAGS) $(STATICLDFLAGS) ./...

.PHONY: fix
fix:
	golangci-lint run --fix

.PHONY: lint
lint:
	golangci-lint run

.PHONY: wait
wait:
	dist/dbmate-linux-amd64 -e MYSQL_URL wait
	dist/dbmate-linux-amd64 -e POSTGRESQL_URL wait
	dist/dbmate-linux-amd64 -e CLICKHOUSE_URL wait

.PHONY: clean
clean:
	rm -rf dist/*

.PHONY: build
build: clean build-linux-amd64
	ls -lh dist

.PHONY: build-linux-amd64
build-linux-amd64:
	GOOS=linux GOARCH=amd64 \
	     go build $(TAGS) $(STATICLDFLAGS) -o dist/dbmate-linux-amd64 .

.PHONY: build-all
build-all: clean build-linux-amd64
	GOOS=linux GOARCH=arm64 CC=aarch64-linux-gnu-gcc-5 CXX=aarch64-linux-gnu-g++-5 \
	     go build $(TAGS) $(STATICLDFLAGS) -o dist/dbmate-linux-arm64 .
	GOOS=darwin GOARCH=amd64 CC=o64-clang CXX=o64-clang++ \
	     go build $(TAGS) $(LDFLAGS) -o dist/dbmate-macos-amd64 .
	GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc-posix CXX=x86_64-w64-mingw32-g++-posix \
	     go build $(TAGS) $(STATICLDFLAGS) -o dist/dbmate-windows-amd64.exe .
	ls -lh dist

.PHONY: docker-make
docker-make:
	docker-compose build
	docker-compose run --rm dbmate make

.PHONY: docker-bash
docker-bash:
	-docker-compose run --rm dbmate bash
