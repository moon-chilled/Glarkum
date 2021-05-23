O := triangle.o glad/glad.o

triangle: $(O)
	$(CC) -o triangle $(O) -lSDL2 -ldl -Iglad
clean:
	rm -f triangle $(O)
