Shader "MYURP/ForceField"
{
    Properties
    {
        [HDR]uEmissionColor("uEmissionColor", Color) = (1, 1, 1, 1)
        uFresnel("uFresnel", Range(0, 1)) = 1
        uEdgePower("uEdgePower", Range(0, 1)) = 0
        uPower("uPower", Range(0, 5)) = 0.5
        uMaskTex("uMaskTex", 2D) = "white"{}
    }
    
    SubShader
    {
        
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "LightMode" = "UniversalForward"
        }
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZWrite Off
            ZTest LEqual
            
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
                float4 vertex:POSITION;
                float3 normalWS:NORMAL;
                float  eyeZ:TEXCOORD1;
                float4 positionScreen:TEXCOORD2;
                float3 viewDirWS:TEXCOORD3;
                float3 color:COLOR;
                float2 uv:TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 uEmissionColor;
            float  uFresnel;
            float  uEdgePower;
            float  uPower;
            sampler2D uMaskTex; float4 uMaskTex_ST;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // GetVertexPositionInputs positionWS(TransformObjectToWorld), positionVS(TransformWorldToView), positionCS(TransformWorldToHClip)
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.vertex.xyz); 
                OUT.vertex = vertexInput.positionCS; //clip space position

                OUT.normalWS  = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                
                OUT.positionScreen = vertexInput.positionNDC;
                OUT.eyeZ = -vertexInput.positionVS.z;
                OUT.color = IN.color;
                OUT.uv = IN.uv;
                
                return OUT;
            }
            
            float4 frag(Varyings IN):SV_Target
            {
                //FRESNEL = dot(worldNormal, viewDirection);
                float3 normalWS  = -1 * normalize(IN.normalWS);
                float3 viewDirWS = normalize(IN.viewDirWS);
                float  fresnel   = 1 - saturate(dot(normalWS, viewDirWS)) * uFresnel;

                float maskTex = tex2D(uMaskTex, IN.uv * uMaskTex_ST.xy + uMaskTex_ST.zw).r;
                
                float screenZ = LinearEyeDepth(SampleSceneDepth(IN.positionScreen.xy / IN.positionScreen.w), _ZBufferParams);
                float intersect = (1 - (screenZ - IN.eyeZ)) * uEdgePower;
                float v = max(fresnel, intersect);
                v = saturate(pow(v, uPower));

                float edge = 1 - pow( 1 - IN.color.r, uPower);

                float4 color = uEmissionColor * lerp(v + 0.5, v, edge - (maskTex * 0.5 ));

                return color;
            }

            ENDHLSL
        }
        
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "LightMode" = "SRPDefaultUnlit"
        }
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            ZWrite Off
            ZTest LEqual
            
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
                float4 vertex:POSITION;
                float3 normalWS:NORMAL;
                float  eyeZ:TEXCOORD1;
                float4 positionScreen:TEXCOORD2;
                float3 viewDirWS:TEXCOORD3;
                float3 color:COLOR;
                float2 uv:TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 uEmissionColor;
            float  uFresnel;
            float  uEdgePower;
            float  uPower;
            sampler2D uMaskTex; float4 uMaskTex_ST;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // GetVertexPositionInputs positionWS(TransformObjectToWorld), positionVS(TransformWorldToView), positionCS(TransformWorldToHClip)
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.vertex.xyz); 
                OUT.vertex = vertexInput.positionCS; //clip space position

                OUT.normalWS  = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                
                OUT.positionScreen = vertexInput.positionNDC;
                OUT.eyeZ = -vertexInput.positionVS.z;
                OUT.color = IN.color;
                OUT.uv = IN.uv;
                
                return OUT;
            }
            
            float4 frag(Varyings IN):SV_Target
            {
                //FRESNEL = dot(worldNormal, viewDirection);
                float3 normalWS  = normalize(IN.normalWS);
                float3 viewDirWS = normalize(IN.viewDirWS);
                float  fresnel   = 1 - saturate(dot(normalWS, viewDirWS)) * uFresnel;

                float maskTex = tex2D(uMaskTex, IN.uv * uMaskTex_ST.xy + uMaskTex_ST.zw).r;
                
                float screenZ = LinearEyeDepth(SampleSceneDepth(IN.positionScreen.xy / IN.positionScreen.w), _ZBufferParams);
                float intersect = (1 - (screenZ - IN.eyeZ)) * uEdgePower;
                float v = max(fresnel, intersect);
                v = saturate(pow(v, uPower));

                float edge = 1 - pow( 1 - IN.color.r, uPower);

                float4 color = uEmissionColor * lerp(v + 0.5, v, edge - (maskTex * 0.5 ));

                return color;
            }

            ENDHLSL
        }
        
    }
    
}
