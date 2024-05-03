#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec3 aNormal;

out vec3 fragPos;
out vec2 tex_cord;
out vec3 fragNormal;

uniform mat4 proj;
uniform mat4 model;
uniform mat4 view;

void main(){

	gl_Position = proj * view * model * vec4(aPos, 1.0);

    fragPos  = vec3(model * vec4(aPos, 1.0));
	tex_cord = vec2(aTexCoord.x, 1.0 - aTexCoord.y);
    fragNormal = mat3(transpose(inverse(model))) * aNormal;
}
