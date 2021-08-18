Shader "Custom/Test"
{
    Properties
    {
        [HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
        uIntensity("uIntensity", Range(0, 1)) = 0.5
        uPos("uPos", Vector) = (0, 0, 0, 0) 
        [HDR]uEmissionColor("uEmissionColor", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma vertex vert
			#pragma fragment frag

            //UNIFORM
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float  uIntensity;
            float3 uPos;
            float4  uEmissionColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS:POSITION;
                float2 uv:TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS:SV_POSITION;
                float2 uv:TEXCOORD0;
                float  eyeZ:TEXCOORD2;
                float2 sobelUV[5]:TEXCOORD3;
                
            };

			float Sobel(float2 sobelUV[5])
            {
				const float Gx[5] = { -2, 
									  0,  0,  0,
									  2};

				const float Gy[5] = { 0,
									 -2, 0, 2,
									  0};

				float3 depth;
				float edgeX = 0;
				float edgeY = 0;

				for (int it = 0; it < 5; it++)
                {
                    depth = SampleSceneDepth(sobelUV[it]);
					edgeX += depth * Gx[it];
					edgeY += depth * Gy[it];
				}

				float edge = 1 - abs(edgeX) - abs(edgeY);
				return edge;

			}

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInput.positionCS;
                //OUT.eyeZ = -vertexInput.positionVS.z;
                OUT.uv = IN.uv;

                float2 texelSize = 1 / _ScaledScreenParams;
				OUT.sobelUV[0] = IN.uv + texelSize.xy * float2( 0, -1);
				OUT.sobelUV[1] = IN.uv + texelSize.xy * float2(-1, 0);
				OUT.sobelUV[2] = IN.uv + texelSize.xy * float2( 0, 0);
				OUT.sobelUV[3] = IN.uv + texelSize.xy * float2( 1, 0);
				OUT.sobelUV[4] = IN.uv + texelSize.xy * float2( 0, 1);

                return OUT;
            }

            float4 frag(Varyings IN):SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                float depth  = SampleSceneDepth(IN.uv);

                float2 UV = IN.positionCS.xy / _ScaledScreenParams.xy;
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);

                float w = saturate(distance(worldPos, uPos) * 0.01);
                w = step(w + 0.5, uIntensity) - step(w + 0.3,  uIntensity);

                float edge = Sobel(IN.sobelUV);
                edge = (1 - saturate(edge)) * w;

                float scanLine = step(frac(worldPos.y * 15 - depth), 0.1) * w;

                float4 color = lerp(mainTex, uEmissionColor, w * edge * 20 );
                color = lerp(color, uEmissionColor * 0.15, w * scanLine);
                
                //float3 normal = normalize(cross(ddx(worldPos), ddy(worldPos)));
                //normal = normal * 0.5 + 0.5;
                //color.rgb = normal;

                return color;
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}