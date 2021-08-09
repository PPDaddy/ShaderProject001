Shader "Custom/VertexMotionShader"
{
    Properties
    {
        uMainTex("uMainTex", 2D) = "white"{}
		uIntensity("uIntensity", Range(0, 1)) = 0.5
        uDirection("uDirection", Vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass
        {
            Cull Off
            //---
            CGPROGRAM
            #include "MyCgInclude.cginc"
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD0;
            };
 
            struct g2f
            {
                float2 uv:TEXCOORD0;
                float4 vertex:POSITION;
            };

            //Uniform
            sampler2D uMainTex; float4 uMainTex_ST;
			float uIntensity;
            float4 uDirection;

            //VertexShader
            v2g vert (appdata IN)
            {
                v2g o;
                o.vertex = IN.vertex;
                o.uv = TRANSFORM_TEX(IN.uv, uMainTex);
                return o;
            }

            //GeometryShader
            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                float3 avgPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

                //FLAT NORMAL
                float3 v1 = IN[1].vertex - IN[0].vertex;
                float3 v2 = IN[2].vertex - IN[0].vertex;
                float3 avgNor = normalize(cross(v1, v2));
                
                g2f o;
                for(int i = 0; i < 3; i++)
                {

                    float l = smoothstep(0, 1, uIntensity);
                    float3 targetPos = avgPos + avgNor + uDirection;
                    
                    float3 p = lerp(IN[i].vertex, targetPos, l);
  
                    o.vertex = UnityObjectToClipPos(p);
                    o.uv = TRANSFORM_TEX(IN[i].uv, uMainTex);

                    triStream.Append(o);
                }
                triStream.RestartStrip();
                
            }

            //PixelShader
            float4 frag (g2f IN):SV_Target
            {
                float4 col = tex2D(uMainTex, IN.uv);
                
                return col;
            }

            ENDCG
        }
    }
}
