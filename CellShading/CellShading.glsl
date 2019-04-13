
@UNIFORMS

//uncomment these buffers i you want to have multipass or multi fbo attachments feature 
//uniform(buffers) sampler2D(buffer:target=0) uBuffer0; // back buffer 0, filled with fragColor (target 0)
//uniform(buffers) sampler2D(buffer:target=1) uBuffer1; // back buffer 1, filled with fragColor1 (target 1)
//uniform(buffers) sampler2D(buffer:target=2) uBuffer2; // back buffer 2, filled with fragColor2 (target 2)
//uniform(buffers) sampler2D(buffer:target=3) uBuffer3; // back buffer 3, filled with fragColor3 (target 3)
//uniform(buffers) sampler2D(buffer:target=4) uBuffer4; // back buffer 4, filled with fragColor4 (target 4)
//uniform(buffers) sampler2D(buffer:target=5) uBuffer5; // back buffer 5, filled with fragColor5 (target 5)
//uniform(buffers) sampler2D(buffer:target=6) uBuffer6; // back buffer 6, filled with fragColor6 (target 6)
//uniform(buffers) sampler2D(buffer:target=7) uBuffer7; // back buffer 7, filled with fragColor7 (target 7)

uniform(sdf) float(0.0:0.1:0.1) 		uSmoothing; // smooth edge
uniform(sdf) float(0.0:0.4:0.4) 		uOutlineWidth; // border line thickness

uniform(common) int(frame) 				uFrame;	// frames
uniform(common) float(time) 			uTime; // time

uniform(texture) sampler2D(sdf)			uAtlas; // sdf texture
uniform(texture) vec2(sdf)				uAtlasSize; // sdf texture size

uniform(glyph) vec2(glyphpadding) 		uGlyphPadding; // global glyphs padding
uniform(glyph) int(glyphcount) 			uCountGlyphs; // count glyphs
uniform(hidden) float(glyphinversions) 	uGlyphInversions[glyphcount]; // glyph inversion ( true is > 0.5, false < 0.5)
uniform(hidden) vec4(glyphrects) 		uGlyphRects[glyphcount]; // glyph rects : left, bottom, right, top
uniform(hidden) vec2(glyphcenter) 		uGlyphCenterOffsets[glyphcount]; // glyph center offset : x,y on range 0,0 to 1,1, default is center 0.5,0.5

uniform(uv) float(checkbox:false) 		canTuneUVCenters;

uniform(color) vec3(color:0)			uColorStart; // start filling color
uniform(color) vec3(color:1)			uColorEnd; // end filling color

uniform(light) float(0.0:6.28318:0.) 	uLightPos;
uniform(light) float(0.0:0.01:0.005) 	uLight;
uniform(light) vec3(color:1) 			uLightColor;
uniform(light) float(0.0:20.0:12.0) 	uBrightNess;

@FRAGMENT

// https://github.com/Chlumsky/msdfgen
float median(vec3 rgb) 
{
    return max(min(rgb.r, rgb.g), min(max(rgb.r, rgb.g), rgb.b));
}

void mainGlyph(in int glyphIndex, in vec2 glyphCoord, in vec2 glyphSize, in vec2 texCoord, in vec2 texSize)
{
	float a = uTime + uLightPos;
	vec2 ld = vec2(cos(a),sin(a));
	if (canTuneUVCenters > 0.5)
		ld -= uGlyphCenterOffsets[glyphIndex] - 0.5;
	ld *= uLight;
	
	vec2 uvTex = texCoord / texSize;
	
	//vec4 font0 = texture(uAtlas, uvTex);
	//vec4 font1 = texture(uAtlas, uvTex + ld);
				
	if (uGlyphInversions[glyphIndex] > 0.5)
	{
		font0 = 1.0 - font0;
		font1 = 1.0 - font1;
	}	
			
	float d0 = median(font0.rgb);
	float d1 = median(font1.rgb);
		
	float b = max(d1 - d0, 0.) * uBrightNess;
	
	// put char between [[ and ]] for adapt your shader for a particular char
	// example with the char c, we want to inverse here the sdf only for the char c
	// if (glyphIndex == [[c]])	glyphSdf = 1. - glyphSdf;
			 
	float smoothing = uSmoothing;
	float outlineWidth = uOutlineWidth;
	float outerEdgeCenter = 0.5 - outlineWidth;

	float alpha = smoothstep(outerEdgeCenter - smoothing, outerEdgeCenter + smoothing, d0);
	float border = smoothstep(0.5 - smoothing, 0.5 + smoothing, d0);

	vec4 col = vec4(
		mix(
			uColorEnd, 
			uColorStart * d0 + uLightColor * (b*b*0.04 + b*0.1), 
			border),
		alpha);

	fragColor = col; // attachment 0, you have alos fragColor1 to 7
}
