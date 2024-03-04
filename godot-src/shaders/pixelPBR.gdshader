// Color-to-material shader for pixel-PBR style.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,diffuse_burley,specular_schlick_ggx;

const int MAX_MATERIALS = 8; // CAN BE as big as 64, but ideally keep as small as possible
const float alpha_scissor_threshold = 0.5;

//uniform bool allow_transparency = true;
uniform float texture_scale = 1.0; // scale the secondary textures, NOTE: INVERTED
uniform bool use_material_normals = false;
uniform bool use_world_coords = false;

// To turn off the material sampling and just use albedo/normal map:
uniform bool webgl_mode = false;
// (This basically defeats the point of the shader,
//  but it shows what a non-materials version would look like,
//  so possibly useful if you want to simultaneously develop
//  both versions, e.g. to support web.  Also does not actually
//  run in webgl, since the shader still won't compile, so it's mostly
//  just useful for developing the shader)

// Note: we do NOT use source_color hint on texture albedo, to insure that colours are loaded
//  unmodified in sRGB space.
//  This means the albedos will not look quite right if actually displayed, so
//  make sure to set a material for every material index.
uniform sampler2D material_map: /*source_color,*/filter_nearest,repeat_enable;
uniform sampler2D normal_map: hint_normal,filter_nearest;

// Details of the various textures
uniform sampler2D albedos[MAX_MATERIALS] : source_color;
uniform sampler2D roughnesses[MAX_MATERIALS];
uniform sampler2D normalmaps[MAX_MATERIALS]; // optional

varying vec2 UV3;

// Get a new basis for tangent space that is guaranteed to be shared across all faces
//   that have the same normal.  To ensure texture normal maps work properly, you need to ensure that
//   the tangent space as understood by Godot matches the space in which you're sampling
//   the normal map.
//   (i.e. we return v1 and v2, set TANGENT to v1 and then use v1 as UV X and v2 as UV y)
// Also, make sure to import normal map w/ lossless compression, or you get artifacts
vec3[2] standardized_tangentspace_basis(vec3 normal, vec3 point) {
	vec3 other_vector = vec3(0.0,1.0,0.0); // So that walls appear right-side up
	if (length(normal - other_vector) < 0.01) {
		other_vector = vec3(0.0,0.0,1.0); // Flat surfaces have "up" away from player
	}
	vec3 v1 = other_vector - normal * dot(other_vector,normal);
	vec3 v2 = cross(v1,normal);
	return {normalize(v1),normalize(v2)};
}

void vertex() {
	vec3 normal = NORMAL;
	vec3 position = VERTEX;
	if (use_world_coords){
		position = (MODEL_MATRIX * vec4(VERTEX, 0.0)).xyz;
		normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	}
	vec3 basis[2] = standardized_tangentspace_basis(normal,position);
	if (use_material_normals) {
		TANGENT = basis[0]; // Don't need to set binormal, it's calculated from normal + tangent
	}
	// Calculate alternate UV coords (project from model/world space to new tangent space):
	UV3 = vec2(dot(position,basis[0]), dot(position,basis[1])) / texture_scale;
}

// No longer used (we don't iterate over a list of colours to match anymore),
//  but I'm leaving it in, in case I change my mind.
/*
bool colors_match(vec3 c1, vec3 c2) {
	return length(c1 - c2) < 0.01;
}*/

// Given a colour, extract an integer index from the least significant 2 bits
//  of each channel (red least-significant, green most-significant).
int index_from_color(vec3 color) {
	ivec3 c = ivec3(round(255.0*color)) % 4;
	return c.r + c.g*4 + c.b*16;
}

void fragment() {
	vec4 material_color = texture(material_map,UV);
	ALBEDO = material_color.rgb; // (ONLY intended as a failsafe/fallback)
	ALPHA *= material_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	NORMAL_MAP = texture(normal_map,UV).rgb;
	
	int material_index = index_from_color(material_color.rgb);
	if (material_index < MAX_MATERIALS && !webgl_mode){
		// TODO Allow optional metalness maps
		// TODO Implement emission, probably as a multiplier on albedo (maybe make this toggleable?)
		vec4 sampled_albedo = texture(albedos[material_index],UV3);
		ALBEDO = sampled_albedo.rgb;
		ROUGHNESS = texture(roughnesses[material_index],UV3).x;
		if (use_material_normals) {
			NORMAL_MAP = texture(normalmaps[material_index],UV3).rgb;
		}
	}
}
