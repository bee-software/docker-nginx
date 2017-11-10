all: clean test

clean:

compose_environment:
	docker-compose up -d --build
	sleep 1

test: compose_environment
	./test.sh
