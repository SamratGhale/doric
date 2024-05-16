#version 450

layout (location = 0) in vec3 Position;
layout (location = 1) in vec3 aTexCoord;
layout (location = 2) in vec3 aNormal;

out vec2 tex_cord;
uniform mat4 MVP;

void main(){
		 gl_Position = MVP * vec4(Position, 1.0);
		 tex_cord = vec2(aTexCoord.x, 1.0 - aTexCoord.y);
}
