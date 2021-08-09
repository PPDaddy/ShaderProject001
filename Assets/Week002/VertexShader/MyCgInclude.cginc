#ifndef MY_CG_INCLUDE
#define MY_CG_INCLUDE

//Helper Function
float remap(float value, float from1, float to1, float from2, float to2)
{
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float4 remapFlowTexture(float4 tex)
{
    return float4(
        remap(tex.x, 0, 1, -1, 1),
        remap(tex.y, 0, 1, -1, 1),
        0,
        remap(tex.w, 0, 1, -1, 1)
    );
}

float random(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
}

float rand(float3 myVector)
{
    return frac(sin( dot(myVector ,float3(12.9898,78.233,45.5432) )) * 43758.5453);
}

#endif