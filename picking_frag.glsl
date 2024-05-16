#version 450

in vec2 tex_cord;
uniform sampler2D tex;

uniform uint obj_index;
uniform uint draw_index;

out uvec3 FragColor;
void main(){
  vec4 tex_color = texture(tex, tex_cord);
  FragColor = uvec3(obj_index, draw_index, gl_PrimitiveID);
  if(tex_color.a < 0.1)
    discard;
}
