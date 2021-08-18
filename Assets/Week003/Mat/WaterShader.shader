Shader "Custom/WaterShader"
{
    Properties
    {
        uWaterColor("uWaterColor", Color) = (1, 1, 1, 1)
        uWaterColorDepth("uWaterColorDepth", Color) = (1, 1, 1, 1)
        uWaterDepth("uWaterDepth", Range(0, 1)) = 0.5
        uDepthMax("uDepthMax", float) = 10
        uFlowTex("uFlowTex", 2D) = "white"{}
        uMaskTex("uMaskTex", 2D) = "white"{}
        uWaterTex("uWaterTex", 2D) = "white"{}
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            //"IgnoreProjector" = "True"
            //"LightMode" = "UniversalForward"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            //Cull Back
            //ZWrite Off
            //ZTest LEqual
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float3 color:COLOR;
                float2 uv:TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS:POSITION;
                float3 normalWS:NORMAL;
                float  eyeZ:TEXCOORD1;
                float4 positionScreen:TEXCOORD2;
                float3 viewDirWS:TEXCOORD3;
                float3 color:COLOR;
                float2 uv:TEXCOORD0;
                float3 positionWS:TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 uWaterColor;
            float4 uWaterColorDepth;
            float uWaterDepth;
            float uDepthMax;
            SAMPLER(_CameraOpaqueTexture);
            sampler2D uFlowTex; float4 uFlowTex_ST;
            sampler2D uMaskTex;   float4 uMaskTex_ST;
            sampler2D uWaterTex;  float4 uWaterTex_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // GetVertexPositionInputs positionWS(TransformObjectToWorld), positionVS(TransformWorldToView), positionCS(TransformWorldToHClip)
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.vertex.xyz); 
                OUT.positionCS = vertexInput.positionCS; //clip space position

                OUT.normalWS  = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                
                OUT.positionScreen = vertexInput.positionNDC;
                OUT.eyeZ = -vertexInput.positionVS.z;
                OUT.color = IN.color;
                OUT.uv = IN.uv;

                OUT.positionWS = vertexInput.positionWS;

                return OUT;
            }

            float3 FlowUVW (float2 uv, float2 flowVector, float time, bool flowB)
            {
                float phaseOffset = flowB ? 0.5 : 0;
                float progress = frac(time + phaseOffset);
                float3 uvw;
                uvw.xy = uv - flowVector * progress;
                uvw.z = 1 - abs(1 - 2 * progress);
                return uvw;
            }

            float4 frag(Varyings IN):SV_Target
            {
                float depth = SampleSceneDepth(IN.positionScreen.xy / IN.positionScreen.w);
                float screenZ = LinearEyeDepth(depth, _ZBufferParams);

                
                float eyeDepth = saturate((screenZ - IN.eyeZ) / uDepthMax );

                float2 UV = IN.positionCS.xy / _ScaledScreenParams.xy;
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
               
                float time = _Time.y * 0.3;
  
                float2 flowTex = tex2D(uFlowTex, IN.uv * uFlowTex_ST.xy + uFlowTex_ST.zw).rg;
                flowTex = flowTex * 2.0 - 1.0;

                float3 uvwA  = FlowUVW(IN.uv, flowTex, time, false);
                float3 uvwB  = FlowUVW(IN.uv, flowTex, time, true);

                float4 texA = tex2D(uWaterTex, IN.uv + uvwA.xy) * uvwA.z;
			    float4 texB = tex2D(uWaterTex, IN.uv + uvwB.xy) * uvwB.z;
                float4 waterTex = (texA + texB);

                float4 color;
                color.rgb = lerp(uWaterColor.rgb, uWaterColorDepth.rgb, eyeDepth);
                color.a =  saturate(eyeDepth + 0.3);

                float edge = 1 - saturate((screenZ - IN.eyeZ) * 5 );
                float3 maskTex = tex2D(uMaskTex, IN.uv * uMaskTex_ST.xy + uMaskTex_ST.zw + time);
                edge = 1 - step(edge - maskTex, 0.3);
               
                color.rgb = lerp(waterTex.rgb,  color.rgb , 0.7);
                color += edge;

                return color;
            }
            ENDHLSL
        }
    }

    FallBack "Diffuse"
}
