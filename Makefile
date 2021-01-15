LOCAL_BIKESHED := $(shell command -v bikeshed 2> /dev/null)

.PHONY: all index.html

all: index.html

index.html: index.bs
ifndef LOCAL_BIKESHED
	curl https://api.csswg.org/bikeshed/ -F file=@index.bs -F output=err
	curl https://api.csswg.org/bikeshed/ -F file=@index.bs -F force=1 > index.html | tee
else
	bikeshed spec index.bs index.html
endif
