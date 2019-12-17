LOCAL_BIKESHED := $(shell command -v bikeshed 2> /dev/null)

.PHONY: dirs

all: dirs index.html

dirs: out

out:
	mkdir -p out

index.html: index.bs
ifndef LOCAL_BIKESHED
	curl https://api.csswg.org/bikeshed/ -F file=@index.bs -F output=err
	curl https://api.csswg.org/bikeshed/ -F file=@index.bs -F force=1 > out/index.html | tee
else
	bikeshed spec index.bs out/index.html
endif
