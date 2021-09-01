Shader "Custom/DeferredRenderShader"
{
    Properties
    {
        [HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "LightMode"="ShadowCaster" }

        Pass
        {
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma vertex vert
			#pragma fragment frag

            //UNIFORM
            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex; float4 _MainTex_ST;
            //
            float4 uPointLightPos;
            CBUFFER_END

            //float4x4 camera

            struct Attributes
            {
                float4 positionOS:POSITION;
                float2 uv:TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS:SV_POSITION;
                float3 positionWS:TEXCOORD1;
                float2 uv:TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS  = vertexInput.positionCS;
                OUT.positionWS  = vertexInput.positionWS;
                OUT.uv = IN.uv;

                return OUT;
            }

            #define MAX_FRACTIONAL_8_BIT        (255.0 / 256.0)
            #define MIDPOINT_8_BIT              (127.0 / 255.0)
            #define TWO_BITS_EXTRACTION_FACTOR  (3.0 + MAX_FRACTIONAL_8_BIT)

            float3 decodeColorYCC( float3 encodedCol )
            {
                encodedCol = float3(encodedCol.x, encodedCol.y / MIDPOINT_8_BIT - 1., encodedCol.z / MIDPOINT_8_BIT - 1.);

                float3 col;
                col.r = encodedCol.x + 1.402 * encodedCol.z;
                col.g = dot( float3( 1, -0.3441, -0.7141 ), encodedCol.xyz );
                col.b = encodedCol.x + 1.772 * encodedCol.y;

                return col * col;
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

            float4 frag(Varyings IN):SV_Target
            {
                float depth  = SampleSceneDepth(IN.uv);
                float2 UV = IN.positionCS.xy / _ScaledScreenParams.xy;

	            float3 viewPos = mul((float2(IN.uv.x, 1 - IN.uv.y) * 2.0 - 1.0), UNITY_MATRIX_P) * (1.0 / (_ZBufferParams.z * depth + _ZBufferParams.w));
                //
                float2 texel = float2(1.0/_ScreenParams.x, 1.0/_ScreenParams.y);
                
                float4 uGBuf  = tex2D(_MainTex, IN.uv);
                float4 uGBuf1 = tex2D(_MainTex, IN.uv + float2( texel.x, 0.0));
                float4 uGBuf2 = tex2D(_MainTex, IN.uv - float2( texel.x, 0.0));
                float4 uGBuf3 = tex2D(_MainTex, IN.uv + float2( 0.0, texel.y));
                float4 uGBuf4 = tex2D(_MainTex, IN.uv - float2( 0.0, texel.y));

                const float edgeThreshold = 0.1;
                float4 lum = float4(uGBuf1.x, uGBuf2.x, uGBuf3.x, uGBuf4.x);
                float4 weights = 1.0 - step(edgeThreshold, abs(lum - uGBuf.x));
                float weightSum = dot(weights, 1.0);

                float invWeightSum = 1.0;
                if (weightSum == 0.0)
                    weights.x = 1.0;
                else
                    invWeightSum = 1.0/weightSum;

                //RECONSTRUCT
                float yy = dot(weights, float4(uGBuf1.y, uGBuf2.y, uGBuf3.y, uGBuf4.y)) * invWeightSum;
                float zz = dot(weights, float4(uGBuf1.z, uGBuf2.z, uGBuf3.z, uGBuf4.z)) * invWeightSum;
                float ww = dot(weights, float4(uGBuf1.w, uGBuf2.w, uGBuf3.w, uGBuf4.w)) * invWeightSum;

                //CHECKER BOARD
                float checkerBoardMask = fmod(floor(IN.uv.x * _ScreenParams.x) + floor(IN.uv.y * _ScreenParams.y), 2.0);

                //COLOR DECODE
                float3 colorDecode;
                colorDecode.x = uGBuf.x;
                colorDecode.y = lerp( uGBuf.y, yy, checkerBoardMask);
                colorDecode.z = lerp( yy, uGBuf.y, checkerBoardMask);
                float3 color = decodeColorYCC(colorDecode);

                //NORMAL DECODE
                float2 normalDecode;
                normalDecode.x = lerp( zz, uGBuf.z, checkerBoardMask);
                normalDecode.y = lerp( ww, uGBuf.w, checkerBoardMask);
                float3 normalVS = decodeNormal(normalDecode);

                //LIGHTING
                float3 lightColor = float3(1,1,1);
                float3 norm = normalVS;

                float3 lightViewPos = uPointLightPos.xyz;
                float3 lightDir = normalize(lightViewPos - viewPos);  
                float diff = max(dot(norm, lightDir), 0.0);
                float3 diffuse = diff * lightColor;

                //POINT
                float distance    = length(lightViewPos - viewPos);
                float attenuation = 1.0 / (distance * distance) ; 
            
                return float4( color * diffuse * attenuation  , 1.0);
                //return float4( viewPos , 1.0 );
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}