// This shader fills the mesh shape with a color predefined in the code.
Shader "Example/MicroGBufferShader"
{
    Properties
    {
        uMainTex("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"            

            CBUFFER_START(UnityPerMaterial)
            sampler2D uMainTex; float4 uMainTex_ST;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normal : NORMAL;
                float2 uv:TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalVS : NORMAL;
                float2 uv:TEXCOORD0;
            };            

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalVS = normalize(mul((float3x3)UNITY_MATRIX_MV, IN.normal));
                OUT.uv = IN.uv;
                return OUT;
            }

            #define MAX_FRACTIONAL_8_BIT        (255.0 / 256.0)
            #define MIDPOINT_8_BIT              (127.0 / 255.0)
            #define TWO_BITS_EXTRACTION_FACTOR  (3.0 + MAX_FRACTIONAL_8_BIT)

            float3 encodeColorYCC(float3 col)
            {
                float3 encodedCol; // Y'Cb'Cr'
                col = sqrt( col );
                encodedCol.x = dot( float3(0.299, 0.587, 0.114),   col.rgb );
                encodedCol.y = dot( float3(-0.1687, -0.3312, 0.5), col.rgb );
                encodedCol.z = dot( float3(0.5, -0.4186, -0.0813), col.rgb );
                
                return float3(encodedCol.x, encodedCol.y * MIDPOINT_8_BIT + MIDPOINT_8_BIT, encodedCol.z * MIDPOINT_8_BIT + MIDPOINT_8_BIT);
            }

            float3 decodeColorYCC( float3 encodedCol )
            {
                encodedCol = float3(encodedCol.x, encodedCol.y / MIDPOINT_8_BIT - 1., encodedCol.z / MIDPOINT_8_BIT - 1.);

                float3 col;
                col.r = encodedCol.x + 1.402 * encodedCol.z;
                col.g = dot( float3( 1, -0.3441, -0.7141 ), encodedCol.xyz );
                col.b = encodedCol.x + 1.772 * encodedCol.y;

                return col * col;
            }

            float2 encodeNormal(float3 n)
            {
                return n.xy * rsqrt(8 * n.z + 8) + 0.5;
                //float2 enc = normalize(n.xy) * (sqrt(-n.z * 0.5 + 0.5));
                //enc = enc * 0.5 + 0.5;
                //return enc;
            }

            float3 decodeNormal(float2 n)
            {
                float2 fenc = n * 4.0 - 2.0;
                float f = dot(fenc,fenc);
                float g = sqrt(1.0 - f/4.0);
                float3 normal;
                normal.xy = fenc * g;
                normal.z = 1.0 - f/2.0;
                return normal;
            }
        
            float4 frag(Varyings IN) : SV_Target
            {
                //MASK
                float checkerBoardMask = fmod(floor( IN.positionHCS.x ) + floor( IN.positionHCS.y ), 2.0);

                //COLOR
                float4 mainTex = tex2D(uMainTex, IN.uv * uMainTex_ST.xy + uMainTex_ST.zw);
                float3 colorYcbcr = encodeColorYCC(mainTex);
                float2 colorEncode;
                colorEncode.x = colorYcbcr.x;
	            colorEncode.y = lerp(colorYcbcr.y, colorYcbcr.z, checkerBoardMask);

                //NORMAL
                float2 normalEncode = encodeNormal(IN.normalVS);
                float roughness = 0.0; //TBD
                float metallic = 0.0;  //TBD
                float2 nrmEncode;
                nrmEncode.x = lerp( roughness, normalEncode.x, checkerBoardMask);
	            nrmEncode.y = lerp( metallic,  normalEncode.y, checkerBoardMask);

                //OUTPUT
                float4 color = float4(colorEncode, nrmEncode);

                return color;
            }
            ENDHLSL
        }
    }
}