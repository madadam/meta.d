TEST = rdmd -unittest -w --main

test:
	$(TEST) adapter.d
	$(TEST) attribute.d
