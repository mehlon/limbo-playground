run:
	plumb http://localhost:8080/magic/kek
	docker run -p 8080:8080 -it mehlon/kek
build:
	docker build -t mehlon/kek .
publish:
	docker push mehlon/kek

