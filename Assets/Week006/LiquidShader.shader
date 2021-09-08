// This shader fills the mesh shape with a color predefined in the code.
Shader "Example/LiquidShader"
{

    Properties
    {
        uLiquidColor ("uLiquidColor", Color) = (1,1,1,1)
        uFillAmount ("uFillAmount", Range(-10,10)) = 0.0
        [HideInInspector] uWobbleX ("WobbleX", Range(-1,1)) = 0.0
        [HideInInspector] uWobbleZ ("WobbleZ", Range(-1,1)) = 0.0
        uLiquidTopColor ("uLiquidTopColor", Color) = (1,1,1,1)
        uLiquidFoamColor ("uLiquidFoamColor", Color) = (1,1,1,1)
        uFoamLineWidth ("Liquid Foam Line Width", Range(0,0.1)) = 0.0    
    }

    SubShader
    {

        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Zwrite On
        Cull Off 
        AlphaToMask On // transparency

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL; 
            };

            struct Varyings
            {
                float2 uv:TEXCOORD0;
                float4 vertex:SV_POSITION;
                float3 viewDir:COLOR;
                float3 normal:COLOR2;    
                float  fillEdge:TEXCOORD2;
            };

            //UNIFORM
            float  uFillAmount, uWobbleX, uWobbleZ;
            float4 uLiquidTopColor, uLiquidFoamColor, uLiquidColor;
            float  uFoamLineWidth;

            #define UNITY_PI 3.14159265359f

            float4 rotateAroundYInDegrees (float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, sina, -sina, cosa);
                return float4(vertex.yz , mul(m, vertex.xz)).xzyw ;            
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.vertex = TransformObjectToHClip(IN.vertex);
                OUT.uv = IN.uv;

                float3 worldPos = mul (unity_ObjectToWorld, IN.vertex.xyz);
                float3 worldPosX= rotateAroundYInDegrees(float4(worldPos,0),360);
                float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);     
                float3 worldPosAdjusted = worldPos + (worldPosX * uWobbleX)+ (worldPosZ * uWobbleZ);

                OUT.fillEdge =  worldPosAdjusted.y + uFillAmount;
                OUT.viewDir = TransformWorldToObject(GetCameraPositionWS()) - IN.vertex;
                OUT.normal = IN.normal;

                return OUT;
            }

            // The fragment shader definition.
            float4 frag(Varyings IN) : SV_Target
            {
                float4 col = uLiquidColor;

                float4 foam = step(IN.fillEdge, 0.5) - step(IN.fillEdge, (0.5 - uFoamLineWidth));
                float4 foamColored = foam * uLiquidFoamColor;

                float4 result = step(IN.fillEdge, 0.5) - foam;
                float4 resultColored = result * col;

                float4 finalResult = resultColored + foamColored;               
                float4 topColor = uLiquidTopColor * (foam + result);

                float facing = dot(IN.normal, IN.viewDir);
                return facing > 0 ? finalResult : topColor;
            }
            ENDHLSL
        }
    }
}