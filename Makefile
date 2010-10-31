test:
	rdmd -unittest -w --main adapter.d
	rdmd -unittest -w --main import_test.d
