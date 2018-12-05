.PHONY: all test

all: test

test:
	tests/00_sni/test.sh
	tests/01_timeouts/test.sh
	tests/02_redirects/test.sh
	tests/03_hsts/test.sh
	tests/04_reverse_proxy_headers/test.sh
	tests/05_frontend_url/test.sh
	tests/06_basic_auth/test.sh