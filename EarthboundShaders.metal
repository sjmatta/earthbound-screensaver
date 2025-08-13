#include <metal_stdlib>
using namespace metal;

struct DistortionUniforms {
    float time;
    float amplitude;
    float amplitudeAccel;
    float frequency;
    float frequencyAccel;
    float compression;
    float compressionAccel;
    float speed;
    int type; // 1: horizontal, 2: horizontal interlaced, 3: vertical
    float2 scrollOffset;
};

struct PatternUniforms {
    int patternIndex;
    int paletteIndex;
    uint2 textureSize;
};

// Compute shader to generate patterns directly on GPU
kernel void generatePattern(texture2d<float, access::write> outTexture [[texture(0)]],
                           constant PatternUniforms &uniforms [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    int x = int(gid.x);
    int y = int(gid.y);
    int patternIndex = uniforms.patternIndex;
    
    // Define palettes in Metal
    float4 palettes[15][4] = {
        // Fire palette (0)
        {{1.0, 0.0, 0.0, 1.0}, {1.0, 0.5, 0.0, 1.0}, {1.0, 1.0, 0.0, 1.0}, {1.0, 0.75, 0.0, 1.0}},
        // Ice palette (1) 
        {{0.0, 0.5, 1.0, 1.0}, {0.0, 0.75, 1.0, 1.0}, {0.5, 0.875, 1.0, 1.0}, {0.75, 0.94, 1.0, 1.0}},
        // Psychedelic palette (2)
        {{1.0, 0.0, 1.0, 1.0}, {0.0, 1.0, 1.0, 1.0}, {1.0, 1.0, 0.0, 1.0}, {0.5, 0.0, 1.0, 1.0}},
        // Earth palette (3)
        {{0.545, 0.27, 0.075, 1.0}, {0.627, 0.322, 0.176, 1.0}, {0.804, 0.522, 0.247, 1.0}, {0.871, 0.722, 0.529, 1.0}},
        // Neon palette (4)
        {{1.0, 0.078, 0.576, 1.0}, {0.0, 1.0, 0.498, 1.0}, {1.0, 0.412, 0.706, 1.0}, {0.498, 1.0, 0.831, 1.0}},
        // Monochrome (5)
        {{0.25, 0.25, 0.25, 1.0}, {0.5, 0.5, 0.5, 1.0}, {0.75, 0.75, 0.75, 1.0}, {1.0, 1.0, 1.0, 1.0}},
        // Sunset palette (6)
        {{1.0, 0.369, 0.302, 1.0}, {1.0, 0.616, 0.302, 1.0}, {1.0, 0.808, 0.329, 1.0}, {0.929, 0.459, 0.224, 1.0}},
        // Ocean palette (7)
        {{0.0, 0.467, 0.745, 1.0}, {0.0, 0.6, 0.859, 1.0}, {0.282, 0.792, 0.894, 1.0}, {0.565, 0.878, 0.937, 1.0}},
        // Forest palette (8)
        {{0.133, 0.545, 0.133, 1.0}, {0.196, 0.804, 0.196, 1.0}, {0.486, 0.988, 0.0, 1.0}, {0.678, 1.0, 0.184, 1.0}},
        // Royal palette (9)
        {{0.294, 0.0, 0.51, 1.0}, {0.541, 0.169, 0.886, 1.0}, {0.576, 0.439, 0.859, 1.0}, {0.729, 0.333, 0.827, 1.0}},
        // Lava palette (10)
        {{0.5, 0.0, 0.0, 1.0}, {1.0, 0.271, 0.0, 1.0}, {1.0, 0.549, 0.0, 1.0}, {1.0, 0.843, 0.0, 1.0}},
        // Cosmic palette (11)
        {{0.098, 0.098, 0.439, 1.0}, {0.255, 0.412, 0.882, 1.0}, {0.392, 0.584, 0.929, 1.0}, {0.529, 0.808, 0.98, 1.0}},
        // Toxic palette (12)
        {{0.0, 1.0, 0.0, 1.0}, {0.196, 0.804, 0.196, 1.0}, {0.498, 1.0, 0.0, 1.0}, {0.678, 1.0, 0.184, 1.0}},
        // Candy palette (13)
        {{1.0, 0.753, 0.796, 1.0}, {1.0, 0.714, 0.757, 1.0}, {1.0, 0.412, 0.706, 1.0}, {1.0, 0.078, 0.576, 1.0}},
        // Rainbow palette (14)
        {{1.0, 0.0, 0.0, 1.0}, {0.0, 1.0, 0.0, 1.0}, {0.0, 0.0, 1.0, 1.0}, {1.0, 1.0, 0.0, 1.0}}
    };
    
    int paletteIdx = uniforms.paletteIndex % 15;
    float4 palette[4] = {
        palettes[paletteIdx][0],
        palettes[paletteIdx][1], 
        palettes[paletteIdx][2],
        palettes[paletteIdx][3]
    };
    
    int colorIndex = 0;
    
    switch (patternIndex % 327) {
        case 0 ... 19: { // Checkerboard patterns
            int size = 8 + (patternIndex % 20) * 4;
            colorIndex = ((x / size) + (y / size));
            break;
        }
        case 20 ... 39: { // Stripe patterns
            bool isVertical = (patternIndex % 2) == 0;
            int stripeWidth = 4 + (patternIndex % 10) * 2;
            colorIndex = (isVertical ? (x / stripeWidth) : (y / stripeWidth));
            break;
        }
        case 40 ... 59: { // Diagonal patterns
            int size = 8 + (patternIndex % 20) * 2;
            colorIndex = ((x + y) / size);
            break;
        }
        case 60 ... 79: { // Circle patterns
            int centerX = 128;
            int centerY = 128;
            float dist = length(float2(x - centerX, y - centerY));
            float ringSize = 20.0 + float(patternIndex % 20) * 5.0;
            colorIndex = int(dist / ringSize);
            break;
        }
        case 80 ... 99: { // Wave patterns
            float frequency = 0.05 + float(patternIndex % 20) * 0.01;
            float amplitude = 10.0 + float(patternIndex % 20) * 2.0;
            float wave = sin(float(x) * frequency) * amplitude;
            colorIndex = abs((y + int(wave)) / 20);
            break;
        }
        case 100 ... 119: { // Grid patterns
            int gridSize = 16 + (patternIndex % 20) * 4;
            bool isGridLine = ((x % gridSize) < 2) || ((y % gridSize) < 2);
            colorIndex = isGridLine ? 0 : ((x / gridSize + y / gridSize) % 3 + 1);
            break;
        }
        case 120 ... 139: { // Diamond patterns
            int size = 16 + (patternIndex % 20) * 4;
            int diamond = abs(x - 128) + abs(y - 128);
            colorIndex = (diamond / size);
            break;
        }
        case 140 ... 159: { // Spiral patterns
            float2 center = float2(128.0, 128.0);
            float2 pos = float2(x, y) - center;
            float angle = atan2(pos.y, pos.x);
            float radius = length(pos);
            float spiral = (angle + radius * 0.1) * float(1 + patternIndex % 20);
            colorIndex = abs(int(spiral));
            break;
        }
        case 160 ... 179: { // Noise patterns
            int seed = patternIndex;
            int hash = (x * 73856093 ^ y * 19349663 ^ seed * 83492791) & 0x7FFFFFFF;
            colorIndex = hash;
            break;
        }
        case 180 ... 199: { // Cross patterns
            int size = 8 + (patternIndex % 20) * 2;
            bool isCross = ((x % size) < 2) || ((y % size) < 2);
            colorIndex = isCross ? ((x + y) / size) : ((x * y) / (size * size));
            break;
        }
        case 200 ... 219: { // Hexagon patterns
            float size = 20.0 + float(patternIndex % 20) * 2.0;
            float hexY = float(y) * 0.866;
            float hexX = float(x) + (y % 2 == 0 ? 0 : size / 2);
            colorIndex = (int(hexX / size) + int(hexY / size));
            break;
        }
        case 220 ... 239: { // Star patterns
            int centerX = 128;
            int centerY = 128;
            int dx = x - centerX;
            int dy = y - centerY;
            float angle = atan2(float(dy), float(dx));
            int points = 5 + (patternIndex % 20) / 4;
            float star = sin(angle * float(points)) * 50.0;
            float dist = length(float2(dx, dy));
            colorIndex = (dist < star ? 0 : 1) + (abs(int(angle * 10)) % 2);
            break;
        }
        case 240 ... 259: { // Gradient patterns
            bool isHorizontal = (patternIndex % 2) == 0;
            int position = isHorizontal ? x : y;
            colorIndex = (position * 4 / 256);
            break;
        }
        case 260 ... 279: { // Mosaic patterns
            int tileSize = 8 + (patternIndex % 20) * 2;
            int tileX = x / tileSize;
            int tileY = y / tileSize;
            int hash = (tileX * 73856093 ^ tileY * 19349663 ^ patternIndex * 83492791) & 0x7FFFFFFF;
            colorIndex = hash;
            break;
        }
        case 280 ... 299: { // Fractal patterns
            float2 c = float2(-0.7 + float(patternIndex % 20) * 0.05, 0.27015);
            float2 z = float2(x - 128, y - 128) / 64.0;
            int iteration = 0;
            const int maxIterations = 20;
            
            while (length(z) < 2.0 && iteration < maxIterations) {
                z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
                iteration++;
            }
            colorIndex = iteration;
            break;
        }
        case 300 ... 319: { // Organic patterns
            float scale = 0.05 + float(patternIndex % 20) * 0.01;
            float value1 = sin(float(x) * scale) * cos(float(y) * scale);
            float value2 = sin(float(x + y) * scale * 0.7);
            float combined = (value1 + value2) * 2.0;
            colorIndex = abs(int(combined + 4));
            break;
        }
        case 320 ... 326: { // Special patterns
            int specialType = patternIndex - 320;
            switch (specialType) {
                case 0: // Solid color
                    colorIndex = 0;
                    break;
                case 1: // Two-tone alternating
                    colorIndex = ((x + y) % 2);
                    break;
                case 2: // Four-quadrant
                    colorIndex = ((x < 128 ? 0 : 1) + (y < 128 ? 0 : 2));
                    break;
                case 3: // Radial gradient
                    {
                        float dist = length(float2(x - 128, y - 128));
                        colorIndex = int(dist / 30.0);
                    }
                    break;
                case 4: // Concentric squares
                    {
                        int dist = max(abs(x - 128), abs(y - 128));
                        colorIndex = (dist / 20);
                    }
                    break;
                case 5: // Random dots
                    {
                        int hash = (x * 73856093 ^ y * 19349663) & 0x7FFFFFFF;
                        colorIndex = (hash % 100 < 10) ? (hash % 1000) : 0;
                    }
                    break;
                default:
                    colorIndex = ((x / 16) + (y / 16));
                    break;
            }
            break;
        }
        default: {
            // Simple checkerboard fallback
            colorIndex = ((x / 16) + (y / 16));
            break;
        }
    }
    
    int safeIndex = abs(colorIndex) % 4;
    float4 color = palette[safeIndex];
    
    outTexture.write(color, gid);
}

// High-performance distortion compute shader
kernel void applyDistortion(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           constant DistortionUniforms &uniforms [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    // Wrap time to prevent overflow corruption (every ~10 minutes)
    float t = fmod(uniforms.time, 600.0);
    float t2 = t * t;
    
    // Calculate time-varying parameters with bounds checking
    float amplitude = uniforms.amplitude + uniforms.amplitudeAccel * t2;
    float frequency = uniforms.frequency + uniforms.frequencyAccel * t2;
    float compression = 1.0 + (uniforms.compression + uniforms.compressionAccel * t2) / 256.0;
    
    // Clamp amplitude to prevent extreme distortion corruption
    amplitude = clamp(amplitude, -200.0, 200.0);
    frequency = clamp(frequency, 0.001, 0.1);
    compression = clamp(compression, 0.5, 2.0);
    float speed = uniforms.speed * t;
    
    float2 coord = float2(gid) + uniforms.scrollOffset;
    float2 sourceCoord = coord;
    
    switch (uniforms.type) {
        case 1: { // Horizontal distortion - more dramatic
            float offset = amplitude * sin(frequency * coord.y + speed) * 2.0;
            sourceCoord.x = coord.x + offset;
            break;
        }
        case 2: { // Horizontal interlaced distortion - enhanced
            float offset;
            if (int(gid.y) % 2 == 0) {
                offset = amplitude * sin(frequency * coord.y + speed) * 2.5;
            } else {
                offset = amplitude * sin(frequency * coord.y - speed) * 2.5;
            }
            sourceCoord.x = coord.x + offset;
            break;
        }
        case 3: { // Vertical distortion - enhanced compression
            float distortedY = coord.y * compression;
            distortedY += amplitude * sin(frequency * coord.y + speed) * 3.0;
            sourceCoord.y = distortedY;
            break;
        }
    }
    
    // Wrap texture coordinates for seamless tiling
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    int srcX = int(sourceCoord.x) % int(width);
    int srcY = int(sourceCoord.y) % int(height);
    
    if (srcX < 0) srcX += width;
    if (srcY < 0) srcY += height;
    
    uint2 sourcePos = uint2(srcX, srcY);
    float4 color = inTexture.read(sourcePos);
    
    outTexture.write(color, gid);
}

// Shader to blend two layers with alpha
kernel void blendLayers(texture2d<float, access::read> layer1 [[texture(0)]],
                       texture2d<float, access::read> layer2 [[texture(1)]],
                       texture2d<float, access::write> outTexture [[texture(2)]],
                       constant float &alpha [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color1 = layer1.read(gid);
    float4 color2 = layer2.read(gid);
    
    // Alpha blend
    float4 blended = mix(color1, color2, alpha);
    
    outTexture.write(blended, gid);
}

// Vertex shader for final display
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    VertexOut out;
    
    // Generate fullscreen quad vertices
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    
    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];
    return out;
}

// CRT effect uniforms
struct CRTUniforms {
    float time;
    float scanlineIntensity;
    float pixelSize;
    float curvature;
    float vignetteStrength;
};

// Apply CRT post-processing effects
kernel void applyCRTEffect(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           constant CRTUniforms &uniforms [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float2 resolution = float2(outTexture.get_width(), outTexture.get_height());
    float2 uv = float2(gid) / resolution;
    
    // Apply barrel distortion for CRT curvature
    float2 centered = uv * 2.0 - 1.0;
    float2 curved = centered;
    if (uniforms.curvature > 0.0) {
        float r2 = dot(centered, centered);
        curved = centered * (1.0 + uniforms.curvature * r2);
    }
    float2 distortedUV = (curved + 1.0) * 0.5;
    
    // Check if we're outside the screen bounds after distortion
    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || 
        distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        outTexture.write(float4(0.0, 0.0, 0.0, 1.0), gid);
        return;
    }
    
    // Pixellation effect - downsample to SNES resolution
    float2 pixelatedUV = distortedUV;
    if (uniforms.pixelSize > 1.0) {
        float2 pixelGrid = floor(distortedUV * resolution / uniforms.pixelSize) * uniforms.pixelSize;
        pixelatedUV = pixelGrid / resolution;
    }
    
    // Sample the texture
    uint2 samplePos = uint2(pixelatedUV * resolution);
    samplePos.x = min(samplePos.x, uint(resolution.x - 1));
    samplePos.y = min(samplePos.y, uint(resolution.y - 1));
    float4 color = inTexture.read(samplePos);
    
    // Scanline effect
    float scanline = 1.0;
    if (uniforms.scanlineIntensity > 0.0) {
        float scanlineY = gid.y;
        scanline = 1.0 - uniforms.scanlineIntensity * abs(sin(scanlineY * 3.14159));
        
        // Add subtle horizontal banding
        if (int(scanlineY) % 3 == 0) {
            scanline *= 0.85;
        }
    }
    
    // Phosphor glow simulation
    float glow = 1.0 + 0.05 * sin(uniforms.time * 60.0 + gid.y * 0.5);
    
    // Vignette effect
    float vignette = 1.0;
    if (uniforms.vignetteStrength > 0.0) {
        float2 vignetteUV = uv * (1.0 - uv.yx);
        vignette = pow(vignetteUV.x * vignetteUV.y * 15.0, uniforms.vignetteStrength);
    }
    
    // Apply all effects
    color.rgb *= scanline * glow * vignette;
    
    // Subtle color bleeding for authentic CRT look
    float bleed = 0.002;
    uint2 bleedPos = uint2((float2(gid) + float2(bleed * resolution.x, 0)) );
    if (bleedPos.x < uint(resolution.x)) {
        float4 bleedColor = inTexture.read(bleedPos);
        color.r = mix(color.r, bleedColor.r, 0.1);
    }
    
    outTexture.write(color, gid);
}

// Fragment shader for final display
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                              texture2d<float> texture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]]) {
    return texture.sample(textureSampler, in.texCoord);
}