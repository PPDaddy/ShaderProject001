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
                OUT.normalVS = normalize(mul((float3x3)UNITY_MATRIX_M, IN.normal));
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

            float2 octWrap( float2 v )
            {
                return ( 1.0 - abs( v.yx ) ) * ( v.xy >= 0.0 ? 1.0 : -1.0 );
            }

            float2 encodeNormal( float3 n )
            {
                n /= ( abs( n.x ) + abs( n.y ) + abs( n.z ) );
                n.xy = n.z >= 0.0 ? n.xy : octWrap( n.xy );
                n.xy = n.xy * 0.5 + 0.5;
                return n.xy;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                //MASK
                float checkerBoardMask = 1 - fmod(floor( IN.positionHCS.x + IN.positionHCS.y ), 2.0);

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
                nrmEncode.x = checkerBoardMask ? roughness : normalEncode.x;
	            nrmEncode.y = checkerBoardMask ? metallic  : normalEncode.y;

                //OUTPUT
                float4 color = float4(colorEncode, nrmEncode);

                return color;
            }
            ENDHLSL
        }
    }
}