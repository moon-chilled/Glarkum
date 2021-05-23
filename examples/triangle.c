#include <assert.h>
#include <stdio.h>

#include <SDL2/SDL.h>
#include "glad/glad.h"

static const char vert_source[] = 
"#version 330 core\n"
"layout (location = 0) in vec3 pos;\n"
"layout (location = 1) in vec4 clr;\n"
"out vec4 oclr;\n"
"void main() {\n"
"	oclr = clr;\n"
"	gl_Position = vec4(pos.xyz, 1);\n"
"}";
static const char frag_source[] =
"#version 330 core\n"
"in vec4 oclr;\n"
"out vec4 colour;\n"
"void main() {\n"
"	colour = oclr;\n"
"}";

void gl_log(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message, const void *userParam) {
	printf("OpenGL: %s\n", message);
}


int main() {

	SDL_Window *win = SDL_CreateWindow("TA", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);
	assert(win);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 5);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	assert(SDL_GL_CreateContext(win));
	assert(gladLoadGL());
	printf("GL version %s\n", glGetString(GL_VERSION));
	glEnable(GL_DEBUG_OUTPUT);
	glDebugMessageCallback(&gl_log, NULL);

	float vertices[] = {
		-1, -1, 0, 0, 0, 1, 1,
		 1, -1, 0, 0, 1, 0, 1,
		 0,  1, 0, 1, 0, 0, 1,
	};

	GLuint vao, vbo, program;
	glCreateVertexArrays(1, &vao);
	glCreateBuffers(1, &vbo);

	glVertexArrayVertexBuffer(vao, 0, vbo, 0, 7 * sizeof(float));

	glEnableVertexArrayAttrib(vao, 0);
	glVertexArrayAttribBinding(vao, 0, 0);
	glVertexArrayAttribFormat(vao, 0, 3, GL_FLOAT, GL_FALSE, 0 * sizeof(float));

	glEnableVertexArrayAttrib(vao, 1);
	glVertexArrayAttribFormat(vao, 1, 4, GL_FLOAT, GL_FALSE, 3 * sizeof(float));
	glVertexArrayAttribBinding(vao, 1, 0);

	glNamedBufferData(vbo, sizeof(vertices), vertices, GL_STATIC_DRAW);

	{
		GLint success;
		GLuint vert = glCreateShader(GL_VERTEX_SHADER), frag = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(vert, 1, &(const char*){vert_source}, &(GLint){sizeof(vert_source)});
		glCompileShader(vert);
		glGetShaderiv(vert, GL_COMPILE_STATUS, &success); assert(success);
		glShaderSource(frag, 1, &(const char*){frag_source}, &(GLint){sizeof(frag_source)});
		glCompileShader(frag);
		glGetShaderiv(frag, GL_COMPILE_STATUS, &success); assert(success);
		program = glCreateProgram();
		glAttachShader(program, vert);
		glAttachShader(program, frag);
		glLinkProgram(program);
		glGetProgramiv(program, GL_LINK_STATUS, &success); assert(success);
		glDeleteShader(vert);
		glDeleteShader(frag);
	}

	glClearColor(0, 0, 0, 1);
	glUseProgram(program);
	glBindVertexArray(vao);

	while (1) {
		SDL_Event ev;
		while (SDL_PollEvent(&ev)) if (ev.type == SDL_QUIT) return 0;
		glClear(GL_COLOR_BUFFER_BIT);

		glDrawArrays(GL_TRIANGLES, 0, 3);

		SDL_GL_SwapWindow(win);
	}
}
