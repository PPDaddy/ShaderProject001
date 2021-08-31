Shader "Custom/Test"
{
    Properties
    {
        [HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
        uCookieTex("uCookieTex", 2D) = "white"{}
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
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            sampler2D uCookieTex;

            float4x4 utexVPMat;

            float4x4 utexVMat;

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
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInput.positionCS;
                OUT.uv = IN.uv;

                return OUT;
            }

            float4 frag(Varyings IN):SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                float depth  = SampleSceneDepth(IN.uv);

                float2 UV = IN.positionCS.xy / _ScaledScreenParams.xy;
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);

                float4 shadowUV = mul(utexVPMat, float4(worldPos, 1.0));
                shadowUV.xyz /= shadowUV.w; 

                float2 uv = abs( float2(shadowUV.x, shadowUV.y) * 0.5 + 0.5 );

                if (uv.x > 1 ||  uv.y > 1) return mainTex;
//
                float4 cookieTex = tex2D(uCookieTex, uv);

                float4 color;
                color = mainTex + cookieTex;
                return color;
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}