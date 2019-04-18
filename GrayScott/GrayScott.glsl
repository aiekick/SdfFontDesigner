@NOTE

For use in SdfFontDesigner
https://github.com/aiekick/SdfFontDesigner/releases

@UNIFORMS

//uncomment these buffers i you want to have multipass or multi fbo attachments feature 
uniform(buffers) sampler2D(buffer:target=1:file=GrayScottBuffer) uGrayScottBuffer; // grayscott buffer ping pong
uniform(buffers) sampler2D(buffer:target=1) uPatternBuffer; // for construct attachment 1
uniform(buffers) sampler2D(buffer:target=2) uLightedBuffer; // for construct attachment 1
//uniform(buffers) sampler2D(buffer:target=2) uBuffer2; // back buffer 2, filled with fragColor2 (target 2)
//uniform(buffers) sampler2D(buffer:target=3) uBuffer3; // back buffer 3, filled with fragColor3 (target 3)
//uniform(buffers) sampler2D(buffer:target=4) uBuffer4; // back buffer 4, filled with fragColor4 (target 4)
//uniform(buffers) sampler2D(buffer:target=5) uBuffer5; // back buffer 5, filled with fragColor5 (target 5)
//uniform(buffers) sampler2D(buffer:target=6) uBuffer6; // back buffer 6, filled with fragColor6 (target 6)
//uniform(buffers) sampler2D(buffer:target=7) uBuffer7; // back buffer 7, filled with fragColor7 (target 7)

uniform(sdf) float(0.0:0.1:0.1) 		uSmoothing; // smooth edge
uniform(sdf) float(0.0:0.4:0.2) 		uOutlineWidth; // border line thickness

//uniform(common) int(frame) 			uFrame;	// frames
uniform(common) float(time) 			uTime; // time

uniform(texture) sampler2D(sdf)			uAtlasBuffer; // sdf texture
uniform(texture) vec2(sdf)				uAtlasBufferSize; // sdf texture size

uniform(glyph) vec2(glyphpadding) 		uGlyphPadding; // global glyphs padding
uniform(glyph) int(glyphcount) 			uCountGlyphs; // count glyphs
uniform(glyph) float(glyphinversions) 	uGlyphInversions[glyphcount]; // glyph inversion ( true is > 0.5, false < 0.5)
uniform(glyph) vec4(glyphrects) 		uGlyphRects[glyphcount]; // glyph rects : left, bottom, right, top
uniform(glyph) vec2(glyphcenter) 		uGlyphCenterOffsets[glyphcount]; // glyph center offset : x,y on range 0,0 to 1,1, default is center 0.5,0.5

uniform(color) vec3(color:1,0,0)		colorStart; // start filling color
uniform(color) vec3(color:0.0,1,0.463)	colorEnd; // end filling color

uniform(light) float(0.0:6.28318:0.) 	uLightPos;
uniform(light) float(0.0:0.01:0.005) 	uLight;
uniform(light) vec3(color:1) 			uLightColor;
uniform(light) float(0.0:20.0:12.0) 	uBrightNess;

uniform float(0:5:1) scale;

@FRAGMENT

float median(vec3 rgb) 
{
    return max(min(rgb.r, rgb.g), min(max(rgb.r, rgb.g), rgb.b)); // https://github.com/Chlumsky/msdfgen
}

vec2 cell(vec2 fragCoord, vec2 pixel, vec2 dir, float scale, sampler2D sam, vec2 size)
{
    pixel *= dir;
    
    // remove screen border of domain
    if (fragCoord.x + pixel.x > size.x) fragCoord.x = 0.;
    if (fragCoord.y + pixel.y > size.y) fragCoord.y = 0.;
    if (fragCoord.x + pixel.x < 0.0) fragCoord.x = size.x;
    if (fragCoord.y + pixel.y < 0.0) fragCoord.y = size.y;
    
	vec2 uv = (fragCoord + pixel) / size.xy;
    return texture(sam, uv).rg * scale;
}

void mainFontMap(vec2 fragCoord)
{
	#define USER_DEFINED_MAIN_FONT_MAP

	vec2 g = fragCoord;
	vec2 s = uAtlasSize;
	vec2 uv = fragCoord / uAtlasBufferSize;
	vec4 font = texture(uAtlasBuffer, uv);			// font map			
	
	float glyphSdf = median(font.rgb);
	
	/////////////////////////////////////////////////////////
	
	fragColor = texture(uGrayScottBuffer, fract(g/s));
	
	/////////////////////////////////////////////////////////
	
	float cc = texture(uGrayScottBuffer, fract(g/s)).r;
    float cc2 = texture(uGrayScottBuffer, fract((g+1.)/s)).r;
    
	float sdf = median(font.rgb);
		
   	fragColor1 = vec4(cc*cc);
   	fragColor1 += vec4(.5, .2, 1,1)*max(cc2*cc2*cc2 - cc*cc*cc, 0.0)*s.y*.2;
   	fragColor1 = fragColor1 * .2 + fragColor1.grba * .3;
	fragColor1 /= fragColor.g*fragColor.g*2.0;
	fragColor1 *= sdf;
	fragColor1.a = fragColor.g;
	
	/////////////////////////////////////////////////////////
	
	float a = uTime + uLightPos;
	vec2 ld = vec2(cos(a),sin(a)) * uLight;
	
	float d0 = texture(uPatternBuffer, g/s).r;
	float d1 = texture(uPatternBuffer, (g+ld)/s).r;
	
	float b = max(d1 - d0, 0.) * uBrightNess;
	
	// put char between [[ and ]] for adapt your shader for a particular char
	// example with the char c, we want to inverse here the sdf only for the char c
	// if (glyphIndex == [[c]])	glyphSdf = 1. - glyphSdf;
			 
	float smoothing = uSmoothing;
	float outlineWidth = uOutlineWidth;
	float outerEdgeCenter = 0.5 - outlineWidth;

	float alpha = smoothstep(outerEdgeCenter - smoothing, outerEdgeCenter + smoothing, d0);
	float border = smoothstep(0.5 - smoothing, 0.5 + smoothing, d0);

	fragColor2 = vec4(
		mix(
			colorEnd, 
			colorStart * d0 + uLightColor * (b*b*0.04 + b*0.1), 
			border),
		alpha);
}