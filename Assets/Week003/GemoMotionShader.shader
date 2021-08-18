Shader "Custom/GemoMotionShader"
{
    Properties
    {
        uMainTex("uMainTex", 2D) = "white"{}
		uIntensity("uIntensity", Range(0, 1)) = 0.5
        uDirection("uDirection", Vector) = (0, 0, 0, 0)
        uFlowTex("uFlowTex", 2D) = "white"{}
        uMaskTex("uMaskTex", 2D) = "white"{}
        uWeight("uWeight", Range(0, 1)) = 0.5
        uRadius("Radius", float) = 0.1
        uShapeTex("uShapeTex", 2D) = "white"{}
        [HDR]uColorEdge ("uColorEdge", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass
        {
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            //---
            CGPROGRAM
            //#include "MyCgInclude.cginc"
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 uv:TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 uv:TEXCOORD0;
            };
 
            struct g2f
            {
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL;
                float4 vertex:POSITION;
                float4 color:COLOR;
            };

            //Uniform
            sampler2D uMainTex;  float4 uMainTex_ST;
            sampler2D uFlowTex;  float4 uFlowTex_ST;
            sampler2D uMaskTex;  float4 uMaskTex_ST;
            sampler2D uShapeTex; float4 uShapeTex_ST;
			float uIntensity;
            float4 uDirection;
            float uWeight;
            float uRadius;
            float4 uColorEdge;

            //VertexShader
            v2g vert (appdata IN)
            {
                v2g o;
                o.vertex = IN.vertex;
                o.uv = TRANSFORM_TEX(IN.uv, uMainTex);
                o.normal = UnityObjectToWorldNormal(IN.normal);
                return o;
            }

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

            //GeometryShader
            [maxvertexcount(6)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                float3 avgPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
                float2 avgUV  = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
                float3 avgNor = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;

                float dissoleValue = tex2Dlod(uMaskTex, float4(avgUV, 0, 0)).r;
                float t = clamp(uWeight * 2 - dissoleValue, 0, 1);

                //FLOW TEX
                float2 flowUV = TRANSFORM_TEX(mul(unity_ObjectToWorld, avgPos).xz, uFlowTex);
                float4 flowVector = remapFlowTexture(tex2Dlod(uFlowTex, float4(flowUV, 0, 0)));
                
                float3 pseudoRandomPos = (avgPos) + uDirection;
                pseudoRandomPos += (flowVector.xyz * uIntensity);

                float3 p = lerp(avgPos, pseudoRandomPos, t);
                float radius = lerp(uRadius, 0, t);

                if (t > 0)
                {
                    float3 look = _WorldSpaceCameraPos - p;
                    look = normalize(look);

                    float3 right = UNITY_MATRIX_IT_MV[0].xyz;
                    float3 up = UNITY_MATRIX_IT_MV[1].xyz;

                    float halfS = 0.5f * radius;

                    float4 v[4];
                    v[0] = float4(p + halfS * right - halfS * up, 1.0f);
                    v[1] = float4(p + halfS * right + halfS * up, 1.0f);
                    v[2] = float4(p - halfS * right - halfS * up, 1.0f);
                    v[3] = float4(p - halfS * right + halfS * up, 1.0f);

                    g2f vert;
                    vert.vertex = UnityObjectToClipPos(v[0]);
                    vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 0.0f));
                    vert.color = float4(1, 1, 1, 1);
                    vert.normal = avgNor;
                    triStream.Append(vert);

                    vert.vertex = UnityObjectToClipPos(v[1]);
                    vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 1.0f));
                    vert.color = float4(1, 1, 1, 1);
                    vert.normal = avgNor;
                    triStream.Append(vert);

                    vert.vertex =UnityObjectToClipPos(v[2]);
                    vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 0.0f));
                    vert.color = float4(1, 1, 1, 1);
                    vert.normal = avgNor;
                    triStream.Append(vert);

                    vert.vertex = UnityObjectToClipPos(v[3]);
                    vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 1.0f));
                    vert.color = float4(1, 1, 1, 1);
                    vert.normal = avgNor;
                    triStream.Append(vert);

                    triStream.RestartStrip();

                }

                g2f o;
                for (int j = 0; j < 3; j++)
                {
                    o.vertex = UnityObjectToClipPos(IN[j].vertex);
                    o.uv = IN[j].uv;
                    o.normal = IN[j].normal;
                    o.color = float4(0, 0, 0, 0);
                    triStream.Append(o);
                }
                triStream.RestartStrip();
                
            }

            //PixelShader
            float4 frag (g2f IN):SV_Target
            {
                float4 mainTex  = tex2D(uMainTex, IN.uv);
                float4 shapeTex = tex2D(uShapeTex, IN.uv);

                float maskTex     =  tex2D(uMaskTex, IN.uv).r;
                float dissove     = step(maskTex, 0.1 + uWeight );
                float dissoveEdge = step(maskTex, 0.1 + uWeight + 0.01);

                float4 color = lerp(mainTex, uColorEdge, dissove);
                color.a = dissoveEdge;
                
                //if(color.a < 0.1) discard;

                return mainTex;
            }

            ENDCG
        }
    }
}
