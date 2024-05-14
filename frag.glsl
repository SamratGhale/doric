#version 450 core

in vec3 fragPos;
in vec2 tex_cord;
in vec3 fragNormal;

out vec4 frag_color;

uniform sampler2D tex;
uniform vec4 colDiffuse;

uniform bool      is_tex;

#define MAX_LIGHTS        10
#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT       1

struct Light {
  int enabled;
  int type;
  vec3 pos;
  vec3 target;
  vec4 color;
};


uniform Light lights[MAX_LIGHTS];
uniform bool light_on;
uniform vec4  ambient;

//This is camera position
uniform vec3  viewPos;


void main(){
  if(is_tex){
    vec4 tex_color = texture(tex, tex_cord);

    vec3 diffuse = vec3(0.0);
    vec3 viewD = normalize(viewPos - fragPos);
    vec3 specular = vec3(0.0);

    //diffuse 
    vec3 normal = normalize(fragNormal);



    for (int i = 0; i < MAX_LIGHTS; i++){

      if(lights[i].enabled == 1 && light_on){

        vec3 lightDir = vec3(0.0);

        if(lights[i].type == LIGHT_DIRECTIONAL)
        {
          lightDir = -normalize(lights[i].target - lights[i].pos);
        }

        if(lights[i].type == LIGHT_POINT)
        {
          lightDir = normalize(lights[i].pos - fragPos);
        }

        float NdotL  = max(dot(normal, lightDir), 0.0);

        diffuse += lights[i].color.rgb * NdotL;


        float specCo = 0.0;
        if (NdotL > 0.0) specCo = pow(max(0.0, dot(viewD, reflect(-(lightDir), normal))), 32.0) ; // 16 refers to shine

        specular += specCo ;
      }
    }

    //frag_color = (tex_color * ((vec4(specular, 1.0)) * vec4(lightDot, 1.0)));
    //frag_color += tex_color * (ambient/10.0) ;

    //ambient
    vec4 ambient_color = (ambient/5.0) ;

    //frag_color = pow(frag_color, vec4(1.0/2.2));
    if(light_on){
      frag_color = (ambient_color + vec4(diffuse, 1.0) + vec4(specular, 1.0)) * tex_color;
    }else{
      frag_color = tex_color;
    }


    if(tex_color.a < 0.1)
      discard;
    //frag_color = tex_color;
  }else{
    frag_color = vec4(1.0, 1.0, 0, 1.0);
  }
}
