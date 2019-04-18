@NOTE

For use in SdfFontDesigner
https://github.com/aiekick/SdfFontDesigner/releases

@FRAMEBUFFER SIZE(512,512)

@UNIFORMS

uniform(common) int(frame) 				uFrame;	// frames

uniform(texture) sampler2D(sdf)			uAtlas; // sdf texture
uniform(texture) vec2(sdf)				uAtlasSize; // sdf texture size

uniform(buffers) sampler2D(buffer:target=0) uGrayScottBuffer; // grayscott buffer ping pong
uniform(buffers) vec2(buffer:target=uGrayScottBuffer) uSize;
uniform(buffers) sampler2D(buffer:target=1) uColorBuffer; // grayscott buffer ping pong

uniform(common) int(frame) uFrame;	// frames
uniform(common) float(time) uTime;	// time

uniform(mouse) vec4(mouse:normalized_2pos_2click)	mouse;

uniform(pattern) int(combobox:custom,base,solitons,movitons,worms) uPattern; 
// solitons 0.03,0.062)
// worms 0.078,0.061
// base 0.037, 0.06
// movitons 0.014, 0.054

uniform(grayscott:0) float(0:0.2:0.04) uFeed;
uniform(grayscott:1) float(0:0.2:0.063) uKill;
uniform(shape) float(1:200:2) radius;

uniform vec3(color:1.0,0.0,0.0) color;
uniform float(0:20:0.7) colorScale;

@VERTEX

#extension GL_ARB_explicit_attrib_location : enable
layout(location = 0) in vec2 a_position; // Current vertex position

void main()
{
	gl_Position = vec4(a_position, 0.0, 1.0);
}

@FRAGMENT

#extension GL_ARB_explicit_attrib_location : enable
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 fragColor1;

float median(vec3 rgb) 
{
    return max(min(rgb.r, rgb.g), min(max(rgb.r, rgb.g), rgb.b)); // https://github.com/Chlumsky/msdfgen
}

vec2 fra(vec2 p, vec2 o, vec2 s)
{
	p = (p+o)/s;//-0.25;
	return fract(p);
	return abs(p);
	return fract(p)-0.5;//+0.25;
}

void main()
{
	#define USER_DEFINED_MAIN_FONT_MAP

	vec2 g = gl_FragCoord.xy;
	vec2 s = uSize;
	vec2 uv = g / s;
	
	// gray scott
	if (uFrame < 1)
	{
		fragColor = vec4(0.9,0,0,1);
	}
	else
	{
		float feedRate = 0.0;
		float killRate = 0.0;
		if (uPattern == 0) // custom
		{
			feedRate = uFeed;
			killRate = uKill;
		}
		else if (uPattern == 1) // base
		{
			// base 0.037, 0.06
			feedRate = 0.037;
			killRate = 0.06;
		}
		else if (uPattern == 2) // solitons
		{
			// solitons 0.03,0.062
			feedRate = 0.03;
			killRate = 0.062;
		}
		else if (uPattern == 3) // movitons
		{
			// movitons 0.014, 0.054
			feedRate = 0.014;
			killRate = 0.054;
		}
		else if (uPattern == 4) // worms
		{
			// worms 0.078,0.061
			feedRate = 0.078;
			killRate = 0.061;
		}
				
		vec4 c = texture(uGrayScottBuffer, fra(g, vec2(0), s));
		
		vec4 l = texture(uGrayScottBuffer, fra(g, vec2(-1,0), s));
		vec4 r = texture(uGrayScottBuffer, fra(g, vec2(1,0), s));
		vec4 b = texture(uGrayScottBuffer, fra(g, vec2(0,-1), s));
		vec4 t = texture(uGrayScottBuffer, fra(g, vec2(0,1), s));
		
		vec2 ab = c.rg;
		vec4 lp = l + r + t + b - c * 4.0;
		
		vec2 uvc =  uv * 2. - 1.;
		
		float d = length(uvc);
		uvc += vec2(cos(d * 3.14159 + uTime),sin(d * 3.14159 * uTime)) * d;
		d = length(uvc);
		 
		//feedRate *= d * 2.0;
		//killRate *= d * 2.0;
		
		float rea = ab.x * ab.y * ab.y;
		vec2 di = vec2(0.2,0.1) * lp.xy;
		float feed = feedRate * (1. - ab.x);
		float kill = (feedRate + killRate) * ab.y;
		ab += di + vec2(feed - rea, rea - kill);
		
		fragColor = vec4(clamp(ab,-1.,1.),0.0, 1.0);
	}
	
	if (mouse.z > 0.)
	{
		vec2 p = uv - mouse.xy;
		p.x *= s.x/s.y;
		
		if (length(p) < radius / s.x)
		{	
			fragColor = vec4(0.1,0.9,0.1,1);
		}
	}
	
	float a = fragColor.r * fragColor.r * 2.;
	fragColor1.rgb = sin(fragColor.r * color * colorScale)*.5+.5;
	fragColor1.a = 1.0;
}