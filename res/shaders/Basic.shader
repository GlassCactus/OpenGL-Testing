#shader vertex
#version 330 core

layout(location = 0) in vec3 aPos; //This refers to their index in the AttribPointer
layout(location = 1) in vec3 aNormal; //The normal vectors 
layout(location = 2) in vec2 aTex; //Texture coordinates

out vec3 FragPos;
out vec3 Normal;
out vec2 Tex;

uniform mat4 normalMat;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
	FragPos = vec3(model * vec4(aPos, 1.0f)); //position of the target box (orange boi)
	Tex = aTex;
	gl_Position = projection * view * vec4(FragPos, 1.0f);
	
	Normal = normalize(mat3(normalMat) * aNormal);
}

//-----------------------------------------------------------------------------------------------//

#shader fragment
#version 330 core

out vec4 FragColor;

in vec3 FragPos;
in vec3 Normal;
in vec2 Tex;

struct Material
{
	sampler2D diffuse;
	sampler2D specular;
	vec3 ambient;
	float shine;
};

struct Light
{
	vec3 position;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float attConst;
	float attLinear;
	float attQuad;
};

struct DirLight
{
	vec3 direction;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

uniform Material material;
uniform Light light;
uniform DirLight dirLight;
uniform vec3 boxColor;
uniform vec3 luminosity;
uniform vec3 lightPos;
uniform vec3 viewPos;


vec3 CalculateDirLight(DirLight sunlight, vec3 normal, vec3 viewDir)
{
	vec3 lightDir = normalize(-sunlight.direction);
	float diff = max(dot(normal, lightDir), 0.0f);
	vec3 reflectDir = reflect(-lightDir, normal);
	float spec = max(dot(viewDir, reflectDir), 0.0f);

	vec3 ambience = sunlight.ambient *	texture(material.diffuse, Tex).rgb;
	vec3 diffuse = sunlight.diffuse * diff * texture(material.diffuse, Tex).rgb;
	vec3 specular = sunlight.specular * spec * texture(material.specular, Tex).rgb;

	return (ambience + diffuse + specular);
}


void main()
{
	float distance = length(light.position - FragPos);
	float attenuation = 1 / (light.attConst + (light.attLinear * distance) + (light.attQuad * distance * distance));

	//ambient
	vec3 ambience = light.ambient * luminosity * texture(material.diffuse, Tex).rgb; //combines the light's ambience and the material's texture as an "ambience"
	ambience *= attenuation;

	//diffuse
	vec3 lightDir = normalize(lightPos - FragPos); //direction vector of the light
	float diff = max(dot(Normal, lightDir), 0.0f); 
	vec3 diffuse = light.diffuse * luminosity * diff * texture(material.diffuse, Tex).rgb;
	diffuse *= attenuation;

	//specular
	vec3 viewDir = normalize(viewPos - FragPos);
	vec3 reflectDir = reflect(-lightDir, Normal);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0f), material.shine);
	vec3 specular = light.specular * luminosity * spec * texture(material.specular, Tex).rgb;
	specular *= attenuation;

	//phong!!!
	vec3 phong = (ambience + diffuse + specular) * boxColor;
	FragColor = vec4(phong + CalculateDirLight(dirLight, Normal, viewDir), 1.0f);
}