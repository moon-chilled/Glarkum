use glarkum;
use NativeCall;
use SDL2::Raw;

constant VERT-SRC = q:to/EOF/;
#version 330 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec4 clr;
out vec4 oclr;
void main() {
       oclr = clr;
       gl_Position = vec4(pos.xyz, 1);
}
EOF

constant FRAG-SRC = q:to/EOF/;
#version 330 core
in vec4 oclr;
out vec4 colour;
void main() {
	colour = oclr;
}
EOF

sub gl-log(GLenum $source, GLenum $type, GLuint $id, GLenum $severity, GLsizei $length, Str $message, Pointer $user-data) {
	say "OpenGL: $message"
}

sub MAIN {
	my $win = SDL_CreateWindow("TA", SDL_WINDOWPOS_UNDEFINED_MASK, SDL_WINDOWPOS_UNDEFINED_MASK, 640, 480, SHOWN +| OPENGL);
	die unless $win;
	SDL_GL_SetAttribute CONTEXT_MAJOR_VERSION, 4;
	SDL_GL_SetAttribute CONTEXT_MINOR_VERSION, 5;
	SDL_GL_SetAttribute CONTEXT_PROFILE_MASK, CONTEXT_PROFILE_CORE;
	die unless SDL_GL_CreateContext $win;
	die unless load-gl-procs;
	say "GL version {glGetString(GL_VERSION)}";
	# https://github.com/Raku/problem-solving/issues/96
	#glEnable(GL_DEBUG_OUTPUT);
	#glDebugMessageCallback(&gl-log, Pointer);

	my @vertices := CArray[num32].new(
		-1e0, -1e0, 0e0, 0e0, 0e0, 1e0, 1e0,
		 1e0, -1e0, 0e0, 0e0, 1e0, 0e0, 1e0,
		 0e0,  1e0, 0e0, 1e0, 0e0, 0e0, 1e0);

	my @vao := CArray[GLuint].allocate(1);
	my @vbo := CArray[GLuint].allocate(1);
	my GLuint $program;
	glCreateVertexArrays(1, @vao);
	my $vao = @vao[0];
	glCreateBuffers(1, @vbo);
	my $vbo = @vbo[0];

	glVertexArrayVertexBuffer($vao, 0, $vbo, 0, 7 * nativesizeof(num32));

	glEnableVertexArrayAttrib($vao, 0);
	glVertexArrayAttribBinding($vao, 0, 0);
	glVertexArrayAttribFormat($vao, 0, 3, GL_FLOAT, GL_FALSE, 0 * nativesizeof(num32));

	glEnableVertexArrayAttrib($vao, 1);
	glVertexArrayAttribFormat($vao, 1, 4, GL_FLOAT, GL_FALSE, 3 * nativesizeof(num32));
	glVertexArrayAttribBinding($vao, 1, 0);

	glNamedBufferData($vbo, 21 * nativesizeof(num32), nativecast(Pointer, @vertices), GL_STATIC_DRAW);

	{
		my @success := CArray[GLint].allocate(1);
		my GLuint $vert = glCreateShader(GL_VERTEX_SHADER);
		my GLuint $frag = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource($vert, 1, CArray[Str].new(VERT-SRC), CArray[GLint].new(VERT-SRC.encode.bytes));
		glCompileShader($vert);
		glGetShaderiv($vert, GL_COMPILE_STATUS, @success); die unless @success[0];
		glShaderSource($frag, 1, CArray[Str].new(FRAG-SRC), CArray[GLint].new(FRAG-SRC.encode.bytes));
		glCompileShader($frag);
		glGetShaderiv($frag, GL_COMPILE_STATUS, @success); die unless @success[0];
		$program = glCreateProgram;
		glAttachShader($program, $vert);
		glAttachShader($program, $frag);
		glLinkProgram($program);
		glGetProgramiv($program, GL_LINK_STATUS, @success); die unless @success[0];
		glDeleteShader($vert);
		glDeleteShader($frag);
	}

	glClearColor 0e0, 0e0, 0e0, 1e0;
	glUseProgram $program;
	glBindVertexArray $vao;

	my SDL_Event $ev = SDL_Event.new;
	loop {
		while SDL_PollEvent($ev) { return if $ev.type == QUIT }
		glClear GL_COLOR_BUFFER_BIT;
		glDrawArrays GL_TRIANGLES, 0, 3;
		SDL_GL_SwapWindow $win;
	}
}
